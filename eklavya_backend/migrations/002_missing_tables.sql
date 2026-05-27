-- ============================================================
-- Eklavya.AI — Complete Schema Migration
-- Adds all tables and columns missing from 001_initial_schema.sql
-- Run once in Supabase SQL editor. All statements are idempotent.
-- ============================================================

-- ── 1. Users: add XP + streak columns ────────────────────────
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS total_xp      INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS current_streak INTEGER NOT NULL DEFAULT 0;

-- ── 2. task_type enum: add write + exercise ───────────────────
DO $$ BEGIN
    ALTER TYPE task_type ADD VALUE IF NOT EXISTS 'write';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TYPE task_type ADD VALUE IF NOT EXISTS 'exercise';
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 3. Badges ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS badges (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    description TEXT        NOT NULL DEFAULT '',
    icon_url    TEXT,
    required_xp INTEGER     NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_badges_name ON badges(name);

-- ── 4. User Badges ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_badges (
    id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id   UUID        NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
    badge_id  UUID        NOT NULL REFERENCES badges(id)  ON DELETE CASCADE,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user   ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge  ON user_badges(badge_id);

-- ── 5. Notifications ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    message     TEXT        NOT NULL DEFAULT '',
    type        VARCHAR(50) NOT NULL DEFAULT 'info',
    read_status BOOLEAN     NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- ── 6. Chat Memories ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_memories (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    role       VARCHAR(20) NOT NULL,
    content    TEXT        NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_memories_user    ON chat_memories(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_memories_session ON chat_memories(session_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_chat_memory_user_session
    ON chat_memories(user_id, session_id, created_at ASC);

-- ── 7. User Session Logs ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_session_logs (
    id                        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    login_timestamp           TIMESTAMPTZ NOT NULL DEFAULT now(),
    tasks_completed_in_session INTEGER    NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_session_logs_user_time
    ON user_session_logs(user_id, login_timestamp DESC);

-- ── 8. User Behavior Logs ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_behavior_logs (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date           DATE        NOT NULL,
    momentum_score FLOAT       NOT NULL DEFAULT 0.0,
    avoidance_count INTEGER    NOT NULL DEFAULT 0,
    decay_value    FLOAT       NOT NULL DEFAULT 0.0,
    gdi_score      FLOAT       NOT NULL DEFAULT 0.0
);

CREATE INDEX IF NOT EXISTS idx_behavior_logs_user_date
    ON user_behavior_logs(user_id, date DESC);

-- ── 9. Reward Signal Logs ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS reward_signal_logs (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp    TIMESTAMPTZ NOT NULL DEFAULT now(),
    action_type  VARCHAR(100) NOT NULL,
    reward_value FLOAT       NOT NULL DEFAULT 0.0
);

CREATE INDEX IF NOT EXISTS idx_reward_logs_user
    ON reward_signal_logs(user_id, timestamp DESC);

-- ── 10. Seed default badges ───────────────────────────────────
INSERT INTO badges (name, description, required_xp) VALUES
    ('First Steps',      'Completed your first task',    0),
    ('Novice',           'Earned 100 XP',              100),
    ('Centurion',        'Earned 500 XP',              500),
    ('Consistency',      'Maintained a 7-day streak',    0),
    ('Milestone Master', 'Completed a milestone',        0),
    ('Goal Crusher',     'Completed a goal',             0)
ON CONFLICT (name) DO NOTHING;

-- ── 11. User GDI Weights (idempotent — already in migration 002) ──
CREATE TABLE IF NOT EXISTS user_gdi_weights (
    user_id      UUID        PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    alpha        FLOAT       NOT NULL DEFAULT  0.4,
    beta         FLOAT       NOT NULL DEFAULT -0.2,
    gamma        FLOAT       NOT NULL DEFAULT -0.2,
    delta        FLOAT       NOT NULL DEFAULT -0.3,
    update_count INTEGER     NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
