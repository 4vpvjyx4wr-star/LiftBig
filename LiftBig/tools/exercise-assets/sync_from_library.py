#!/usr/bin/env python3
"""
Build exercise_list.json + name_map.json from src/utils/exerciseLibrary.ts.

Skips isCardio: true entries. Preserves curated edbQueries from an existing
name_map when the library id matches.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from pipeline.muscles import MUSCLE_GROUP_LABELS

ROOT = Path(__file__).resolve().parent
DEFAULT_LIBRARY = ROOT.parent.parent / "src" / "utils" / "exerciseLibrary.ts"
DEFAULT_LIST = ROOT / "exercise_list.json"
DEFAULT_MAP = ROOT / "name_map.json"


def _parse_reg_blocks(ts: str) -> list[dict]:
    """Extract id/name/muscleGroups/isCardio from each reg({...}) object."""
    blocks: list[dict] = []
    # Match reg({ ... }) at top level of EXERCISE_LIBRARY entries
    for m in re.finditer(r"reg\(\{", ts):
        start = m.end() - 1  # at '{'
        depth = 0
        i = start
        while i < len(ts):
            ch = ts[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    body = ts[start + 1 : i]
                    blocks.append(_parse_block_body(body))
                    break
            i += 1
    return blocks


def _parse_block_body(body: str) -> dict:
    eid_m = re.search(r"\bid:\s*'([^']+)'", body)
    name_m = re.search(r"\bname:\s*'([^']*)'", body)
    if not name_m:
        name_m = re.search(r'\bname:\s*"([^"]*)"', body)
    mg_m = re.search(r"\bmuscleGroups:\s*\[([^\]]*)\]", body)
    is_cardio = bool(re.search(r"\bisCardio:\s*true", body))

    muscles: list[str] = []
    if mg_m:
        muscles = re.findall(r"'([^']+)'", mg_m.group(1))

    return {
        "id": eid_m.group(1) if eid_m else "",
        "name": name_m.group(1) if name_m else "",
        "muscleGroups": muscles,
        "isCardio": is_cardio,
    }


def _edb_queries(name: str, eid: str) -> list[str]:
    """Derive sensible ExerciseDB search queries from display name + id."""
    queries: list[str] = []
    base = name.strip()
    if base:
        queries.append(base.lower())
        # Drop leading equipment words for alternate match
        alt = re.sub(
            r"^(barbell|dumbbell|cable|machine|smith|kettlebell|ez[- ]?bar)\s+",
            "",
            base,
            flags=re.I,
        ).strip()
        if alt and alt.lower() != base.lower():
            queries.append(alt.lower())
    # Kebab id → spaced
    from_id = eid.replace("-", " ").strip()
    if from_id and from_id not in queries:
        queries.append(from_id)
    # Dedupe preserve order
    seen: set[str] = set()
    out: list[str] = []
    for q in queries:
        key = re.sub(r"\s+", " ", q.lower()).strip()
        if key and key not in seen:
            seen.add(key)
            out.append(key)
    return out or [eid.replace("-", " ")]


def _muscles_from_groups(groups: list[str]) -> tuple[list[str], list[str]]:
    labels = [MUSCLE_GROUP_LABELS.get(g, g.title()) for g in groups]
    if not labels:
        return [], []
    return [labels[0]], labels[1:]


def build_maps(
    library_path: Path,
    *,
    existing_map: dict | None = None,
) -> tuple[list[str], dict]:
    ts = library_path.read_text(encoding="utf-8")
    blocks = _parse_reg_blocks(ts)

    # Index existing curated queries by id
    by_id: dict[str, dict] = {}
    if existing_map:
        for _name, meta in existing_map.items():
            eid = meta.get("id")
            if eid:
                by_id[eid] = meta

    exercise_list: list[str] = []
    name_map: dict = {}
    seen_ids: set[str] = set()

    for block in blocks:
        eid = block["id"]
        name = block["name"]
        if not eid or not name:
            continue
        if block["isCardio"]:
            continue
        if eid in seen_ids:
            continue
        seen_ids.add(eid)

        primary, secondary = _muscles_from_groups(block["muscleGroups"])
        prev = by_id.get(eid, {})
        queries = prev.get("edbQueries") or _edb_queries(name, eid)
        # Prefer curated muscles if present, else library-derived
        if prev.get("primaryMuscles"):
            primary = prev["primaryMuscles"]
            secondary = prev.get("secondaryMuscles") or secondary

        exercise_list.append(name)
        name_map[name] = {
            "id": eid,
            "edbQueries": queries,
            "primaryMuscles": primary,
            "secondaryMuscles": secondary,
        }

    return exercise_list, name_map


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Sync exercise asset maps from exerciseLibrary.ts")
    parser.add_argument("--library", type=Path, default=DEFAULT_LIBRARY)
    parser.add_argument("--list-out", type=Path, default=DEFAULT_LIST)
    parser.add_argument("--map-out", type=Path, default=DEFAULT_MAP)
    parser.add_argument(
        "--merge-existing",
        action="store_true",
        default=True,
        help="Preserve curated edbQueries from existing name_map by id (default)",
    )
    args = parser.parse_args(argv)

    existing = None
    if args.merge_existing and args.map_out.exists():
        existing = json.loads(args.map_out.read_text(encoding="utf-8"))

    exercise_list, name_map = build_maps(args.library, existing_map=existing)
    args.list_out.write_text(json.dumps(exercise_list, indent=2) + "\n", encoding="utf-8")
    args.map_out.write_text(json.dumps(name_map, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(exercise_list)} non-cardio exercises -> {args.list_out}")
    print(f"Wrote name map -> {args.map_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
