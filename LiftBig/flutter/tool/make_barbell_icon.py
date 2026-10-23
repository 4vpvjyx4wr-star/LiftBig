#!/usr/bin/env python3
"""Barbell mark: horizontal bar and round plates on navy. Not an H."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

NAVY = (10, 15, 30, 255)
ORANGE = (244, 80, 30, 255)
RING = (255, 158, 90, 255)
HOLE = (10, 15, 30, 255)

ROOT = Path("/Users/jtiralongo/Documents/GitHub/LiftBig/LiftBig/flutter")


def draw_barbell(size: int, inset: float = 0.08) -> Image.Image:
    image = Image.new("RGBA", (size, size), NAVY)
    draw = ImageDraw.Draw(image)
    margin = size * inset
    box = [margin, margin, size - margin, size - margin]
    draw.ellipse(box, fill=ORANGE)
    ring = size * 0.045
    draw.ellipse(
        [box[0] + ring, box[1] + ring, box[2] - ring, box[3] - ring],
        outline=NAVY,
        width=max(1, int(size * 0.035)),
    )
    font_size = max(8, int(size * 0.34))
    font = None
    for path in (
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf",
    ):
        try:
            font = ImageFont.truetype(path, font_size)
            break
        except OSError:
            continue
    if font is None:
        font = ImageFont.load_default()
    text = "LB"
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    x = (size - (right - left)) / 2 - left
    y = (size - (bottom - top)) / 2 - top
    draw.text((x, y), text, font=font, fill=NAVY)
    return image


def write(path: Path, size: int, inset: float = 0.08) -> None:
    image = draw_barbell(max(size, 64), inset)
    if image.size[0] != size:
        image = image.resize((size, size), Image.Resampling.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG")


def main() -> None:
    phone = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    phone_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in phone_sizes.items():
        write(phone / name, size)

    watch = ROOT / "ios/LiftBigWatch/Assets.xcassets/AppIcon.appiconset"
    watch_sizes = {
        "Icon-24@2x.png": 48,
        "Icon-27.5@2x.png": 55,
        "Icon-29@2x.png": 58,
        "Icon-29@3x.png": 87,
        "Icon-40@2x.png": 80,
        "Icon-44@2x.png": 88,
        "Icon-46@2x.png": 92,
        "Icon-50@2x.png": 100,
        "Icon-51@2x.png": 102,
        "Icon-54@2x.png": 108,
        "Icon-86@2x.png": 172,
        "Icon-98@2x.png": 196,
        "Icon-108@2x.png": 216,
        "Icon-117@2x.png": 234,
        "Icon-129@2x.png": 258,
        "Icon-1024.png": 1024,
    }
    for name, size in watch_sizes.items():
        write(watch / name, size)

    web = ROOT / "web/icons"
    write(web / "Icon-192.png", 192)
    write(web / "Icon-512.png", 512)
    write(web / "Icon-maskable-192.png", 192, inset=0.18)
    write(web / "Icon-maskable-512.png", 512, inset=0.18)
    print("icons written")


if __name__ == "__main__":
    main()
