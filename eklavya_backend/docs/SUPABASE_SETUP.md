# Supabase Setup Guide

Step-by-step instructions to set up the Supabase backend for Eklavya.AI.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) → **New Project**
2. Choose a name (e.g., `eklavya-dev`), set a database password, select a region
3. Wait ~2 minutes for provisioning

## 2. Get Connection Details

Navigate to **Settings → Database**:

1. Copy the **Session Mode** connection string (port `5432`)
2. **Important**: Replace the `postgresql://` prefix with `postgresql+asyncpg://`
3. This becomes `DATABASE_URL` in your `.env`

Example:
```
postgresql+asyncpg://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres
```

## 3. Get API Keys

Navigate to **Settings → API**:

| What | Where | `.env` Variable |
|------|-------|-----------------|
| Project URL | Top of API page | `SUPABASE_URL` |
| `anon` public key | Under "Project API keys" | `SUPABASE_ANON_KEY` |
| JWT Secret | Under "JWT Settings" | `JWT_SECRET` |

## 4. Run the SQL Migration

1. Go to **SQL Editor** in the Supabase Dashboard
2. Paste the contents of `migrations/001_initial_schema.sql`
3. Click **Run**
4. Verify tables appear in **Table Editor** (users, goals, milestones, tasks)

## 5. Create Your `.env`

```bash
cp .env.example .env
```

Fill in all values from steps 2–3.

## 6. Create a Test User

1. Go to **Authentication → Users → Add User**
2. Create with email + password
3. Note the user UUID — you'll see it in the Users table

## 7. Get a JWT Token

To test authenticated endpoints, you need a valid JWT:

```bash
curl -X POST "https://[PROJECT_REF].supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: [SUPABASE_ANON_KEY]" \
  -H "Content-Type: application/json" \
  -d '{"email": "[USER_EMAIL]", "password": "[USER_PASSWORD]"}'
```

The response includes an `access_token` — use it as `Bearer <token>` in API calls.

## 8. Start the Backend

```bash
cd eklavya_backend
uv sync
uv run python run.py
```

Visit **http://localhost:8000/docs** for the Swagger UI.

Click the 🔒 **Authorize** button, paste your `access_token`, and test the endpoints.
