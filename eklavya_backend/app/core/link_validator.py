"""
Resource-link integrity checks.

LLMs (any provider) sometimes fabricate or hallucinate URLs, or suggest links
that have since gone dead. This module verifies each resource URL is actually
reachable and, when it isn't, swaps in a deterministic search-results URL
built from the resource's title — a search page never 404s, so the user
always lands somewhere useful.
"""

import asyncio
import logging
from urllib.parse import quote_plus

from app.core.http_client import get_http_client

logger = logging.getLogger(__name__)

_TIMEOUT = httpx.Timeout(4.0, connect=4.0)
_MAX_CONCURRENCY = 8
_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; EklavyaLinkChecker/1.0; "
        "+https://eklavya.ai)"
    )
}


def _fallback_url(title: str) -> str:
    """A Google search results URL for the resource title — never 404s."""
    return f"https://www.google.com/search?q={quote_plus(title or 'learning resource')}"


async def _is_reachable(url: str) -> bool:
    client = get_http_client()
    try:
        resp = await client.head(url, headers=_HEADERS, follow_redirects=True, timeout=_TIMEOUT)
        if resp.status_code < 400:
            return True
        if resp.status_code not in (403, 405):
            return False
    except httpx.HTTPError:
        pass

    # Some sites reject HEAD (403/405) or errored — retry with a ranged GET
    # so we don't download the full body just to check liveness.
    try:
        resp = await client.get(
            url,
            headers={**_HEADERS, "Range": "bytes=0-1023"},
            follow_redirects=True,
            timeout=_TIMEOUT,
        )
        return resp.status_code < 400
    except httpx.HTTPError:
        return False


async def _check_one(semaphore: asyncio.Semaphore, resource: dict) -> None:
    """Verify a single resource dict's URL in place (mutates url/verified)."""
    url = str(resource.get("url", "")).strip()
    title = str(resource.get("title", "")).strip() or url
    if not url:
        return
    async with semaphore:
        try:
            reachable = await _is_reachable(url)
        except Exception as e:
            logger.warning("Link check errored for %s: %s", url, e)
            reachable = False
    if reachable:
        resource["verified"] = True
    else:
        resource["url"] = _fallback_url(title)
        resource["verified"] = False


async def fix_resources(resources: list[dict]) -> list[dict]:
    """Verify each resource's URL; replace dead/unreachable ones with a safe fallback."""
    valid = [r for r in resources if isinstance(r, dict)]
    if not valid:
        return resources

    semaphore = asyncio.Semaphore(_MAX_CONCURRENCY)
    await asyncio.gather(*(_check_one(semaphore, r) for r in valid))
    return resources


async def fix_roadmap_resources(roadmap: dict) -> dict:
    """Walk a roadmap dict and verify/fix every task's resource links in place.

    All resources across the whole roadmap are checked in a single batch
    (one client, one concurrency-bounded semaphore) rather than per-task,
    so total concurrent requests stay capped regardless of roadmap size.
    """
    milestones = roadmap.get("milestones", [])
    if not isinstance(milestones, list):
        return roadmap

    all_resources: list[dict] = []
    for milestone in milestones:
        if not isinstance(milestone, dict):
            continue
        for task in milestone.get("tasks", []):
            if not isinstance(task, dict):
                continue
            for resource in task.get("resources", []):
                if isinstance(resource, dict):
                    all_resources.append(resource)

    if not all_resources:
        return roadmap

    semaphore = asyncio.Semaphore(_MAX_CONCURRENCY)
    await asyncio.gather(*(_check_one(semaphore, r) for r in all_resources))

    # Log validation results
    verified_count = sum(1 for r in all_resources if r.get("verified", False))
    fallback_count = len(all_resources) - verified_count
    logger.info("Link validation: %d verified, %d replaced with fallback", verified_count, fallback_count)

    return roadmap


async def validate_single_url(url: str, title: str = "") -> tuple[str, bool]:
    """
    Validate a single URL and return (validated_url, is_verified).
    If URL is not reachable, returns a Google search fallback URL and False.
    """
    if not url or not url.strip():
        return _fallback_url(title or "learning resource"), False

    reachable = await _is_reachable(url)
    if reachable:
        return url, True
    else:
        return _fallback_url(title or url), False


async def validate_resources_batch(resources: list[dict]) -> list[dict]:
    """Validate a batch of resources, returning updated list with verified flags."""
    valid = [r for r in resources if isinstance(r, dict)]
    if not valid:
        return resources

    semaphore = asyncio.Semaphore(_MAX_CONCURRENCY)
    await asyncio.gather(*(_check_one(semaphore, r) for r in valid))
    return resources
