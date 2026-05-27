-- Eklavya.AI — Performance + Adaptive GDI Migration
-- Run this once against your Supabase database.
-- All statements are idempotent (IF NOT EXISTS / IF EXISTS guards).

-- ── 1. Missing indexes on hot query paths ─────────────────────────────────────

-- Dashboard active goal lookup (goals(user_id, status))
CREATE INDEX IF NOT EXISTS idx_goals_user_status
    ON goals(user_id, status, created_at DESC);

-- claim-task milestone completion check (tasks per milestone + status)
CREATE INDEX IF NOT EXISTS idx_tasks_milestone_status
    ON tasks(milestone_id, status);

-- GDI sweep + analytics: completed tasks by time
CREATE INDEX IF NOT EXISTS idx_tasks_completed_at
    ON tasks(completed_at)
    WHERE status = 'completed';

-- Chat sessions window query: chat_memories by user + session + role + time
CREATE INDEX IF NOT EXISTS idx_chat_memory_user_session
    ON chat_memories(user_id, session_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_chat_memory_session_role
    ON chat_memories(session_id, role, created_at ASC);

-- Session logs for GDI sweep
CREATE INDEX IF NOT EXISTS idx_session_logs_user_time
    ON user_session_logs(user_id, login_timestamp DESC);

-- ── 2. Adaptive GDI weights table ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_gdi_weights (
    user_id      UUID        PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    alpha        FLOAT       NOT NULL DEFAULT  0.4,
    beta         FLOAT       NOT NULL DEFAULT -0.2,
    gamma        FLOAT       NOT NULL DEFAULT -0.2,
    delta        FLOAT       NOT NULL DEFAULT -0.3,
    update_count INTEGER     NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for nightly sweep reads (updated_at for staleness checks)
CREATE INDEX IF NOT EXISTS idx_user_gdi_weights_updated
    ON user_gdi_weights(updated_at DESC);

-- ── 3. Verify indexes exist ────────────────────────────────────────────────────
-- Run this SELECT after applying to confirm:
-- SELECT indexname, tablename FROM pg_indexes
-- WHERE schemaname = 'public'
-- AND indexname LIKE 'idx_%'
-- ORDER BY tablename, indexname;
