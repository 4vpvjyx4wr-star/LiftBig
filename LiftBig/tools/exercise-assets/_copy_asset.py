"""Copy PNG+GIF assets between exercise ids and update manifest."""
from __future__ import annotations

import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PUBLIC = ROOT.parent.parent / "public"
EX = PUBLIC / "assets" / "exercises"
GIFS = EX / "gifs"
MANIFEST = PUBLIC / "data" / "exercise_assets.json"


def copy_asset(src_id: str, dst_id: str, *, note: str | None = None) -> None:
    src_png = EX / f"{src_id}.png"
    src_gif = GIFS / f"{src_id}.gif"
    dst_png = EX / f"{dst_id}.png"
    dst_gif = GIFS / f"{dst_id}.gif"

    if not src_png.exists():
        raise FileNotFoundError(f"Missing source PNG: {src_png}")
    shutil.copy2(src_png, dst_png)
    print(f"copied png {src_id} -> {dst_id}")

    has_gif = src_gif.exists()
    if has_gif:
        shutil.copy2(src_gif, dst_gif)
        print(f"copied gif {src_id} -> {dst_id}")
    elif dst_gif.exists():
        dst_gif.unlink()
        print(f"removed stale gif for {dst_id}")

    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))
    by_id = {e["id"]: e for e in entries}
    src = by_id.get(src_id, {})
    dst = by_id.get(dst_id, {"id": dst_id, "name": dst_id})
    dst = dict(dst)
    dst["thumbnail"] = f"/assets/exercises/{dst_id}.png"
    dst["animation"] = f"/assets/exercises/gifs/{dst_id}.gif" if has_gif else None
    dst["source"] = note or f"copied-from:{src_id}"
    dst["licenseNote"] = src.get("licenseNote") or dst.get("licenseNote") or f"Copied from {src_id}"
    if "primaryMuscles" not in dst and "primaryMuscles" in src:
        dst["primaryMuscles"] = src["primaryMuscles"]
    if "secondaryMuscles" not in dst and "secondaryMuscles" in src:
        dst["secondaryMuscles"] = src["secondaryMuscles"]
    by_id[dst_id] = dst
    out = list(by_id.values())
    out.sort(key=lambda e: e.get("name") or e["id"])
    MANIFEST.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(f"manifest updated for {dst_id} ({dst['source']})")


if __name__ == "__main__":
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--note", default=None)
    args = p.parse_args()
    copy_asset(args.src, args.dst, note=args.note or f"copied-from:{args.src}")
