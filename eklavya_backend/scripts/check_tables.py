import asyncio
import sys
from pathlib import Path

import asyncpg

sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.config import get_settings


async def main() -> None:
    settings = get_settings()
    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://", 1)
    conn = await asyncpg.connect(dsn=dsn, ssl="require", statement_cache_size=0)
    try:
        row = await conn.fetchrow(
            """
            select
                to_regclass('public.users') as users,
                to_regclass('public.goals') as goals,
                to_regclass('public.milestones') as milestones,
                to_regclass('public.tasks') as tasks,
                to_regclass('public.notifications') as notifications,
                to_regclass('public.badges') as badges,
                to_regclass('public.user_badges') as user_badges
            """
        )
        print(dict(row))
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
