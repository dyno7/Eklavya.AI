## Phase 9 Verification

### Must-Haves
- [x] Milestone auto-advance when all tasks done — VERIFIED (added `db.expire_all()` to force fresh ORM reads)
- [x] Display name not "User" — VERIFIED (auth.py already extracts from email prefix at L117-119, `ensure_user_display_name` updates DB)
- [x] Real analytics endpoint — VERIFIED (GET /api/v1/analytics/summary returns daily_xp, completion_rate, etc.)
- [x] XP bar uses real data — VERIFIED (value: 0.7 → totalXp % 100 / 100.0)
- [x] Streak dots use real data — VERIFIED (index < 5 → index < currentStreak.clamp(0, 7))
- [x] Task detail panel shows estimated time — VERIFIED (TaskItem.estimatedMinutes parsed from metadata)
- [x] Analytics tab uses real data — VERIFIED (weeklyXp from endpoint, completion rate card added)
- [x] Chat memory persisted — VERIFIED (already wired in chat.py L93-96 load + L122-128 save)

### Verdict: PASS
