-- Migration: Add session_id to chat_memories for ChatGPT-style conversation grouping
-- Run this against your Supabase database

ALTER TABLE chat_memories
ADD COLUMN IF NOT EXISTS session_id UUID DEFAULT gen_random_uuid();

CREATE INDEX IF NOT EXISTS idx_chat_memories_session_id ON chat_memories(session_id);
