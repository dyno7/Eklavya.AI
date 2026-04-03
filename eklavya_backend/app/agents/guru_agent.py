"""
Guru Agent — the conversational AI that creates personalized roadmaps.

Uses Google Gemini for generation. Maintains per-session conversation history.
"""

import json
import logging
import re

import google.generativeai as genai

from app.agents.prompts import get_system_prompt
from app.core.config import get_settings

logger = logging.getLogger(__name__)


class GuruAgent:
    """Stateful conversational agent for a single user session."""

    def __init__(self, domain: str, user_id: str):
        self.domain = domain
        self.user_id = user_id
        self.history: list[dict[str, str]] = []
        self.roadmap: dict | None = None
        self._system_prompt = get_system_prompt(domain)

        # Configure Gemini
        settings = get_settings()
        if settings.GEMINI_API_KEY:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self._model = genai.GenerativeModel(
                model_name="gemini-2.5-flash",
                system_instruction=self._system_prompt,
            )
            self._chat = self._model.start_chat(history=[])
            self._offline = False
        else:
            logger.warning("GEMINI_API_KEY not set — running in offline demo mode")
            self._model = None
            self._chat = None
            self._offline = True
            self._demo_step = 0

    async def chat(self, user_message: str) -> tuple[str, bool]:
        """
        Send a user message and get the Guru's reply.

        Returns:
            (reply_text, is_roadmap_ready)
        """
        self.history.append({"role": "user", "content": user_message})

        if self._offline:
            reply, is_ready = self._demo_response(user_message)
        else:
            reply, is_ready = await self._gemini_response(user_message)

        self.history.append({"role": "assistant", "content": reply})

        # Check if the reply contains a roadmap
        if is_ready:
            self.roadmap = self._extract_roadmap(reply)
            if self.roadmap:
                # Clean the reply — remove the JSON block for display
                clean_reply = re.sub(
                    r"ROADMAP_READY\s*```json\s*[\s\S]*?```",
                    "🎉 Your personalized roadmap is ready! I've created a structured plan tailored just for you.",
                    reply,
                )
                self.history[-1]["content"] = clean_reply
                return clean_reply, True

        return reply, False

    async def _gemini_response(self, user_message: str) -> tuple[str, bool]:
        """Get response from Gemini API."""
        try:
            response = self._chat.send_message(user_message)
            reply = response.text
            is_ready = "ROADMAP_READY" in reply
            return reply, is_ready
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            return f"I'm having a moment — could you try again? (Error: {type(e).__name__})", False

    def _demo_response(self, user_message: str) -> tuple[str, bool]:
        """Offline demo responses that simulate the Guru conversation flow."""
        self._demo_step += 1

        if self._demo_step == 1:
            return (
                "Welcome! I'm your Eklavya Guru for Deep Learning 🧠\n\n"
                "I'd love to help you create a personalized learning roadmap. "
                "To start — what specific aspect of Deep Learning interests you most? "
                "For example: computer vision, NLP, generative AI, or the fundamentals?",
                False,
            )
        elif self._demo_step == 2:
            return (
                "Great choice! That's a fascinating area with lots of practical applications.\n\n"
                "How would you describe your current experience level? Are you a complete beginner, "
                "or do you have some programming/math background already?",
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
        """Generate a hardcoded Deep Learning roadmap for demo mode."""
        return {
            "title": "Master Deep Learning",
            "domain": "learning",
            "estimated_weeks": 12,
            "milestones": [
                {
                    "title": "Math & Python Foundations",
                    "order": 1,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Linear algebra refresher (3Blue1Brown)", "type": "watch", "xp_reward": 20, "estimated_minutes": 45},
                        {"title": "Calculus for ML (Khan Academy)", "type": "watch", "xp_reward": 20, "estimated_minutes": 40},
                        {"title": "NumPy & matrix operations practice", "type": "practice", "xp_reward": 30, "estimated_minutes": 60},
                        {"title": "Quiz: Math foundations", "type": "quiz", "xp_reward": 25, "estimated_minutes": 15},
                    ],
                },
                {
                    "title": "Neural Network Basics",
                    "order": 2,
                    "estimated_days": 14,
                    "tasks": [
                        {"title": "Watch: But what is a Neural Network? (3B1B)", "type": "watch", "xp_reward": 25, "estimated_minutes": 30},
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
            # Look for JSON block after ROADMAP_READY
            match = re.search(r"```json\s*([\s\S]*?)\s*```", text)
            if match:
                return json.loads(match.group(1))
        except (json.JSONDecodeError, AttributeError) as e:
            logger.error(f"Failed to parse roadmap JSON: {e}")
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
            self._chat = self._model.start_chat(history=[])
