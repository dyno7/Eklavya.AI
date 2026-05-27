"""
Coach Agent — answers learning questions for a specific task or general domain.

Unlike the Guru (which only generates roadmaps), the Coach explains concepts,
suggests approaches, and provides curated resources for individual tasks.
"""

import asyncio
import json
import logging
import re

from google import genai
from google.genai import types

from app.core.config import get_settings

logger = logging.getLogger(__name__)

COACH_SYSTEM_PROMPT = """\
You are the Eklavya Coach — a sharp, practical tutor embedded inside a learning task.
Your job is to help learners understand concepts, debug problems, and find resources.
You are NOT a roadmap generator — if someone asks for a roadmap, tell them to use the Guru chat tab.

## BREVITY RULES
- Maximum 4 sentences per reply. Be direct and practical.
- Use numbered lists ONLY when walking through steps (max 5 steps).
- 1 emoji max per response.

## Resource Format
When you recommend a resource, include it inline as plain text with the URL in parentheses.
Example: "Check the official docs (https://docs.python.org) for the full reference."

## Task Context
You may be given a task title, description, type, and milestone. Use it to tailor every answer.
If a user asks something completely unrelated to their task, gently redirect once, then help anyway.

## Tone
Encouraging but not fluffy. Like a senior dev or researcher who gets to the point.
"""


class CoachAgent:
    """Stateful Coach session for one user conversation."""

    def __init__(
        self,
        task_title: str | None = None,
        task_description: str | None = None,
        task_type: str | None = None,
        milestone_title: str | None = None,
    ):
        self.history: list[dict[str, str]] = []

        context_parts = []
        if milestone_title:
            context_parts.append(f"Milestone: {milestone_title}")
        if task_title:
            context_parts.append(f"Task: {task_title}")
        if task_type:
            context_parts.append(f"Type: {task_type}")
        if task_description:
            context_parts.append(f"Description: {task_description}")

        task_context_block = ""
        if context_parts:
            task_context_block = (
                "\n\n## Current Task Context\n"
                + "\n".join(context_parts)
                + "\nAnswer questions in the context of this task."
            )

        system_prompt = COACH_SYSTEM_PROMPT + task_context_block

        settings = get_settings()
        if settings.GEMINI_API_KEY:
            self._client = genai.Client(api_key=settings.GEMINI_API_KEY)
            self._chat = self._client.chats.create(
                model="gemini-2.5-flash",
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=0.7,
                    max_output_tokens=1024,
                ),
            )
            self._offline = False
        else:
            self._chat = None
            self._offline = True

    async def ask(self, message: str) -> str:
        self.history.append({"role": "user", "content": message})

        if self._offline:
            reply = "I'm in offline mode — start the backend to get real coaching responses."
        else:
            reply = await self._gemini_response(message)

        self.history.append({"role": "assistant", "content": reply})
        return reply

    async def _gemini_response(self, message: str) -> str:
        try:
            response = await asyncio.wait_for(
                asyncio.to_thread(self._chat.send_message, message),
                timeout=30,
            )
            return response.text
        except asyncio.TimeoutError:
            logger.error("Coach agent timed out")
            return "Taking longer than expected — please try again."
        except Exception as e:
            logger.error("Coach agent error: %s", e)
            return "Something went wrong — could you rephrase that?"

    @staticmethod
    def parse_resources(text: str) -> list[dict]:
        """Extract URLs from the reply text for the Flutter resource card renderer."""
        urls = re.findall(r'https?://[^\s\)\"\']+', text)
        resources = []
        for url in urls:
            url = url.rstrip('.,;)')
            resources.append({"title": url, "url": url})
        return resources
