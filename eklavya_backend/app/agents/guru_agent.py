"""
Guru Agent — the conversational AI that creates personalized roadmaps.

Uses Google Gemini for generation. Maintains per-session conversation history.
"""

import asyncio
import json
import logging
import re

from google import genai
from google.genai import types

from app.agents.prompts import get_system_prompt
from app.core.config import get_settings

logger = logging.getLogger(__name__)


class GuruAgent:
    """Stateful conversational agent for a single user session."""

    def __init__(
        self,
        domain: str,
        user_id: str,
        roadmap_context: str | None = None,
        memory_context: str | None = None,
        current_streak: int | None = None,
        coach_state: str | None = None,
    ):
        self.domain = domain
        self.user_id = user_id
        self.history: list[dict[str, str]] = []
        self.roadmap: dict | None = None
        
        # Base capability scalar (Adaptive Goal Decomposition)
        self.user_capability_scalar = 1.0

        streak_value = max(0, int(current_streak or 0))
        if streak_value >= 7:
            self.user_capability_scalar = 1.15
            streak_tier = "HIGH"
        elif streak_value >= 3:
            self.user_capability_scalar = 1.0
            streak_tier = "STEADY"
        else:
            self.user_capability_scalar = 0.9
            streak_tier = "REBUILDING"
        
        dynamic_context = (
            f"\n\n## Adaptive Goal Decomposition\n"
            f"The user's current capability scalar is {self.user_capability_scalar}. "
            "Multiply the estimated base difficulty/time and xp_reward of generated tasks by this scalar."
        )

        dynamic_context += (
            "\n\n## Momentum-Aware Roadmap Pacing\n"
            f"Current streak: {streak_value} days ({streak_tier}). "
            "Use a lighter first milestone and shorter tasks when streak is low, a balanced progression for steady streaks, "
            "and a slightly more ambitious final milestone when the user is on a strong streak. "
            "Break the roadmap into clear win-sized steps so the user can keep momentum without feeling overwhelmed."
        )

        if coach_state:
            dynamic_context += (
                "\n\n## Coach Signal\n"
                f"Current coach state: {coach_state}. Use this as a pacing signal when shaping the roadmap: "
                "ENGAGED users can handle deeper tasks, WAVERING users should get smaller wins and tighter time estimates, "
                "and SILENT_RECESS users need the most supportive, low-friction breakdown."
            )

        if roadmap_context:
            dynamic_context += f"\n\n## User's Current Roadmap\nThe user already has an active roadmap:\n{roadmap_context}\nDo not generate a NEW roadmap unless explicitly requested to overwrite it. Reference their current progress."

        if memory_context:
            dynamic_context += (
                "\n\n## Recent Conversation Memory\n"
                "Use this memory to keep continuity and help the user retrieve or modify existing roadmaps safely:\n"
                f"{memory_context}"
            )
        
        dynamic_context += """
## Navigation Commands
If the user explicitly asks to see their roadmap, asks to navigate to it, or asks to start learning, reply using EXACTLY this JSON format (no other text outside of it):
```json
{"navigate_to": "roadmap", "message": "Let's go to your roadmap!"}
```
You can customize the "message" field.
"""

        # Put the core system prompt LAST so the strict output JSON formatting rules are the final things the model reads.
        self._system_prompt = dynamic_context + "\n\n" + get_system_prompt(domain)

        # Configure Gemini GenAI SDK
        settings = get_settings()
        if settings.GEMINI_API_KEY:
            self._client = genai.Client(api_key=settings.GEMINI_API_KEY)
            self._chat = self._client.chats.create(
                model="gemini-2.5-flash",
                config=types.GenerateContentConfig(
                    system_instruction=self._system_prompt,
                    temperature=0.7,
                )
            )
            self._offline = False
        else:
            logger.warning("GEMINI_API_KEY not set — running in offline demo mode")
            self._model = None
            self._chat = None
            self._offline = True
            self._demo_step = 0

    async def chat(self, user_message: str) -> tuple[str, bool, bool, list[str] | None]:
        """
        Send a user message and get the Guru's reply.

        Returns:
            (reply_text, is_roadmap_ready, navigate_to_roadmap, options)
        """
        self.history.append({"role": "user", "content": user_message})

        if self._offline:
            reply, is_ready = self._demo_response(user_message)
        else:
            reply, is_ready = await self._gemini_response(user_message)

        # Parse QUICK_REPLY options from the reply
        options = self._extract_quick_reply(reply)
        if options:
            reply = re.sub(r'\n?QUICK_REPLY:\[.*?\]', '', reply).strip()

        self.history.append({"role": "assistant", "content": reply})

        # Check if the reply contains a roadmap
        if is_ready:
            self.roadmap = self._extract_roadmap(reply)
            if self.roadmap:
                # Reply may be raw JSON (from json mode) or ROADMAP_READY+markdown — strip both.
                try:
                    json.loads(reply.strip())
                    clean_reply = "🎉 Your personalized roadmap is ready! Head to the Goals tab to start learning."
                except (json.JSONDecodeError, ValueError):
                    clean_reply = re.sub(
                        r"ROADMAP_READY\s*```json\s*[\s\S]*?```",
                        "🎉 Your personalized roadmap is ready! Head to the Goals tab to start learning.",
                        reply,
                    )
                self.history[-1]["content"] = clean_reply
                return clean_reply, True, False, None

        # Parse navigate_to signals
        navigate_to_roadmap = False
        try:
            parsed = json.loads(reply)
            if parsed.get("navigate_to") == "roadmap":
                navigate_to_roadmap = True
                reply = parsed.get("message", "Navigating to your roadmap!")
        except Exception:
            match = re.search(r"```json\s*({[\s\S]*?})\s*```", reply)
            if match:
                try:
                    parsed = json.loads(match.group(1))
                    if parsed.get("navigate_to") == "roadmap":
                        navigate_to_roadmap = True
                        reply = parsed.get("message", "Navigating to your roadmap!")
                except Exception:
                    pass

        self.history[-1]["content"] = reply
        return reply, False, navigate_to_roadmap, options

    @staticmethod
    def _extract_quick_reply(text: str) -> list[str] | None:
        """Extract QUICK_REPLY:[...] options from the Guru's response."""
        match = re.search(r'QUICK_REPLY:\[(.+?)\]', text)
        if match:
            try:
                items = json.loads(f'[{match.group(1)}]')
                return [str(i) for i in items]
            except Exception:
                pass
        return None

    async def _gemini_response(self, user_message: str) -> tuple[str, bool]:
        """Get response from Gemini API.

        Flow:
        1. Normal conversational call (text mode).
        2. If the model emits ROADMAP_READY (signaling it has enough info), parse
           the embedded JSON. If parsing succeeds, return it. If the JSON is
           malformed/truncated, do a second JSON-mode call to get clean output.
        3. Otherwise return the text reply as-is (more questions / chit-chat).
        """
        try:
            response = await asyncio.wait_for(
                asyncio.to_thread(self._chat.send_message, user_message),
                timeout=60,
            )
            reply = response.text or ""
        except asyncio.TimeoutError:
            logger.error("Gemini API timed out (conversation pass)")
            return "I'm taking too long — please send your message again.", False
        except Exception as e:
            logger.error("Gemini API error: %s", e)
            return "I'm having a moment — could you try again?", False

        signaled_ready = "ROADMAP_READY" in reply
        has_json_block = "```json" in reply and '"milestones"' in reply
        has_inline_json = reply.strip().startswith("{") and '"milestones"' in reply

        # Try to extract a valid roadmap from the conversational reply.
        if signaled_ready or has_json_block or has_inline_json:
            if self._extract_roadmap(reply) is not None:
                return reply, True

            # The model signaled readiness but the JSON is malformed/missing.
            # Do a second pass forcing JSON mode for a clean roadmap.
            logger.info("Model signaled readiness; doing JSON-mode follow-up call")
            try:
                followup = await asyncio.wait_for(
                    asyncio.to_thread(
                        self._chat.send_message,
                        "Output the full roadmap JSON now. Return ONLY the JSON object, no surrounding text or markdown.",
                        config=types.GenerateContentConfig(
                            response_mime_type="application/json",
                            max_output_tokens=16000,
                        ),
                    ),
                    timeout=120,
                )
                json_reply = (followup.text or "").strip()
                clean = json_reply.replace("```json", "").replace("```", "").strip()
                parsed = json.loads(clean)
                if "milestones" in parsed:
                    return clean, True
            except asyncio.TimeoutError:
                logger.error("Gemini JSON-mode follow-up timed out")
            except json.JSONDecodeError as e:
                logger.error("JSON-mode follow-up returned invalid JSON: %s", e)
            except Exception as e:
                logger.error("JSON-mode follow-up failed: %s", e)

            # Fall through — return the original reply (without is_ready) so the user
            # at least sees something. Frontend will not navigate.
            return reply, False

        return reply, False

    def _demo_response(self, user_message: str) -> tuple[str, bool]:
        """Offline demo responses that simulate the Guru conversation flow."""
        self._demo_step += 1

        if self._demo_step == 1:
            return (
                "Welcome! I'm your Eklavya Guru 🧠\n\n"
                "I'd love to help you create a personalized learning roadmap. "
                "To start — what specific skill, project, or goal do you want to master?",
                False,
            )
        elif self._demo_step == 2:
            return (
                "Great choice! That's a fascinating area with lots of practical applications.\n\n"
                "How would you describe your current experience level in this domain? Are you a complete beginner, "
                "or do you have some background already?",
                False,
            )
        elif self._demo_step == 3:
            return (
                "Perfect, that helps me calibrate the roadmap for you.\n\n"
                "One more thing — how much time can you realistically commit per day? "
                "Even 30 minutes of focused learning adds up quickly!",
                False,
            )
        else:
            # Generate demo roadmap
            roadmap = self._generate_demo_roadmap()
            roadmap_json = json.dumps(roadmap, indent=2)
            reply = f"ROADMAP_READY\n```json\n{roadmap_json}\n```"
            return reply, True

    def _generate_demo_roadmap(self) -> dict:
        """Generate a hardcoded generic roadmap for demo mode."""
        return {
            "title": "Master Your Goal",
            "domain": "learning",
            "estimated_weeks": 12,
            "milestones": [
                {
                    "title": "Math & Python Foundations",
                    "order": 1,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Watch overview video for basics", "type": "watch", "xp_reward": 20, "estimated_minutes": 45},
                        {"title": "Read introductory guide", "type": "read", "xp_reward": 20, "estimated_minutes": 40},
                        {"title": "Fundamental skills practice", "type": "practice", "xp_reward": 30, "estimated_minutes": 60},
                        {"title": "Quiz: Core concepts", "type": "quiz", "xp_reward": 25, "estimated_minutes": 15},
                    ],
                },
                {
                    "title": "Intermediate Techniques",
                    "order": 2,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Watch: Component architecture", "type": "watch", "xp_reward": 25, "estimated_minutes": 30},
                        {"title": "Read: Deep Learning Book Ch.6 — Deep Feedforward Networks", "type": "read", "xp_reward": 20, "estimated_minutes": 50},
                        {"title": "Code a perceptron from scratch in Python", "type": "practice", "xp_reward": 40, "estimated_minutes": 90},
                        {"title": "Implement backpropagation manually", "type": "practice", "xp_reward": 45, "estimated_minutes": 120},
                    ],
                },
                {
                    "title": "CNNs & Computer Vision",
                    "order": 3,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Watch: CNN explainers (Andrej Karpathy)", "type": "watch", "xp_reward": 25, "estimated_minutes": 40},
                        {"title": "Build an image classifier with PyTorch", "type": "practice", "xp_reward": 50, "estimated_minutes": 120},
                        {"title": "Transfer learning with ResNet", "type": "practice", "xp_reward": 40, "estimated_minutes": 90},
                        {"title": "Quiz: Convolution operations", "type": "quiz", "xp_reward": 25, "estimated_minutes": 20},
                    ],
                },
                {
                    "title": "RNNs & Sequence Models",
                    "order": 4,
                    "estimated_days": 10,
                    "tasks": [
                        {"title": "Read: Understanding LSTMs (Chris Olah)", "type": "read", "xp_reward": 20, "estimated_minutes": 30},
                        {"title": "Build a text generator with LSTM", "type": "practice", "xp_reward": 45, "estimated_minutes": 120},
                        {"title": "Sequence-to-sequence model basics", "type": "watch", "xp_reward": 25, "estimated_minutes": 45},
                    ],
                },
                {
                    "title": "Transformers & Attention",
                    "order": 5,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Read: Attention Is All You Need (paper)", "type": "read", "xp_reward": 30, "estimated_minutes": 60},
                        {"title": "Watch: Andrej Karpathy — Let's build GPT", "type": "watch", "xp_reward": 30, "estimated_minutes": 120},
                        {"title": "Build a mini-GPT from scratch", "type": "practice", "xp_reward": 50, "estimated_minutes": 180},
                        {"title": "Fine-tune a HuggingFace model", "type": "practice", "xp_reward": 45, "estimated_minutes": 90},
                    ],
                },
                {
                    "title": "Capstone Project",
                    "order": 6,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Choose and scope your project", "type": "custom", "xp_reward": 15, "estimated_minutes": 30},
                        {"title": "Implement and train your model", "type": "practice", "xp_reward": 50, "estimated_minutes": 240},
                        {"title": "Write a project report / blog post", "type": "write", "xp_reward": 35, "estimated_minutes": 90},
                        {"title": "Deploy model as an API", "type": "practice", "xp_reward": 40, "estimated_minutes": 120},
                    ],
                },
            ],
        }

    def _extract_roadmap(self, text: str) -> dict | None:
        """Extract JSON roadmap from the Guru's response."""
        try:
            # First try parsing it as pure JSON
            try:
                parsed = json.loads(text.strip())
                if "milestones" in parsed:
                    return parsed
            except json.JSONDecodeError:
                # Fallback: Look for JSON block in markdown
                match = re.search(r"```json\s*([\s\S]*?)\s*```", text)
                if match:
                    return json.loads(match.group(1))
        except (json.JSONDecodeError, AttributeError) as e:
            logger.error("Failed to parse roadmap JSON: %s", e)
        return None

    def get_history(self) -> list[dict[str, str]]:
        """Return the conversation history."""
        return self.history.copy()

    def reset(self) -> None:
        """Reset the conversation."""
        self.history = []
        self.roadmap = None
        self._demo_step = 0
        if self._chat and not self._offline:
            self._chat = self._client.chats.create(
                model="gemini-2.5-flash",
                config=types.GenerateContentConfig(
                    system_instruction=self._system_prompt,
                    temperature=0.7,
                )
            )
