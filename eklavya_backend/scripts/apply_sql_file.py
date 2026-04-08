import argparse
import asyncio
import sys
from pathlib import Path

import asyncpg

sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.config import get_settings


def _to_asyncpg_dsn(database_url: str) -> str:
    if database_url.startswith("postgresql+asyncpg://"):
        return database_url.replace("postgresql+asyncpg://", "postgresql://", 1)
    return database_url


async def main() -> None:
    parser = argparse.ArgumentParser(description="Apply a SQL file to configured database")
    parser.add_argument("sql_file", help="Path to SQL file")
    args = parser.parse_args()

    sql_path = Path(args.sql_file)
    if not sql_path.is_absolute():
        sql_path = Path.cwd() / sql_path

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    sql_text = sql_path.read_text(encoding="utf-8")
    dsn = _to_asyncpg_dsn(get_settings().DATABASE_URL)

    conn = await asyncpg.connect(dsn=dsn, ssl="require", statement_cache_size=0)
    try:
        await conn.execute(sql_text)
        print(f"Applied SQL successfully: {sql_path}")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
