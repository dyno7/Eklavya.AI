---
phase: 7
plan: 4
wave: 4
depends_on: [1, 2, 3]
autonomous: false
files_modified:
  - eklavya_backend/app/presentation/chat.py
  - eklavya_backend/app/agents/guru_agent.py
---

# Plan 7.4: Gemini Debug Endpoint + E2E Smoke Test

## Objective
Before calling Phase 7 complete, verify that:
1. The Gemini API is actually being called (not always falling to demo mode)
2. The full E2E flow works on a physical/emulated device with real credentials

## Context
- eklavya_backend/app/agents/guru_agent.py
- eklavya_backend/app/presentation/chat.py
- eklavya_backend/.env

## Tasks

<task type="auto">
  <name>Add /api/chat/debug endpoint to show Gemini status</name>
  <files>
    eklavya_backend/app/presentation/chat.py
    eklavya_backend/app/agents/guru_agent.py
  </files>
  <action>
    1. In `guru_agent.py`, expose a `@property` or class attribute:
       ```python
       @property
       def mode(self) -> str:
           return "live" if self._live_mode else "demo"
       ```
       Where `_live_mode` is set to `True` only if the Gemini API call succeeds on first use.
    2. In `chat.py`, add:
       ```python
       @router.get("/debug")
       async def debug_status():
           """Non-authenticated debug endpoint — shows whether Gemini API is live or demo."""
           from app.core.config import get_settings
           settings = get_settings()
           return {
               "gemini_key_set": bool(settings.GEMINI_API_KEY),
               "gemini_key_preview": settings.GEMINI_API_KEY[:8] + "..." if settings.GEMINI_API_KEY else "NOT SET",
               "environment": settings.ENVIRONMENT,
           }
       ```
    3. Visit http://localhost:8000/api/chat/debug — if `gemini_key_set` is `false`, the `.env` key wasn't loaded.
  </action>
  <verify>curl http://localhost:8000/api/chat/debug returns {"gemini_key_set": true}</verify>
  <done>Debug endpoint confirms Gemini key is loaded and mode</done>
</task>

<task type="checkpoint:human-verify">
  <name>Full E2E Flow Verification</name>
  <action>
    1. Ensure `.env` has real values for all 4 Supabase fields + GEMINI_API_KEY
    2. Run backend: `uv run uvicorn app.main:app --reload`
    3. Check migration: `uv run alembic current` shows head
    4. Run Flutter: `flutter run -d <your_device>`
    5. Verify the following sequence:
       a. Splash → auto-navigates to Login (or Home if already logged in)
       b. Sign up with a fresh email → navigates to Home
       c. Home shows "No active goal yet" (no demo data)
       d. Open Chat tab → send "I want to learn Python"
       e. Guru responds in a real conversational way (Gemini, not canned responses)
       f. After 3-4 exchanges, Guru generates a roadmap
       g. Click "View Your Roadmap" → Home tab
       h. Home shows the real generated goal and tasks
       i. Tick off a task → XP snackbar appears → XP counter updates
    6. Verify http://localhost:8000/api/chat/debug shows `gemini_key_set: true`
  </action>
</task>

## Success Criteria
- [ ] `/api/chat/debug` confirms `gemini_key_set: true`
- [ ] Full E2E flow works (steps a-i above)
- [ ] No 401 errors visible in backend logs for authenticated endpoints
- [ ] Roadmap visible in Supabase Dashboard → Table Editor → goals table
