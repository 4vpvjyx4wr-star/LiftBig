"""Muscle label helpers for LiftBig exercise assets."""

from __future__ import annotations

MUSCLE_GROUP_LABELS = {
    "chest": "Chest",
    "back": "Back",
    "shoulders": "Shoulders",
    "biceps": "Biceps",
    "triceps": "Triceps",
    "quads": "Quads",
    "hamstrings": "Hamstrings",
    "glutes": "Glutes",
    "calves": "Calves",
    "core": "Core",
    "forearms": "Forearms",
}


def split_primary_secondary(
    primary: list[str] | None,
    secondary: list[str] | None,
) -> tuple[list[str], list[str]]:
    """Return (primaryMuscles, secondaryMuscles) with duplicates removed."""
    prim = [p for p in (primary or []) if p]
    sec = [s for s in (secondary or []) if s and s not in prim]
    return prim, sec
