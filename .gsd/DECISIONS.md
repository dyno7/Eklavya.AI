# Decisions Log

## Phase 11 Decisions

**Date:** 2026-04-14

### Scope
- **Goal Drift Index (GDI):** Full RL-based mechanism is mandated using a specific formula: `GDI(t) = a*M(t) + b*V(t) + g*c(t) + d*D(t)` acting as a Kalman Filter state estimation.
- **Adaptive Difficulty:** Task complications adapt organically based on the user's base completion rate (>0.8 increases difficulty, <0.8 decreases it).
- **Narrative Arc Scheduler:** Roadmap generation will follow heroic storytelling curves (Setup, Rising Action, Climax with identity shift & shareability).
- **Commitment Gradient Descent:** Interventions for disengagement won't spam the user; the system degrades gracefully and peacefully recalibrates.

### Approach
- **Chose:** Hybrid JIT + Scheduled System. 
- **Reason:** Guarantees absolute freshness during active sessions without lagging, while delegating heavy global analytics and overnight decay to a scalable APScheduler background job.
- **Chose:** Strict Relational Tables for raw logging initially.
- **Reason:** Provides the raw data needed to query analytics safely at scale.

### Constraints
- Need to hotfix the Gemini Python SDK to `google.genai` because the previous library is throwing deprecation crashes.
