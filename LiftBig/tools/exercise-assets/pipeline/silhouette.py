"""Procedural LiftBig-style silhouette when no free media is found."""

from __future__ import annotations

from PIL import Image, ImageDraw

BG = (248, 249, 250)
BODY = (158, 163, 170)
SHADE = (130, 136, 145)
PRIMARY = (37, 99, 235)  # #2563EB
SECONDARY = (96, 165, 250)  # #60A5FA


def generate_silhouette(
    exercise_id: str,
    primary_count: int = 1,
    size: int = 360,
) -> Image.Image:
    """
    Draw a clear 3/4 athletic figure with blue muscle accents.
    Never emit empty/near-blank frames or abstract square clusters.
    """
    img = Image.new("RGB", (size, size), BG)
    d = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2 + 8
    family = _family(exercise_id)

    if family == "plank":
        _draw_plank(d, cx, cy)
        return img
    if family == "floor":
        _draw_floor_core(d, cx, cy)
        return img
    if family == "stretch":
        _draw_stretch(d, cx, cy)
        return img

    # Standing / hinged figure — filled limbs (not thin line stubs)
    _head(d, cx - 6, cy - 118)
    if family == "press":
        _torso(d, cx, cy, lean=6)
        _arm(d, cx - 38, cy - 48, cx - 95, cy - 105, thick=20)
        _arm(d, cx + 42, cy - 48, cx + 98, cy - 100, thick=20)
        _leg(d, cx - 16, cy + 28, cx - 30, cy + 125, thick=24)
        _leg(d, cx + 22, cy + 28, cx + 38, cy + 125, thick=24)
        _paint_chest(d, cx, cy, PRIMARY if primary_count else SECONDARY)
    elif family == "pull":
        _torso(d, cx, cy, lean=12)
        _arm(d, cx - 34, cy - 50, cx - 92, cy - 10, thick=20)
        _arm(d, cx + 40, cy - 50, cx + 95, cy - 8, thick=20)
        _leg(d, cx - 14, cy + 28, cx - 26, cy + 125, thick=24)
        _leg(d, cx + 24, cy + 28, cx + 36, cy + 125, thick=24)
        _paint_back(d, cx, cy, PRIMARY)
    elif family == "squat":
        _torso(d, cx, cy + 18, lean=4)
        _arm(d, cx - 36, cy - 30, cx - 70, cy + 20, thick=18)
        _arm(d, cx + 40, cy - 30, cx + 72, cy + 20, thick=18)
        _leg(d, cx - 14, cy + 48, cx - 58, cy + 95, thick=26)
        _leg(d, cx - 58, cy + 95, cx - 42, cy + 135, thick=24)
        _leg(d, cx + 22, cy + 48, cx + 62, cy + 95, thick=26)
        _leg(d, cx + 62, cy + 95, cx + 46, cy + 135, thick=24)
        _paint_quads(d, cx, cy, PRIMARY)
    elif family == "hinge":
        _torso(d, cx + 8, cy + 8, lean=38)
        _arm(d, cx - 10, cy - 20, cx - 18, cy + 55, thick=18)
        _arm(d, cx + 40, cy - 15, cx + 30, cy + 55, thick=18)
        _leg(d, cx - 2, cy + 40, cx - 22, cy + 130, thick=24)
        _leg(d, cx + 28, cy + 40, cx + 42, cy + 130, thick=24)
        _paint_hamstrings(d, cx, cy, PRIMARY)
    else:
        _torso(d, cx, cy, lean=6)
        _arm(d, cx - 36, cy - 48, cx - 72, cy + 8, thick=18)
        _arm(d, cx + 40, cy - 48, cx + 74, cy + 8, thick=18)
        _leg(d, cx - 16, cy + 28, cx - 28, cy + 125, thick=24)
        _leg(d, cx + 22, cy + 28, cx + 36, cy + 125, thick=24)
        _paint_chest(d, cx, cy, SECONDARY)

    return img


def _family(eid: str) -> str:
    if any(k in eid for k in ("plank", "shoulder-tap")):
        return "plank"
    if any(
        k in eid
        for k in (
            "hollow",
            "crunch",
            "dead-bug",
            "deadbug",
            "leg-raise",
            "dragon",
            "twist",
            "rollout",
        )
    ):
        return "floor"
    if any(
        k in eid
        for k in (
            "stretch",
            "pose",
            "pigeon",
            "foam",
            "lunge-hip",
            "cat-cow",
            "cobra",
            "90-90",
            "hamstring-stretch",
        )
    ):
        return "stretch"
    if "deadlift" in eid or "romanian" in eid or "good-morning" in eid or "rdl" in eid:
        return "hinge"
    if any(k in eid for k in ("squat", "lunge", "leg-press", "extension", "calf", "split")):
        return "squat"
    if any(
        k in eid
        for k in ("row", "pulldown", "pull-up", "face-pull", "curl", "shrug", "lat")
    ):
        return "pull"
    if "tricep" in eid or "pushdown" in eid:
        return "press"
    if any(k in eid for k in ("press", "push-up", "fly", "dip", "raise", "thrust", "bridge")):
        return "press"
    return "press"


