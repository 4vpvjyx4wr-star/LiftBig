"""Download remote exercise assets."""

from __future__ import annotations

import requests

USER_AGENT = (
    "LiftBigExerciseAssets/1.0 (https://github.com/local; educational fitness app; contact: local)"
)


def download_asset(url: str, timeout: int = 90) -> bytes:
    """Download asset bytes from a URL with light retry on 429."""
    last_err: Exception | None = None
    for attempt in range(4):
        try:
            r = requests.get(
                url,
                headers={
                    "User-Agent": USER_AGENT,
                    "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
                },
                timeout=timeout,
                stream=True,
            )
            if r.status_code == 429:
                import time

                time.sleep(2.0 * (attempt + 1))
                last_err = requests.HTTPError(f"429 for {url}")
                continue
            r.raise_for_status()
            chunks: list[bytes] = []
            total = 0
            max_bytes = 25 * 1024 * 1024
            for chunk in r.iter_content(chunk_size=65536):
                if not chunk:
                    continue
                total += len(chunk)
                if total > max_bytes:
                    raise ValueError(f"Asset too large (>25MB): {url}")
                chunks.append(chunk)
            return b"".join(chunks)
        except Exception as exc:
            last_err = exc
            import time

            time.sleep(1.0 * (attempt + 1))
    raise last_err or RuntimeError(f"Failed to download {url}")

