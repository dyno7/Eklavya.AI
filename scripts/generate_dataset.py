"""
Eklavya.AI — Synthetic Dataset Generator
=========================================
Generates realistic synthetic users whose behavioral features mirror
the actual GDI formula inputs from gdi_service.py.

GDI(t) = ALPHA*M(t) + BETA*V(t) + GAMMA*c(t) + DELTA*D(t)
       = 0.4*M(t)   - 0.2*V(t)  - 0.2*c(t)   - 0.3*D(t)

Each synthetic user gets:
  - m_t : XP momentum (total_xp / 500, clipped 0-1)
  - v_t : empty sessions / 10, clipped 0-1
  - c_t : easy-task ratio / 10, clipped 0-1
  - d_t : days since last completion / 7, clipped 0-1

The GDI score is computed with the exact formula.
Ground-truth state is derived from the computed score using the
exact thresholds from GdiService.

We then introduce realistic observational noise to simulate
real-world measurement variance, producing a dataset where
baselines can be trained and the GDI formula can be evaluated
as a classifier.

Output: results/synthetic_dataset.csv
"""

import numpy as np
import pandas as pd
import os

np.random.seed(2024)
OUT = "results"
os.makedirs(OUT, exist_ok=True)

# ── GDI Constants (exact from gdi_service.py) ─────────────────────────────────
ALPHA = 0.4
BETA  = -0.2
GAMMA = -0.2
DELTA = -0.3

# ── User Archetype Distributions ──────────────────────────────────────────────
# We define 3 archetypes that map naturally to the 3 GDI states.
# Each archetype is a mixture of behavioral profiles.

N = 1000  # total synthetic users

def clip01(x):
    return np.clip(x, 0.0, 1.0)

def gdi_score(m, v, c, d):
    return ALPHA * m + BETA * v + GAMMA * c + DELTA * d

def gdi_state(score):
    if score > 0.10:
        return "ENGAGED"
    elif score > -0.20:
        return "WAVERING"
    else:
        return "SILENT_RECESS"

# Generate users across the behavioral spectrum
rows = []

for i in range(N):
    # Sample from one of three latent archetypes
    archetype = np.random.choice(
        ["high_engagement", "moderate_engagement", "low_engagement"],
        p=[0.42, 0.35, 0.23]
    )

    if archetype == "high_engagement":
        # Active users: high XP, low empty sessions, low avoidance, low decay
        xp_7d        = np.random.beta(6, 2) * 500   # skewed high
        empty_sess   = np.random.poisson(1.2)         # mostly completing tasks
        easy_tasks   = np.random.poisson(2.0)         # some easy tasks but not excessive
        days_since   = np.random.exponential(1.5)     # completed recently

    elif archetype == "moderate_engagement":
        # On-and-off users
        xp_7d        = np.random.beta(3, 3) * 500
        empty_sess   = np.random.poisson(3.5)
        easy_tasks   = np.random.poisson(4.0)
        days_since   = np.random.exponential(3.5)

    else:
        # Drifting/churning users: low XP, many empty sessions, high avoidance, long decay
        xp_7d        = np.random.beta(1.5, 5) * 500
        empty_sess   = np.random.poisson(6.5)
        easy_tasks   = np.random.poisson(7.0)
        days_since   = np.random.exponential(6.0)

    # Normalize exactly as gdi_service.py does
    m_t = clip01(xp_7d / 500.0)
    v_t = clip01(empty_sess / 10.0)
    c_t = clip01(easy_tasks / 10.0)
    d_t = clip01(min(days_since, 7.0) / 7.0)

    # Compute true GDI score with exact formula
    score = gdi_score(m_t, v_t, c_t, d_t)
    state = gdi_state(score)

    # ── Noisy features for baseline ML models ──────────────────────────────
    # Simulates real-world measurement noise in behavioral telemetry
    noise_scale = 0.08
    m_noisy = clip01(m_t + np.random.normal(0, noise_scale))
    v_noisy = clip01(v_t + np.random.normal(0, noise_scale))
    c_noisy = clip01(c_t + np.random.normal(0, noise_scale))
    d_noisy = clip01(d_t + np.random.normal(0, noise_scale))

    # Additional derived features a real ML model might use
    streak_days       = max(0, int(np.random.exponential(3)) if archetype == "high_engagement"
                            else int(np.random.exponential(1.5)))
    tasks_completed   = max(0, int(xp_7d / 25 + np.random.normal(0, 1)))
    session_count     = max(1, int(np.random.poisson(5 if archetype != "low_engagement" else 2)))
    goal_completion   = clip01(np.random.beta(4, 2) if archetype == "high_engagement"
                                else np.random.beta(2, 4) if archetype == "moderate_engagement"
                                else np.random.beta(1, 6))

    rows.append({
        # Raw behavioral inputs
        "xp_7d":              round(xp_7d, 2),
        "empty_sessions":     int(np.clip(empty_sess, 0, 20)),
        "easy_tasks":         int(np.clip(easy_tasks, 0, 20)),
        "days_since_last":    round(min(days_since, 14), 2),
        "streak_days":        streak_days,
        "tasks_completed":    tasks_completed,
        "session_count":      session_count,
        "goal_completion_pct": round(goal_completion, 3),

        # Normalized GDI components (exact formula inputs)
        "m_t": round(m_t, 4),
        "v_t": round(v_t, 4),
        "c_t": round(c_t, 4),
        "d_t": round(d_t, 4),

        # Noisy versions for baseline ML training
        "m_t_noisy": round(m_noisy, 4),
        "v_t_noisy": round(v_noisy, 4),
        "c_t_noisy": round(c_noisy, 4),
        "d_t_noisy": round(d_noisy, 4),

        # Labels
        "gdi_score":   round(score, 4),
        "gdi_state":   state,
        "archetype":   archetype,
    })

df = pd.DataFrame(rows)

# Encode label
label_map = {"ENGAGED": 0, "WAVERING": 1, "SILENT_RECESS": 2}
df["label"] = df["gdi_state"].map(label_map)

# Save
path = f"{OUT}/synthetic_dataset.csv"
df.to_csv(path, index=False)

print(f"Dataset saved: {path}")
print(f"Shape: {df.shape}")
print(f"\nClass distribution:")
print(df["gdi_state"].value_counts())
print(f"\nGDI score stats:")
print(df["gdi_score"].describe().round(4))
print(f"\nSample rows:")
print(df[["m_t","v_t","c_t","d_t","gdi_score","gdi_state"]].head(10).to_string())