def _head(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), fill=BODY, outline=SHADE, width=1)


def _torso(d: ImageDraw.ImageDraw, cx: int, cy: int, lean: float) -> None:
    ox = int(lean * 0.45)
    d.polygon(
        [
            (cx - 42 + ox, cy - 72),
            (cx + 38 + ox, cy - 70),
            (cx + 34 + ox, cy + 32),
            (cx - 34 + ox, cy + 34),
        ],
        fill=BODY,
        outline=SHADE,
    )


def _arm(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, thick: int = 18) -> None:
    d.line([(x0, y0), (x1, y1)], fill=BODY, width=thick)
    r = max(8, thick // 2)
    d.ellipse((x1 - r, y1 - r, x1 + r, y1 + r), fill=BODY)


def _leg(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, thick: int = 22) -> None:
    d.line([(x0, y0), (x1, y1)], fill=BODY, width=thick)
    r = max(9, thick // 2)
    d.ellipse((x1 - r - 2, y1 - 4, x1 + r + 6, y1 + 10), fill=BODY)


def _draw_plank(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    # Clear horizontal athlete — filled body, not rectangles alone
    d.ellipse((cx - 118, cy - 28, cx - 72, cy + 16), fill=BODY)  # head
    d.polygon(
        [
            (cx - 70, cy - 16),
            (cx + 90, cy - 14),
            (cx + 95, cy + 16),
            (cx - 65, cy + 18),
        ],
        fill=BODY,
    )
    _arm(d, cx - 40, cy - 8, cx - 70, cy + 55, thick=16)
    _arm(d, cx - 20, cy + 10, cx - 5, cy + 8, thick=14)
    _leg(d, cx + 70, cy + 12, cx + 110, cy + 55, thick=18)
    _leg(d, cx + 55, cy + 12, cx + 95, cy + 58, thick=18)
    d.ellipse((cx - 10, cy - 6, cx + 28, cy + 14), fill=PRIMARY)


def _draw_floor_core(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    # Hollow / crunch style — figure on back with tucked torso highlight
    d.ellipse((cx - 90, cy - 40, cx - 40, cy + 8), fill=BODY)
    d.polygon(
        [
            (cx - 40, cy - 20),
            (cx + 70, cy - 8),
            (cx + 60, cy + 28),
            (cx - 35, cy + 22),
        ],
        fill=BODY,
    )
    _leg(d, cx + 50, cy + 10, cx + 30, cy - 50, thick=18)
    _leg(d, cx + 65, cy + 12, cx + 50, cy - 45, thick=18)
    _arm(d, cx - 20, cy - 5, cx - 55, cy + 40, thick=14)
    d.ellipse((cx - 5, cy - 8, cx + 35, cy + 18), fill=PRIMARY)


def _draw_stretch(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    # Kneeling / lunging stretch silhouette
    _head(d, cx - 40, cy - 90)
    _torso(d, cx - 20, cy - 20, lean=-10)
    _arm(d, cx - 50, cy - 50, cx - 90, cy - 100, thick=16)
    _arm(d, cx + 5, cy - 45, cx + 40, cy - 20, thick=16)
    _leg(d, cx - 10, cy + 30, cx - 70, cy + 110, thick=22)
    _leg(d, cx + 10, cy + 30, cx + 80, cy + 50, thick=22)
    _leg(d, cx + 80, cy + 50, cx + 100, cy + 110, thick=20)
    d.ellipse((cx - 30, cy - 10, cx + 10, cy + 25), fill=SECONDARY)


def _paint_chest(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.ellipse((cx - 34, cy - 55, cx - 2, cy - 18), fill=color)
    d.ellipse((cx + 4, cy - 55, cx + 34, cy - 18), fill=color)


def _paint_back(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.polygon(
        [(cx - 34, cy - 58), (cx + 34, cy - 56), (cx + 18, cy + 12), (cx - 18, cy + 14)],
        fill=color,
    )


def _paint_quads(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.ellipse((cx - 62, cy + 55, cx - 28, cy + 105), fill=color)
    d.ellipse((cx + 30, cy + 55, cx + 64, cy + 105), fill=color)


def _paint_hamstrings(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.ellipse((cx - 30, cy + 48, cx + 0, cy + 105), fill=color)
    d.ellipse((cx + 16, cy + 48, cx + 48, cy + 105), fill=color)
