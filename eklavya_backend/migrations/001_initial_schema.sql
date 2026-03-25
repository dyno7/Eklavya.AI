-- ============================================================
-- Eklavya.AI — Initial Schema (Phase 1)
-- Core tables: users, goals, milestones, tasks
-- Gamification tables deferred to Phase 4 (ADR-005)
-- No RLS policies (ADR-010)
-- ============================================================

-- Enum types
CREATE TYPE domain_type AS ENUM ('learning', 'fitness', 'startup', 'finance', 'writing');
CREATE TYPE goal_status AS ENUM ('active', 'paused', 'completed', 'abandoned');
CREATE TYPE milestone_status AS ENUM ('locked', 'active', 'completed');
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed', 'skipped');
CREATE TYPE task_type AS ENUM ('read', 'watch', 'practice', 'quiz', 'custom');

-- ============================================================
-- Users
-- Syncs with Supabase auth.users. The id column references
-- the auth.users UUID so profile data stays linked to login.
-- ============================================================
CREATE TABLE users (
    id          UUID PRIMARY KEY,  -- matches auth.users.id
    display_name VARCHAR(255) NOT NULL DEFAULT '',
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE users IS 'Application user profiles linked to Supabase Auth';

-- ============================================================
-- Goals
-- A user's high-level objective in a specific domain.
-- metadata (JSONB) holds domain-specific fields without
-- needing separate tables per domain.
-- ============================================================
CREATE TABLE goals (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    domain      domain_type NOT NULL,
    title       VARCHAR(500) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    target_date DATE,
    metadata    JSONB NOT NULL DEFAULT '{}',
    status      goal_status NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE goals IS 'User goals across domains (learning, fitness, startup, etc.)';

CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goals_user_status ON goals(user_id, status);

-- ============================================================
-- Milestones
-- Ordered checkpoints within a goal. Each milestone groups
-- a set of tasks that form a logical learning/execution unit.
-- ============================================================
CREATE TABLE milestones (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id     UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    title       VARCHAR(500) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    order_index INTEGER NOT NULL DEFAULT 0,
    status      milestone_status NOT NULL DEFAULT 'locked',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE milestones IS 'Ordered checkpoints within a goal';

CREATE INDEX idx_milestones_goal_id ON milestones(goal_id);

-- ============================================================
-- Tasks
-- Individual actionable items within a milestone.
-- metadata (JSONB) stores domain-specific task details
-- (e.g., video URL for 'watch' type, quiz questions for 'quiz').
-- xp_reward is defined here but gamification tracking (XP logs,
-- badges, streaks) is deferred to Phase 4.
-- ============================================================
CREATE TABLE tasks (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    milestone_id  UUID NOT NULL REFERENCES milestones(id) ON DELETE CASCADE,
    title         VARCHAR(500) NOT NULL,
    description   TEXT NOT NULL DEFAULT '',
    task_type     task_type NOT NULL DEFAULT 'custom',
    metadata      JSONB NOT NULL DEFAULT '{}',
    xp_reward     INTEGER NOT NULL DEFAULT 10,
    order_index   INTEGER NOT NULL DEFAULT 0,
    status        task_status NOT NULL DEFAULT 'pending',
    due_date      DATE,
    completed_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE tasks IS 'Individual actionable items within a milestone';

CREATE INDEX idx_tasks_milestone_id ON tasks(milestone_id);
CREATE INDEX idx_tasks_status ON tasks(milestone_id, status);
