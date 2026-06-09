"""
Guru Agent — the conversational AI that creates personalized roadmaps.

Uses Groq (Llama 3.3 70B) for generation. Maintains per-session conversation history.
"""

import asyncio
import json
import logging
import re

from groq import AsyncGroq

from app.agents.prompts import get_system_prompt
from app.core.config import get_settings

logger = logging.getLogger(__name__)

_GROQ_MODEL = "llama-3.3-70b-versatile"


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

        # Core system prompt last so strict JSON rules are freshest in context.
        self._system_prompt = dynamic_context + "\n\n" + get_system_prompt(domain)

        settings = get_settings()
        if settings.GROQ_API_KEY:
            self._client = AsyncGroq(api_key=settings.GROQ_API_KEY)
            self._offline = False
        else:
            logger.warning("GROQ_API_KEY not set — running in offline demo mode")
            self._client = None
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
            reply, is_ready = await self._groq_response()

        # Parse QUICK_REPLY options from the reply
        options = self._extract_quick_reply(reply)
        if options:
            reply = re.sub(r'\n?QUICK_REPLY:\[.*?\]', '', reply).strip()

        self.history.append({"role": "assistant", "content": reply})

        # Check if the reply contains a roadmap
        if is_ready:
            self.roadmap = self._extract_roadmap(reply)
            if self.roadmap:
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

    def _build_messages(self) -> list[dict]:
        """Full message list: system prompt + conversation history."""
        return [{"role": "system", "content": self._system_prompt}] + self.history

    async def _groq_response(self) -> tuple[str, bool]:
        """Get response from Groq API (stateless — passes full history each call)."""
        messages = self._build_messages()
        reply = ""

        for attempt in range(3):
            try:
                response = await asyncio.wait_for(
                    self._client.chat.completions.create(
                        model=_GROQ_MODEL,
                        messages=messages,
                        temperature=0.7,
                        max_tokens=4096,
                    ),
                    timeout=60,
                )
                reply = response.choices[0].message.content or ""
                break
            except asyncio.TimeoutError:
                logger.error("Groq API timed out (attempt %d)", attempt + 1)
                if attempt == 2:
                    return "I'm taking too long — please send your message again.", False
            except Exception as e:
                err_str = str(e)
                if ("429" in err_str or "rate_limit" in err_str.lower()) and attempt < 2:
                    wait = 2 ** attempt
                    logger.warning("Groq 429 rate limit, retrying in %ss (attempt %d)", wait, attempt + 1)
                    await asyncio.sleep(wait)
                    continue
                logger.error("Groq API error: %s", e)
                if "429" in err_str or "rate_limit" in err_str.lower():
                    return "The AI is a bit overloaded right now — please try again in a moment.", False
                return "I'm having a moment — could you try again?", False

        signaled_ready = "ROADMAP_READY" in reply
        has_json_block = "```json" in reply and '"milestones"' in reply
        has_inline_json = reply.strip().startswith("{") and '"milestones"' in reply

        if signaled_ready or has_json_block or has_inline_json:
            if self._extract_roadmap(reply) is not None:
                return reply, True

            # Signal present but JSON malformed — do a JSON-mode follow-up.
            logger.info("Model signaled readiness; doing JSON-mode follow-up call")
            try:
                followup_messages = messages + [
                    {"role": "assistant", "content": reply},
                    {"role": "user", "content": "Output the full roadmap JSON now. Return ONLY the JSON object, no surrounding text or markdown."},
                ]
                followup = await asyncio.wait_for(
                    self._client.chat.completions.create(
                        model=_GROQ_MODEL,
                        messages=followup_messages,
                        temperature=0.1,
                        max_tokens=8000,
                        response_format={"type": "json_object"},
                    ),
                    timeout=120,
                )
                json_reply = (followup.choices[0].message.content or "").strip()
                parsed = json.loads(json_reply)
                if "milestones" in parsed:
                    return json_reply, True
            except asyncio.TimeoutError:
                logger.error("Groq JSON-mode follow-up timed out")
            except json.JSONDecodeError as e:
                logger.error("JSON-mode follow-up returned invalid JSON: %s", e)
            except Exception as e:
                logger.error("JSON-mode follow-up failed: %s", e)

            return reply, False

        return reply, False

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
                "Great choice! How would you describe your current experience level in this domain?",
                False,
            )
        elif self._demo_step == 3:
            return (
                "Perfect. How much time can you realistically commit per day? "
                "Even 30 minutes of focused learning adds up quickly!",
                False,
            )
        else:
            roadmap = self._generate_demo_roadmap()
            roadmap_json = json.dumps(roadmap, indent=2)
            reply = f"ROADMAP_READY\n```json\n{roadmap_json}\n```"
            return reply, True

    def _generate_demo_roadmap(self) -> dict:
        return {
            "title": "Master Your Goal",
            "domain": "learning",
            "estimated_weeks": 12,
            "milestones": [
                {
                    "title": "Foundations",
                    "order": 1,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Watch overview video", "type": "watch", "xp_reward": 20, "estimated_minutes": 45},
                        {"title": "Read introductory guide", "type": "read", "xp_reward": 20, "estimated_minutes": 40},
                        {"title": "Fundamentals practice", "type": "practice", "xp_reward": 30, "estimated_minutes": 60},
                        {"title": "Quiz: Core concepts", "type": "quiz", "xp_reward": 25, "estimated_minutes": 15},
                    ],
                },
                {
                    "title": "Intermediate Skills",
                    "order": 2,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Deep dive video", "type": "watch", "xp_reward": 25, "estimated_minutes": 30},
                        {"title": "Hands-on project", "type": "practice", "xp_reward": 40, "estimated_minutes": 90},
                        {"title": "Build something real", "type": "practice", "xp_reward": 45, "estimated_minutes": 120},
                    ],
                },
            ],
        }

    def _extract_roadmap(self, text: str) -> dict | None:
        """Extract JSON roadmap from the Guru's response."""
        try:
            try:
                parsed = json.loads(text.strip())
                if "milestones" in parsed:
                    return parsed
            except json.JSONDecodeError:
                match = re.search(r"```json\s*([\s\S]*?)\s*```", text)
                if match:
                    return json.loads(match.group(1))
        except (json.JSONDecodeError, AttributeError) as e:
            logger.error("Failed to parse roadmap JSON: %s", e)
        return None

    def get_history(self) -> list[dict[str, str]]:
        return self.history.copy()

    def reset(self) -> None:
        """Reset conversation state (history is all state; no chat object to recreate)."""
        self.history = []
        self.roadmap = None
        if self._offline:
            self._demo_step = 0
