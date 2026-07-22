"""Procedural LiftBig-style silhouette when no free media is found."""

from __future__ import annotations

from PIL import Image, ImageDraw

BG = (248, 249, 250)
BODY = (160, 165, 172)
PRIMARY = (37, 99, 235)  # #2563EB
SECONDARY = (96, 165, 250)  # #60A5FA


def generate_silhouette(
    exercise_id: str,
    primary_count: int = 1,
    size: int = 360,
) -> Image.Image:
    """
    Draw a simple 3/4 athletic figure with blue muscle accents.
    Pose varies slightly by exercise family for basic recognition.
    """
    img = Image.new("RGB", (size, size), BG)
    d = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2 + 10

    family = _family(exercise_id)

    # Head
    d.ellipse((cx - 28, cy - 130, cx + 28, cy - 74), fill=BODY)

    if family == "press":
        _torso(d, cx, cy, lean=0)
        _arms_press(d, cx, cy)
        _legs_stand(d, cx, cy)
        _paint_chest(d, cx, cy, PRIMARY if primary_count else SECONDARY)
    elif family == "pull":
        _torso(d, cx, cy, lean=8)
        _arms_pull(d, cx, cy)
        _legs_stand(d, cx, cy)
        _paint_back(d, cx, cy, PRIMARY)
    elif family == "squat":
        _torso(d, cx, cy + 20, lean=0)
        _arms_hold(d, cx, cy + 20)
        _legs_squat(d, cx, cy)
        _paint_quads(d, cx, cy, PRIMARY)
    elif family == "hinge":
        _torso(d, cx, cy + 10, lean=35)
        _arms_hang(d, cx, cy + 10)
        _legs_hinge(d, cx, cy)
        _paint_hamstrings(d, cx, cy, PRIMARY)
    elif family == "core":
        _torso(d, cx, cy, lean=0)
        _arms_plankish(d, cx, cy) if "plank" in exercise_id else _arms_hold(d, cx, cy)
        if "plank" in exercise_id:
            _plank_body(d, cx, cy)
        else:
            _legs_stand(d, cx, cy)
            _paint_core(d, cx, cy, PRIMARY)
    else:
        _torso(d, cx, cy, lean=0)
        _arms_hold(d, cx, cy)
        _legs_stand(d, cx, cy)
        _paint_chest(d, cx, cy, SECONDARY)

    return img


def _family(eid: str) -> str:
    if "deadlift" in eid or "romanian" in eid:
        return "hinge"
    if any(k in eid for k in ("plank", "leg-raise", "crunch")):
        return "core"
    if any(k in eid for k in ("squat", "lunge", "leg-press", "extension", "calf")):
        return "squat"
    if any(k in eid for k in ("row", "pulldown", "pull-up", "face-pull", "curl")):
        return "pull"
    if "tricep" in eid or "pushdown" in eid:
        return "press"
    if any(k in eid for k in ("press", "push-up", "fly", "dip", "raise")):
        return "press"
    return "press"


def _torso(d: ImageDraw.ImageDraw, cx: int, cy: int, lean: float) -> None:
    # Simple trapezoid torso
    ox = int(lean * 0.4)
    d.polygon(
        [
            (cx - 40 + ox, cy - 70),
            (cx + 40 + ox, cy - 70),
            (cx + 32 + ox, cy + 30),
            (cx - 32 + ox, cy + 30),
        ],
        fill=BODY,
    )


def _arms_press(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.line([(cx - 40, cy - 40), (cx - 90, cy - 100)], fill=BODY, width=18)
    d.line([(cx + 40, cy - 40), (cx + 90, cy - 100)], fill=BODY, width=18)
    d.ellipse((cx - 100, cy - 110, cx - 80, cy - 90), fill=BODY)
    d.ellipse((cx + 80, cy - 110, cx + 100, cy - 90), fill=BODY)


def _arms_pull(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.line([(cx - 36, cy - 50), (cx - 85, cy - 20)], fill=BODY, width=18)
    d.line([(cx + 36, cy - 50), (cx + 85, cy - 20)], fill=BODY, width=18)


def _arms_hold(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.line([(cx - 38, cy - 50), (cx - 70, cy + 10)], fill=BODY, width=16)
    d.line([(cx + 38, cy - 50), (cx + 70, cy + 10)], fill=BODY, width=16)


def _arms_hang(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.line([(cx - 30, cy - 40), (cx - 20, cy + 40)], fill=BODY, width=16)
    d.line([(cx + 30, cy - 40), (cx + 20, cy + 40)], fill=BODY, width=16)


def _arms_plankish(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    pass


def _legs_stand(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.line([(cx - 18, cy + 30), (cx - 28, cy + 120)], fill=BODY, width=22)
    d.line([(cx + 18, cy + 30), (cx + 28, cy + 120)], fill=BODY, width=22)


def _legs_squat(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.line([(cx - 18, cy + 40), (cx - 55, cy + 90)], fill=BODY, width=24)
    d.line([(cx - 55, cy + 90), (cx - 40, cy + 130)], fill=BODY, width=22)
    d.line([(cx + 18, cy + 40), (cx + 55, cy + 90)], fill=BODY, width=24)
    d.line([(cx + 55, cy + 90), (cx + 40, cy + 130)], fill=BODY, width=22)


def _legs_hinge(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    d.line([(cx - 10, cy + 30), (cx - 25, cy + 120)], fill=BODY, width=22)
    d.line([(cx + 20, cy + 30), (cx + 35, cy + 120)], fill=BODY, width=22)


def _plank_body(d: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    # Horizontal plank silhouette
    d.ellipse((cx - 110, cy - 30, cx - 70, cy + 10), fill=BODY)  # head
    d.rectangle((cx - 70, cy - 18, cx + 80, cy + 18), fill=BODY)
    d.line([(cx - 50, cy + 18), (cx - 70, cy + 70)], fill=BODY, width=14)
    d.line([(cx + 60, cy + 18), (cx + 90, cy + 70)], fill=BODY, width=14)
    d.ellipse((cx - 20, cy - 8, cx + 20, cy + 12), fill=PRIMARY)  # core highlight


def _paint_chest(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.ellipse((cx - 34, cy - 55, cx - 4, cy - 20), fill=color)
    d.ellipse((cx + 4, cy - 55, cx + 34, cy - 20), fill=color)


def _paint_back(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.polygon(
        [(cx - 36, cy - 60), (cx + 36, cy - 60), (cx + 20, cy + 10), (cx - 20, cy + 10)],
        fill=color,
    )


def _paint_quads(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.ellipse((cx - 60, cy + 55, cx - 30, cy + 100), fill=color)
    d.ellipse((cx + 30, cy + 55, cx + 60, cy + 100), fill=color)


def _paint_hamstrings(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.ellipse((cx - 35, cy + 50, cx - 5, cy + 100), fill=color)
    d.ellipse((cx + 10, cy + 50, cx + 40, cy + 100), fill=color)


def _paint_core(d: ImageDraw.ImageDraw, cx: int, cy: int, color: tuple[int, int, int]) -> None:
    d.rectangle((cx - 22, cy - 20, cx + 22, cy + 25), fill=color)
