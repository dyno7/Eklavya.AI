import asyncio
import sys
from pathlib import Path
from urllib.parse import ParseResult, urlparse, urlunparse

from sqlalchemy.engine import make_url
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.config import get_settings
from app.core.database import get_engine


def _sanitize_url(raw_url: str) -> str:
    try:
        parsed = make_url(raw_url)
        return parsed.render_as_string(hide_password=True)
    except Exception:
        # Best effort masking for malformed URLs.
        if "@" in raw_url and ":" in raw_url.split("@", 1)[0]:
            prefix, suffix = raw_url.split("@", 1)
            user = prefix.rsplit(":", 1)[0]
            return f"{user}:***@{suffix}"
        return raw_url


def _derive_direct_url(pooler_url: str) -> str | None:
    """Build direct DB URL candidate from pooler URL when possible."""
    parsed = make_url(pooler_url)
    host = parsed.host or ""
    username = parsed.username or ""

    if not host.endswith(".pooler.supabase.com"):
        return None
    if not username.startswith("postgres."):
        return None

    project_ref = username.split(".", 1)[1]
    direct_host = f"db.{project_ref}.supabase.co"
    db_name = parsed.database or "postgres"

    query = dict(parsed.query)
    query["ssl"] = "require"

    direct = parsed.set(
        host=direct_host,
        port=5432,
        username="postgres",
        database=db_name,
        query=query,
    )
    return str(direct)


def _detect_malformed_userinfo(raw_url: str) -> list[str]:
    hints: list[str] = []
    try:
        parsed = make_url(raw_url)
    except Exception:
        return [
            "DATABASE_URL could not be parsed. This often means unescaped special characters in password.",
        ]

    host = parsed.host or ""
    query = dict(parsed.query)
    drivername = parsed.drivername or ""

    if drivername != "postgresql+asyncpg":
        hints.append("Invalid DB scheme/driver. Use postgresql+asyncpg://")

    if "@" in host or "]" in host or "[" in host:
        hints.append(
            "Host contains unexpected characters (likely password split issue). URL-encode DB password."
        )

    if not query.get("ssl") and not query.get("sslmode"):
        hints.append("Missing SSL query parameter. Add ?ssl=require.")

    return hints


async def _probe(db_url: str, label: str) -> bool:
    print(f"\n[{label}] { _sanitize_url(db_url) }")
    try:
        engine = create_async_engine(
            db_url,
            pool_pre_ping=True,
            connect_args={"ssl": "require", "statement_cache_size": 0},
        )
    except Exception as exc:
        print(f"Failed to initialize engine: {type(exc).__name__}: {exc}")
        return False
    try:
        async with engine.connect() as conn:
            result = await conn.execute(
                text("select current_user, current_database()")
            )
            row = result.first()
            print(f"Connected: user={row[0]} db={row[1]}")
            return True
    except Exception as exc:
        print(f"Failed: {type(exc).__name__}: {exc}")
        return False
    finally:
        await engine.dispose()


async def main() -> None:
    settings = get_settings()
    primary_url = settings.DATABASE_URL

    print("Checking database connectivity...")
    malformed_hints = _detect_malformed_userinfo(primary_url)
    if malformed_hints:
        print("Pre-check warnings:")
        for hint in malformed_hints:
            print(f"- {hint}")

    ok_primary = await _probe(primary_url, "primary")

    direct_candidate = _derive_direct_url(primary_url)
    ok_direct = False
    if direct_candidate:
        ok_direct = await _probe(direct_candidate, "derived_direct")

    print("\nSummary")
    print(f"primary_ok={ok_primary}")
    if direct_candidate:
        print(f"derived_direct_ok={ok_direct}")

    if not ok_primary and not ok_direct:
        print("\nHints")
        print("1) Recopy DB password from Supabase Dashboard -> Settings -> Database.")
        print("2) Ensure DATABASE_URL uses postgresql+asyncpg:// and includes ?ssl=require.")
        print("3) If using pooler host, username should be postgres.<project_ref>.")
        print("4) If password contains special chars, URL-encode it.")
        print("5) Try direct host db.<project_ref>.supabase.co:5432 with user postgres.")


if __name__ == "__main__":
    asyncio.run(main())
