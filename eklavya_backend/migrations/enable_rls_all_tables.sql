-- Eklavya.AI — Enable RLS on all user-data tables
-- Run in: Supabase Dashboard → SQL Editor
-- Safe to re-run (idempotent).
-- Your FastAPI backend uses the postgres superuser role,
-- so it bypasses RLS completely — nothing will break.

-- ── Core tables ───────────────────────────────────────────────
ALTER TABLE users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals            ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones       ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks            ENABLE ROW LEVEL SECURITY;

-- ── Gamification ──────────────────────────────────────────────
ALTER TABLE badges           ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges      ENABLE ROW LEVEL SECURITY;

-- ── Notifications & Chat ──────────────────────────────────────
ALTER TABLE notifications    ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_memories    ENABLE ROW LEVEL SECURITY;

-- ── GDI / Telemetry ───────────────────────────────────────────
ALTER TABLE user_session_logs   ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_behavior_logs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_signal_logs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_gdi_weights    ENABLE ROW LEVEL SECURITY;  -- already done, safe to re-run

-- ── Verify: this should return all 12 tables with rls = true ──
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
