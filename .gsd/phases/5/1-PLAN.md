---
phase: 5
plan: 1
wave: 1
depends_on: []
files_modified:
  - eklavya_backend/app/agents/__init__.py
  - eklavya_backend/app/agents/guru_agent.py
  - eklavya_backend/app/agents/prompts.py
  - eklavya_backend/app/presentation/chat.py
  - eklavya_backend/app/domain/schemas.py
  - eklavya_backend/app/main.py
  - eklavya_backend/pyproject.toml
autonomous: true
user_setup:
  - service: Google Gemini API (or OpenAI)
    why: "GenAI calls for the Guru Agent"
    env_vars:
      - name: GEMINI_API_KEY
        source: "Google AI Studio → Get API Key (https://aistudio.google.com/apikey)"

must_haves:
  truths:
    - "Guru Agent generates a structured roadmap from a user prompt"
    - "Chat API supports multi-turn conversation with session state"
    - "Domain-specific prompts exist for Learning (Deep Learning POC)"
  artifacts:
    - "app/agents/guru_agent.py exists with generate_roadmap()"
    - "app/agents/prompts.py exists with LEARNING_SYSTEM_PROMPT"
    - "app/presentation/chat.py has POST /api/chat/send and GET /api/chat/history"
---

# Plan 5.1: Backend Guru Agent + Chat API

## Objective
Build the GenAI Guru Agent on the backend and expose a chat API for multi-turn onboarding conversations. POC domain: Deep Learning.

Purpose: This is the brain of Eklavya — the conversational AI that takes a user's ambition ("I want to master Deep Learning") and produces a structured roadmap with milestones and tasks.

## Context
- .gsd/SPEC.md
- eklavya_backend/app/main.py
- eklavya_backend/app/domain/models.py
- eklavya_backend/app/domain/schemas.py
- eklavya_backend/app/domain/enums.py

## Tasks

<task type="auto">
  <name>Create Guru Agent with Gemini integration</name>
  <files>
    eklavya_backend/app/agents/__init__.py
    eklavya_backend/app/agents/guru_agent.py
    eklavya_backend/app/agents/prompts.py
    eklavya_backend/pyproject.toml
  </files>
  <action>
    1. Add `google-genai` (or `google-generativeai`) to pyproject.toml dependencies
    2. Create app/agents/__init__.py (empty, makes it a package)
    3. Create app/agents/prompts.py with:
       - SYSTEM_PROMPT_TEMPLATE: A template string that takes {domain} and returns a system prompt. The prompt instructs the AI to act as an expert Guru for the given domain, gather user preferences (time commitment, experience level, preferred resources), then generate a structured JSON roadmap
       - LEARNING_SYSTEM_PROMPT: Concrete system prompt for the "Learning" domain (Deep Learning POC) with specific curriculum knowledge
       - ROADMAP_SCHEMA: A JSON schema describing the expected output format: { title, domain, milestones: [{ title, order, tasks: [{ title, type, xpReward, estimatedMinutes }] }] }
    4. Create app/agents/guru_agent.py with:
       - class GuruAgent: stateful conversation manager
       - __init__(domain: str, user_id: str): loads system prompt for domain
       - async chat(user_message: str) -> str: sends message to Gemini, returns response
       - async generate_roadmap() -> dict: sends final prompt requesting JSON roadmap, parses and validates response
       - Conversation history stored in-memory (list of {role, content} dicts)
       - Uses google-genai SDK with model "gemini-2.0-flash"
    AVOID: Putting API keys in code — read from environment via app/core/config.py
    AVOID: Streaming for now — simple request/response for MVP
  </action>
  <verify>python -c "from app.agents.guru_agent import GuruAgent; print('OK')"</verify>
  <done>GuruAgent class importable, takes domain and user_id, has chat() and generate_roadmap() methods</done>
</task>

<task type="auto">
  <name>Create Chat API router with session management</name>
  <files>
    eklavya_backend/app/presentation/chat.py
    eklavya_backend/app/domain/schemas.py
    eklavya_backend/app/main.py
  </files>
  <action>
    1. Add chat schemas to domain/schemas.py:
       - ChatMessageRequest(message: str, domain: str = "learning")
       - ChatMessageResponse(reply: str, is_roadmap_ready: bool = False, roadmap: dict | None = None)
       - ChatHistoryResponse(messages: list[dict])
    2. Create app/presentation/chat.py with APIRouter(prefix="/api/chat"):
       - POST /send: Takes ChatMessageRequest + user_id (from auth header or query param for now)
         - Creates or retrieves GuruAgent for this user session (use a simple dict cache keyed by user_id)
         - Sends user message to agent, returns ChatMessageResponse
         - If the Guru determines the conversation is complete, auto-calls generate_roadmap() and includes the roadmap JSON in the response
       - GET /history/{user_id}: Returns conversation history for the session
       - POST /reset/{user_id}: Clears conversation and agent state
    3. Wire chat_router into app/main.py
    AVOID: Database persistence of chat messages for now — in-memory is fine for MVP
    AVOID: WebSocket/streaming — simple REST for now
  </action>
  <verify>Run backend, curl POST /api/chat/send with test message, verify response has reply field</verify>
  <done>POST /api/chat/send returns AI reply. GET /api/chat/history returns conversation. POST /api/chat/reset clears session.</done>
</task>

## Success Criteria
- [ ] GuruAgent generates coherent multi-turn conversation for Deep Learning domain
- [ ] Chat API has 3 endpoints: send, history, reset
- [ ] Roadmap JSON is valid and matches expected schema
- [ ] `python -m pytest` or manual curl test passes
