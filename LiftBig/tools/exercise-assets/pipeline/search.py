"""Search free exercise media (ExerciseDB OSS, then Wikimedia Commons)."""

from __future__ import annotations

import json
import re
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import requests

EDB_API = "https://oss.exercisedb.dev/api/v1/exercises"
WIKI_API = "https://commons.wikimedia.org/w/api.php"
USER_AGENT = (
    "LiftBigExerciseAssets/1.0 (https://github.com/local; educational fitness app)"
)

_CACHE_PATH = Path(__file__).resolve().parent.parent / ".cache" / "edb_exercises.json"

# Skip cardio / sports style matches
_BLOCKED_KEYWORDS = (
    "running",
    "jogging",
    "treadmill",
    "elliptical",
    "cycling",
    "swim",
    "tennis",
    "boxing",
    "kickboxing",
    "soccer",
    "basketball",
    "volleyball",
    "skiing",
    "yoga",
    "pilates",
    "jump rope",
)


@dataclass
class SearchResult:
    url: str
    source: str  # exercisedb-oss | wikimedia | silhouette
    title: str
    license_note: str
    author: str = ""


def _normalize(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def _session() -> requests.Session:
    s = requests.Session()
    s.headers.update({"User-Agent": USER_AGENT, "Accept": "application/json"})
    return s


def _gif_from_item(item: dict[str, Any]) -> str | None:
    gif = item.get("gifUrl") or item.get("gif_url")
    if gif:
        return str(gif)
    gifs = item.get("gifUrls") or {}
    if isinstance(gifs, dict) and gifs:
        return str(gifs.get("180p") or gifs.get("360p") or next(iter(gifs.values())))
    return None


def _is_blocked(name: str) -> bool:
    n = name.lower()
    return any(k in n for k in _BLOCKED_KEYWORDS)


_STOP = {"the", "a", "an", "and", "or", "with", "to", "of", "v", "2", "3"}


def _tokens(s: str) -> set[str]:
    return {t for t in re.findall(r"[a-z0-9]+", s.lower()) if t not in _STOP and len(t) > 1}


def _score_name(query: str, candidate: str) -> int:
    nq = _normalize(query)
    nc = _normalize(candidate)
    if not nq or not nc:
        return 0
    if nq == nc:
        return 1000
    qt = _tokens(query)
    ct = _tokens(candidate)
    if not qt:
        return 0
    missing = qt - ct
    # Require all meaningful query tokens for a strong match
    if missing:
        if len(missing) > 1 or len(qt & ct) / len(qt) < 0.75:
            return 0
    overlap = len(qt & ct) / len(qt)
    # Prefer shorter, closer names (avoid "overhead tricep extension" for "overhead press")
    length_penalty = abs(len(nc) - len(nq))
    extra = len(ct - qt)
    score = int(overlap * 700) + max(0, 200 - length_penalty) - extra * 25
    if nq in nc or nc in nq:
        score += 150
    # Extra boost when candidate ends with same primary movement word
    q_words = [w for w in re.findall(r"[a-z0-9]+", query.lower()) if w not in _STOP]
    c_words = [w for w in re.findall(r"[a-z0-9]+", candidate.lower()) if w not in _STOP]
    if q_words and c_words and q_words[-1] == c_words[-1]:
        score += 80
    # Reject odd novelty names when query is a classic compound lift
    odd = ("potty", "sissy", "pistol", "jump", "impossible", "advanced")
    if any(o in candidate.lower() for o in odd) and len(qt) <= 3:
        score -= 400
    return score


def _to_result(item: dict[str, Any], query: str) -> SearchResult | None:
    name = str(item.get("name") or "")
    if _is_blocked(name):
        return None
    gif = _gif_from_item(item)
    if not gif:
        return None
    return SearchResult(
        url=gif,
        source="exercisedb-oss",
        title=name or query,
        license_note="Non-commercial; attribute AscendAPI / ExerciseDB OSS",
        author="AscendAPI",
    )


def _get_json(sess: requests.Session, url: str, params: dict[str, Any], retries: int = 4) -> Any:
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            r = sess.get(url, params=params, timeout=45)
            if r.status_code == 429:
                time.sleep(1.5 * (attempt + 1))
                continue
            r.raise_for_status()
            if not r.text.strip():
                time.sleep(0.8 * (attempt + 1))
                continue
            return r.json()
        except Exception as exc:
            last_err = exc
            time.sleep(0.8 * (attempt + 1))
    if last_err:
        raise last_err
    return None


def search_exercisedb_by_name(queries: list[str]) -> SearchResult | None:
    """Query ExerciseDB OSS with the `name` filter (fuzzy)."""
    sess = _session()
    best: tuple[int, SearchResult] | None = None
    for q in queries:
        try:
            payload = _get_json(sess, EDB_API, {"name": q, "limit": 25})
            items = payload.get("data") if isinstance(payload, dict) else payload
            if not isinstance(items, list):
                continue
        except Exception:
            continue

        for item in items:
            name = str(item.get("name") or "")
            score = _score_name(q, name)
            if score < 400:
                continue
            result = _to_result(item, q)
            if result is None:
                continue
            if best is None or score > best[0]:
                best = (score, result)
        time.sleep(0.35)

    return best[1] if best else None


def _load_edb_catalog(force: bool = False) -> list[dict[str, Any]]:
    """Paginate the full catalog with `after` cursors (cached for 7 days)."""
    _CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    if _CACHE_PATH.exists() and not force:
        age = time.time() - _CACHE_PATH.stat().st_mtime
        if age < 7 * 24 * 3600:
            return json.loads(_CACHE_PATH.read_text(encoding="utf-8"))

    sess = _session()
    all_items: list[dict[str, Any]] = []
    after: str | None = None
    limit = 50
    seen_cursors: set[str] = set()

    while True:
        params: dict[str, Any] = {"limit": limit}
        if after:
            params["after"] = after
        r = sess.get(EDB_API, params=params, timeout=60)
        r.raise_for_status()
        payload = r.json()
        if isinstance(payload, list):
            all_items.extend(payload)
            break
        if not isinstance(payload, dict):
            break

        batch = payload.get("data") or []
        all_items.extend(batch)
        meta = payload.get("meta") or {}
        if not meta.get("hasNextPage"):
            break
        nxt = meta.get("nextCursor")
        if not nxt or nxt in seen_cursors:
            break
        seen_cursors.add(str(nxt))
        after = str(nxt)
        time.sleep(0.2)
        # Safety cap
        if len(all_items) >= 2000:
            break

    _CACHE_PATH.write_text(json.dumps(all_items), encoding="utf-8")
    return all_items


def search_exercisedb_catalog(queries: list[str]) -> SearchResult | None:
    catalog = _load_edb_catalog()
    best: tuple[int, SearchResult] | None = None
    for q in queries:
        for item in catalog:
            name = str(item.get("name") or "")
            score = _score_name(q, name)
            if score < 400:
                continue
            result = _to_result(item, q)
            if result is None:
                continue
            if best is None or score > best[0]:
                best = (score, result)
    return best[1] if best else None


def search_wikimedia(queries: list[str]) -> SearchResult | None:
    sess = _session()
    for q in queries:
        search = f"{q} exercise OR weightlifting OR fitness"
        params = {
            "action": "query",
            "format": "json",
            "generator": "search",
            "gsrsearch": search,
            "gsrnamespace": 6,
            "gsrlimit": 12,
            "prop": "imageinfo",
            "iiprop": "url|extmetadata|mime|size",
            "iiurlwidth": 640,
        }
        try:
            r = sess.get(WIKI_API, params=params, timeout=45)
            r.raise_for_status()
            pages = (r.json().get("query") or {}).get("pages") or {}
        except Exception:
            continue

        for page in pages.values():
            infos = page.get("imageinfo") or []
            if not infos:
                continue
            info = infos[0]
            mime = (info.get("mime") or "").lower()
            if not any(x in mime for x in ("image/png", "image/jpeg", "image/gif", "image/webp")):
                continue
            meta = info.get("extmetadata") or {}
            license_short = (meta.get("LicenseShortName") or {}).get("value", "")
            license_lower = license_short.lower()
            if license_lower and any(
                t in license_lower for t in ("all rights", "copyright", "fair use")
            ):
                continue
            url = info.get("thumburl") or info.get("url")
            if not url:
                continue
            title = page.get("title", q)
            if _is_blocked(title):
                continue
            # Require the result to look like an exercise illustration, not stock lifestyle photos
            title_l = title.lower()
            stock_reject = (
                "attractive",
                "wellness",
                "portrait",
                "lifestyle",
                "fashion",
                "model posing",
            )
            if any(s in title_l for s in stock_reject):
                continue
            q_tokens = _tokens(q)
            overlap = len(q_tokens & _tokens(title)) if q_tokens else 0
            if q_tokens and overlap < max(1, (len(q_tokens) + 1) // 2):
                continue
            artist = (meta.get("Artist") or {}).get("value", "")
            artist = re.sub(r"<[^>]+>", "", artist).strip()
            return SearchResult(
                url=url,
                source="wikimedia",
                title=title,
                license_note=f"Wikimedia Commons ({license_short or 'unknown'})",
                author=artist,
            )
        time.sleep(0.25)
    return None


def search_exercise_image(
    exercise_name: str,
    *,
    edb_queries: list[str] | None = None,
) -> SearchResult | None:
    """
    Find a usable free exercise image/GIF.
    Priority: ExerciseDB name filter → ExerciseDB catalog → Wikimedia → None.
    """
    queries = list(edb_queries or [])
    if exercise_name not in queries:
        queries.insert(0, exercise_name)

    result = search_exercisedb_by_name(queries)
    if result:
        return result

    try:
        result = search_exercisedb_catalog(queries)
        if result:
            return result
    except Exception:
        pass

    result = search_wikimedia(queries)
    if result:
        return result

    return None
