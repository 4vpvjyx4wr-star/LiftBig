#!/usr/bin/env python3
"""
LiftBig exercise illustration asset pipeline.

Fetches free ExerciseDB OSS / Wikimedia media, applies the LiftBig visual theme,
and writes PNG thumbnails, looping GIFs, and exercise_assets.json into the app public/ folder.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from pipeline.download import download_asset
from pipeline.muscles import split_primary_secondary
from pipeline.process import (
    create_looping_gif,
    create_thumbnail,
    load_frames_from_bytes,
    process_frame,
    process_frames,
    union_content_bbox,
)
from pipeline.search import SearchResult, search_exercise_image
from pipeline.silhouette import generate_silhouette

ROOT = Path(__file__).resolve().parent
DEFAULT_LIST = ROOT / "exercise_list.json"
DEFAULT_MAP = ROOT / "name_map.json"
DEFAULT_OUT = ROOT.parent.parent / "public"  # LiftBig/public


def build_asset_library(
    exercise_list: list[str],
    *,
    name_map: dict,
    out_dir: Path,
    only: set[str] | None = None,
    skip_gif: bool = False,
    use_rembg: bool = True,
) -> list[dict]:
    """
    End-to-end generation for each exercise name in exercise_list.
    Returns manifest entries.
    """
    exercises_dir = out_dir / "assets" / "exercises"
    gifs_dir = exercises_dir / "gifs"
    data_dir = out_dir / "data"
    exercises_dir.mkdir(parents=True, exist_ok=True)
    gifs_dir.mkdir(parents=True, exist_ok=True)
    data_dir.mkdir(parents=True, exist_ok=True)

    attributions: list[str] = [
        f"# Exercise asset attributions",
        f"",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        f"",
        f"ExerciseDB OSS media: non-commercial use; attribute AscendAPI (https://exercisedb.dev).",
        f"Wikimedia Commons: see per-file license notes below.",
        f"",
    ]

    manifest: list[dict] = []
    # Merge existing manifest when --only is used
    manifest_path = data_dir / "exercise_assets.json"
    existing_by_id: dict[str, dict] = {}
    if manifest_path.exists() and only:
        try:
            for entry in json.loads(manifest_path.read_text(encoding="utf-8")):
                existing_by_id[entry["id"]] = entry
        except Exception:
            pass

    for name in exercise_list:
        meta = name_map.get(name)
        if not meta:
            print(f"[skip] No name_map entry for {name!r}", file=sys.stderr)
            continue
        eid = meta["id"]
        if only and eid not in only and name not in only:
            continue

        print(f"==> {name} ({eid})")
        queries = meta.get("edbQueries") or [name]
        primary, secondary = split_primary_secondary(
            meta.get("primaryMuscles"),
            meta.get("secondaryMuscles"),
        )

        result: SearchResult | None = search_exercise_image(name, edb_queries=queries)
        source = "silhouette"
        license_note = "Generated LiftBig silhouette (no third-party media)"
        frames_raw = []

        if result is not None:
            print(f"    source={result.source}  {result.title}")
            try:
                data = download_asset(result.url)
                frames_raw = load_frames_from_bytes(data)
                source = result.source
                license_note = result.license_note
                attributions.append(
                    f"- **{eid}** ({name}): {result.source} — {result.title} — "
                    f"{result.license_note}"
                    + (f" — {result.author}" if result.author else "")
                    + f" — {result.url}"
                )
            except Exception as exc:
                print(f"    download failed: {exc}; using silhouette", file=sys.stderr)
                result = None

        if not frames_raw:
            print("    using silhouette fallback")
            sil = generate_silhouette(eid, primary_count=len(primary))
            frames_raw = [sil.convert("RGBA")]
            attributions.append(f"- **{eid}** ({name}): silhouette fallback")

        try:
            themed = process_frames(frames_raw, use_rembg=use_rembg)
        except Exception as exc:
            print(f"    batch process error: {exc}; falling back per-frame", file=sys.stderr)
            themed = []
            for i, fr in enumerate(frames_raw):
                try:
                    themed.append(process_frame(fr, use_rembg=use_rembg and i == 0))
                except Exception as frame_exc:
                    print(f"    frame {i} process error: {frame_exc}", file=sys.stderr)
                    themed.append(process_frame(fr, use_rembg=False))

        if not themed:
            print(f"    [error] no frames for {eid}", file=sys.stderr)
            continue

        # Stable crop for thumbnail matches GIF framing when multi-frame
        thumb_bbox = union_content_bbox(themed) if len(themed) > 1 else None
        mid = themed[len(themed) // 2]
        thumb = create_thumbnail(mid, bbox=thumb_bbox)
        png_path = exercises_dir / f"{eid}.png"
        thumb.save(png_path, format="PNG", optimize=True)
        print(f"    wrote {png_path.relative_to(out_dir)}")

        anim_rel = None
        if not skip_gif:
            try:
                gif_bytes = create_looping_gif(themed)
                gif_path = gifs_dir / f"{eid}.gif"
                gif_path.write_bytes(gif_bytes)
                kb = len(gif_bytes) / 1024
                print(f"    wrote {gif_path.relative_to(out_dir)} ({kb:.0f} KB)")
                anim_rel = f"/assets/exercises/gifs/{eid}.gif"
            except Exception as exc:
                print(f"    gif failed: {exc}", file=sys.stderr)

        entry = {
            "id": eid,
            "name": name,
            "thumbnail": f"/assets/exercises/{eid}.png",
            "animation": anim_rel,
            "primaryMuscles": primary,
            "secondaryMuscles": secondary,
            "source": source,
            "licenseNote": license_note,
        }
        existing_by_id[eid] = entry
        manifest.append(entry)
        time.sleep(0.5)

    # Write full manifest (merged)
    if only and existing_by_id:
        final = list(existing_by_id.values())
    else:
        final = list(existing_by_id.values()) if existing_by_id else manifest
        if not only:
            final = manifest

    # Stable order by name from list when possible
    order = {name_map[n]["id"]: i for i, n in enumerate(exercise_list) if n in name_map}
    final.sort(key=lambda e: order.get(e["id"], 999))

    manifest_path.write_text(json.dumps(final, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {manifest_path}")

    attr_path = ROOT / "attributions.md"
    attr_path.write_text("\n".join(attributions) + "\n", encoding="utf-8")
    print(f"Wrote {attr_path}")

    return final


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Generate LiftBig exercise illustration assets")
    parser.add_argument("--list", type=Path, default=DEFAULT_LIST, help="JSON list of exercise names")
    parser.add_argument("--map", type=Path, default=DEFAULT_MAP, help="name_map.json path")
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help="App public/ directory (default: LiftBig/public)",
    )
    parser.add_argument(
        "--only",
        action="append",
        default=[],
        help="Only generate these ids or names (repeatable)",
    )
    parser.add_argument("--skip-gif", action="store_true", help="Skip GIF generation")
    parser.add_argument("--no-rembg", action="store_true", help="Disable rembg background removal")
    args = parser.parse_args(argv)

    exercise_list = json.loads(args.list.read_text(encoding="utf-8"))
    name_map = json.loads(args.map.read_text(encoding="utf-8"))
    only = set(args.only) if args.only else None

    build_asset_library(
        exercise_list,
        name_map=name_map,
        out_dir=args.out.resolve(),
        only=only,
        skip_gif=args.skip_gif,
        use_rembg=not args.no_rembg,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
