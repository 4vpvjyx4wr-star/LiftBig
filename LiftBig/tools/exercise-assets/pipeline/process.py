"""LiftBig visual theme processing for exercise stills and GIFs."""

from __future__ import annotations

import io
from typing import Iterable

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageSequence

BG_RGB = (248, 249, 250)  # #F8F9FA
PRIMARY = np.array([37, 99, 235], dtype=np.float32)  # #2563EB
SECONDARY = np.array([96, 165, 250], dtype=np.float32)  # #60A5FA
THUMB_SIZE = 320
CORNER_RADIUS = 28
CONTENT_PAD = 0.09  # ~9% padding
TARGET_FPS = 11
TARGET_DURATION_S = 4.0
MAX_GIF_BYTES = int(1.5 * 1024 * 1024)

_rembg_session = None
_rembg_failed = False


def _get_rembg():
    global _rembg_session, _rembg_failed
    if _rembg_failed:
        return None
    if _rembg_session is not None:
        return _rembg_session
    try:
        from rembg import new_session, remove

        _rembg_session = (remove, new_session("u2net"))
        return _rembg_session
    except Exception:
        _rembg_failed = True
        return None


def load_frames_from_bytes(data: bytes) -> list[Image.Image]:
    """Decode GIF or still image bytes into RGB frames."""
    img = Image.open(io.BytesIO(data))
    frames: list[Image.Image] = []
    if getattr(img, "is_animated", False):
        for frame in ImageSequence.Iterator(img):
            frames.append(frame.convert("RGBA"))
    else:
        frames.append(img.convert("RGBA"))
    return frames


def _threshold_alpha(rgba: Image.Image) -> np.ndarray:
    """Near-white / pale background → alpha 0. Returns uint8 HxW."""
    arr = np.asarray(rgba).astype(np.float32)
    rgb = arr[:, :, :3]
    brightness = rgb.mean(axis=2)
    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    bg_mask = (brightness > 230) & (saturation < 35)
    pale = (brightness > 210) & (saturation < 20)
    bg_mask = bg_mask | pale
    alpha = np.where(bg_mask, 0, arr[:, :, 3]).astype(np.uint8)
    alpha_img = Image.fromarray(alpha, mode="L").filter(ImageFilter.GaussianBlur(1.2))
    return np.asarray(alpha_img)


def remove_background(
    image: Image.Image,
    use_rembg: bool = True,
    *,
    guide_alpha: np.ndarray | None = None,
) -> Image.Image:
    """
    Remove busy backgrounds. Prefer rembg when available;
    otherwise threshold near-white / near-uniform backgrounds.
    When guide_alpha is provided (from the first frame), blend toward it
    so animated edges do not flicker frame-to-frame.
    Returns RGBA.
    """
    rgba = image.convert("RGBA")
    alpha: np.ndarray | None = None

    if use_rembg:
        rem = _get_rembg()
        if rem is not None:
            remove_fn, session = rem
            try:
                out = remove_fn(rgba, session=session).convert("RGBA")
                alpha = np.asarray(out.split()[-1])
                rgba = Image.merge("RGBA", (*out.split()[:3], Image.fromarray(alpha, mode="L")))
            except Exception:
                alpha = None

    if alpha is None:
        alpha = _threshold_alpha(rgba)

    if guide_alpha is not None and guide_alpha.shape == alpha.shape:
        # Soft temporal consistency: keep ~65% of this frame, 35% of guide
        guide = guide_alpha.astype(np.float32)
        cur = alpha.astype(np.float32)
        # Dilate guide slightly so motion isn't clipped
        guide_img = Image.fromarray(guide.astype(np.uint8), mode="L").filter(
            ImageFilter.MaxFilter(3)
        )
        guide_d = np.asarray(guide_img).astype(np.float32)
        blended = 0.65 * cur + 0.35 * guide_d
        # Never invent opacity outside either mask (reduces fringe flicker)
        blended = np.minimum(blended, np.maximum(cur, guide_d))
        alpha = np.clip(blended, 0, 255).astype(np.uint8)

    out = rgba.copy()
    out.putalpha(Image.fromarray(alpha, mode="L"))
    return out


def _rgb_to_hsv_np(rgb: np.ndarray) -> np.ndarray:
    """rgb float 0-255 -> hsv h in [0,360), s,v in [0,1]."""
    rgb_n = rgb / 255.0
    r, g, b = rgb_n[..., 0], rgb_n[..., 1], rgb_n[..., 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    v = maxc
    delta = maxc - minc
    s = np.where(maxc == 0, 0, delta / np.maximum(maxc, 1e-8))
    h = np.zeros_like(maxc)
    mask = delta > 1e-8
    # red max
    idx = mask & (maxc == r)
    h[idx] = (60 * ((g[idx] - b[idx]) / delta[idx]) + 360) % 360
    idx = mask & (maxc == g)
    h[idx] = 60 * ((b[idx] - r[idx]) / delta[idx]) + 120
    idx = mask & (maxc == b)
    h[idx] = 60 * ((r[idx] - g[idx]) / delta[idx]) + 240
    return np.stack([h, s, v], axis=-1)


def apply_liftbig_theme(image: Image.Image) -> Image.Image:
    """
    Convert model to neutral grey, remap red/orange muscle highlights to LiftBig blues,
    composite onto #F8F9FA.
    """
    rgba = image.convert("RGBA")
    arr = np.asarray(rgba).astype(np.float32)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3] / 255.0

    hsv = _rgb_to_hsv_np(rgb)
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]

    # Warm highlight detection (ExerciseDB-style red/orange muscle paint)
    warm = ((h < 40) | (h > 340)) & (s > 0.28) & (v > 0.25)
    # Stronger (more saturated / brighter) → primary blue
    strength = s * v
    primary_mask = warm & (strength >= 0.35)
    secondary_mask = warm & (strength < 0.35) & (strength > 0.12)

    # Greyscale body for non-highlight pixels
    grey = rgb.mean(axis=2, keepdims=True)
    # Slightly cool-neutral grey athletic tone
    body = np.concatenate(
        [grey * 0.96, grey * 0.98, grey * 1.02],
        axis=2,
    )
    body = np.clip(body, 0, 255)

    out = body.copy()
    # Blend highlights toward LiftBig blues while preserving luminance
    for mask, color in ((primary_mask, PRIMARY), (secondary_mask, SECONDARY)):
        if not mask.any():
            continue
        lum = grey[..., 0] / 255.0
        tint = color[None, None, :] * (0.55 + 0.45 * lum[..., None])
        tint = np.clip(tint, 0, 255)
        m = mask[..., None]
        out = np.where(m, tint * 0.85 + body * 0.15, out)

    bg = np.array(BG_RGB, dtype=np.float32)
    a = alpha[..., None]
    comp = out * a + bg * (1.0 - a)
    result = np.clip(comp, 0, 255).astype(np.uint8)
    return Image.fromarray(result, mode="RGB")


def _content_bbox(image: Image.Image, bg_thresh: int = 18) -> tuple[int, int, int, int]:
    arr = np.asarray(image.convert("RGB"))
    diff = np.abs(arr.astype(np.int16) - np.array(BG_RGB, dtype=np.int16)).sum(axis=2)
    mask = diff > bg_thresh
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return 0, 0, image.width, image.height
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def is_nearly_blank(
    image: Image.Image,
    *,
    bg_dist: float = 10.0,
    blank_frac_thresh: float = 0.97,
    min_std: float = 8.0,
) -> bool:
    """
    Detect empty / near-uniform #F8F9FA frames (failed scrapes, empty squares).
    True means the image should be rejected and regenerated.
    """
    arr = np.asarray(image.convert("RGB")).astype(np.float32)
    if arr.size == 0:
        return True
    bg = np.array(BG_RGB, dtype=np.float32)
    dist = np.abs(arr - bg).mean(axis=2)
    blank_frac = float((dist < bg_dist).mean())
    std = float(arr.std())
    if blank_frac >= blank_frac_thresh:
        return True
    if std < min_std and blank_frac >= 0.90:
        return True
    content_px = int((dist >= bg_dist).sum())
    if content_px < 400:
        return True
    return False


def union_content_bbox(frames: list[Image.Image]) -> tuple[int, int, int, int]:
    """Stable crop box: union of content across all frames (same crop every frame)."""
    if not frames:
        raise ValueError("No frames for bbox")
    # Prefer mid-frame seed, then expand to cover motion
    mid = frames[len(frames) // 2]
    x0, y0, x1, y1 = _content_bbox(mid)
    for fr in frames:
        a, b, c, d = _content_bbox(fr)
        x0 = min(x0, a)
        y0 = min(y0, b)
        x1 = max(x1, c)
        y1 = max(y1, d)
    # Clamp to image bounds (assume identical geometry)
    w, h = frames[0].size
    return max(0, x0), max(0, y0), min(w, x1), min(h, y1)


def _square_pad_resize(
    image: Image.Image,
    size: int = THUMB_SIZE,
    bbox: tuple[int, int, int, int] | None = None,
) -> Image.Image:
    """Crop to content (or provided bbox), pad to square with consistent margin, resize."""
    rgb = image.convert("RGB")
    x0, y0, x1, y1 = bbox if bbox is not None else _content_bbox(rgb)
    # Guard empty / inverted
    if x1 <= x0 or y1 <= y0:
        x0, y0, x1, y1 = 0, 0, rgb.width, rgb.height
    cropped = rgb.crop((x0, y0, x1, y1))
    w, h = cropped.size
    side = max(w, h)
    pad = int(side * CONTENT_PAD)
    canvas_side = side + pad * 2
    canvas = Image.new("RGB", (canvas_side, canvas_side), BG_RGB)
    ox = (canvas_side - w) // 2
    oy = (canvas_side - h) // 2
    canvas.paste(cropped, (ox, oy))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def _apply_rounded_corners(image: Image.Image, radius: int = CORNER_RADIUS) -> Image.Image:
    """Rounded corners composited on solid LiftBig background (no transparency)."""
    img = image.convert("RGB")
    size = img.size[0]
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    bg = Image.new("RGB", (size, size), BG_RGB)
    bg.paste(img, (0, 0), mask)
    return bg


def create_thumbnail(
    image: Image.Image,
    bbox: tuple[int, int, int, int] | None = None,
) -> Image.Image:
    """Export 320x320 rounded-corner PNG-ready RGB image."""
    squared = _square_pad_resize(image, THUMB_SIZE, bbox=bbox)
    return _apply_rounded_corners(squared, CORNER_RADIUS)


def _pulse_frames(still: Image.Image, n: int = 24) -> list[Image.Image]:
    """
    Gentle sine pulse so stills can become short looping GIFs.
    Amplitude kept small to avoid jittery spatial jump.
    """
    frames: list[Image.Image] = []
    base = still.convert("RGB")
    if base.size != (THUMB_SIZE, THUMB_SIZE):
        base = _square_pad_resize(base, THUMB_SIZE)
        base = _apply_rounded_corners(base)
    for i in range(n):
        # Full sine cycle for seamless loop (frame 0 ≈ frame n)
        t = i / max(n, 1)
        scale = 1.0 + 0.012 * np.sin(t * 2 * np.pi)
        new_size = max(1, int(round(THUMB_SIZE * scale)))
        scaled = base.resize((new_size, new_size), Image.Resampling.LANCZOS)
        canvas = Image.new("RGB", (THUMB_SIZE, THUMB_SIZE), BG_RGB)
        ox = (THUMB_SIZE - new_size) // 2
        oy = (THUMB_SIZE - new_size) // 2
        canvas.paste(scaled, (ox, oy))
        frames.append(_apply_rounded_corners(canvas))
    return frames


def _even_sample_indices(n: int, target: int) -> list[int]:
    """Strictly increasing even spacing; no duplicate indices when n >= target."""
    if n <= 0:
        return []
    if target >= n:
        return list(range(n))
    if target <= 1:
        return [n // 2]
    return [int(round(i * (n - 1) / (target - 1))) for i in range(target)]


def _temporal_blend(frames: list[Image.Image], amount: float = 0.12) -> list[Image.Image]:
    """Very light blend with neighbors to reduce micro-jitter (avoids heavy ghosting)."""
    if len(frames) < 3 or amount <= 0:
        return frames
    arrs = [np.asarray(f.convert("RGB")).astype(np.float32) for f in frames]
    out: list[Image.Image] = []
    n = len(arrs)
    for i in range(n):
        prev = arrs[(i - 1) % n]
        cur = arrs[i]
        nxt = arrs[(i + 1) % n]
        blended = (1.0 - amount) * cur + (amount * 0.5) * prev + (amount * 0.5) * nxt
        out.append(Image.fromarray(np.clip(blended, 0, 255).astype(np.uint8), mode="RGB"))
    return out


def create_looping_gif(
    frames: Iterable[Image.Image],
    *,
    max_bytes: int = MAX_GIF_BYTES,
    target_duration_s: float = TARGET_DURATION_S,
    target_fps: float = TARGET_FPS,
) -> bytes:
    """
    Build a looping GIF under max_bytes, targeting ~3–5 seconds at ~10–12 fps.
    Uses a stable content bbox across all frames so crop/padding does not jump.
    Frames should already be themed RGB images.
    """
    frame_list = [f.convert("RGB") for f in frames]
    if not frame_list:
        raise ValueError("No frames for GIF")

    # Same geometry assumed; pad mismatches to first frame size before bbox
    w0, h0 = frame_list[0].size
    aligned: list[Image.Image] = []
    for f in frame_list:
        if f.size != (w0, h0):
            canvas = Image.new("RGB", (w0, h0), BG_RGB)
            tw = min(f.width, w0)
            th = min(f.height, h0)
            canvas.paste(f.resize((tw, th), Image.Resampling.LANCZOS), (0, 0))
            aligned.append(canvas)
        else:
            aligned.append(f)

    bbox = union_content_bbox(aligned)

    normalized: list[Image.Image] = []
    for f in aligned:
        squared = _square_pad_resize(f, THUMB_SIZE, bbox=bbox)
        normalized.append(_apply_rounded_corners(squared))

    n = len(normalized)
    if n == 1:
        normalized = _pulse_frames(normalized[0], n=max(24, int(target_duration_s * target_fps)))
        n = len(normalized)
    else:
        # Even subsample to ~10–12 fps over target duration
        target_frames = max(8, min(48, int(round(target_duration_s * target_fps))))
        if n > target_frames:
            idxs = _even_sample_indices(n, target_frames)
            normalized = [normalized[i] for i in idxs]
            n = len(normalized)
        # Subtle temporal blend only for real motion clips
        if n >= 8:
            normalized = _temporal_blend(normalized, amount=0.10)

    duration_ms = int(round((target_duration_s * 1000) / max(n, 1)))
    # ~83–100ms ≈ 10–12 fps sweet spot
    duration_ms = max(80, min(120, duration_ms))

    def encode(frames_in: list[Image.Image], colors: int, scale: float) -> bytes:
        out = io.BytesIO()
        sized: list[Image.Image] = []
        for fr in frames_in:
            im = fr
            if scale < 1.0:
                side = max(160, int(THUMB_SIZE * scale))
                im = fr.resize((side, side), Image.Resampling.LANCZOS)
                im = im.resize((THUMB_SIZE, THUMB_SIZE), Image.Resampling.LANCZOS)
            sized.append(im)

        # Shared palette across frames — major anti-flicker for GIF quantization
        base_q = sized[0].quantize(
            colors=colors,
            method=Image.Quantize.MEDIANCUT,
            dither=Image.Dither.NONE,
        )
        processed = [base_q]
        for fr in sized[1:]:
            q = fr.quantize(palette=base_q, dither=Image.Dither.NONE)
            processed.append(q)

        processed[0].save(
            out,
            format="GIF",
            save_all=True,
            append_images=processed[1:],
            duration=duration_ms,
            loop=0,
            optimize=True,
            disposal=2,
        )
        return out.getvalue()

    # Progressive compression until under budget
    for colors, scale in (
        (128, 1.0),
        (96, 1.0),
        (64, 1.0),
        (64, 0.85),
        (48, 0.75),
        (32, 0.65),
    ):
        data = encode(normalized, colors, scale)
        if len(data) <= max_bytes:
            return data

    # Last resort: fewer frames (even sample, not [::2] which can feel uneven)
    slim_n = max(6, n // 2)
    slim_idxs = _even_sample_indices(n, slim_n)
    slim = [normalized[i] for i in slim_idxs]
    return encode(slim, 32, 0.6)


def process_frame(image: Image.Image, use_rembg: bool = True) -> Image.Image:
    """Full per-frame pipeline: bg remove → theme."""
    cleaned = remove_background(image, use_rembg=use_rembg)
    return apply_liftbig_theme(cleaned)


def process_frames(
    frames: list[Image.Image],
    use_rembg: bool = True,
) -> list[Image.Image]:
    """
    Process an animation with stable background removal.
    First frame establishes a guide alpha; later frames blend toward it.
    rembg (if enabled) runs on the first frame only for speed + consistency.
    """
    if not frames:
        return []

    themed: list[Image.Image] = []
    guide_alpha: np.ndarray | None = None

    for i, fr in enumerate(frames):
        do_rembg = use_rembg and i == 0
        try:
            cleaned = remove_background(
                fr,
                use_rembg=do_rembg,
                guide_alpha=guide_alpha,
            )
        except Exception:
            cleaned = remove_background(fr, use_rembg=False, guide_alpha=guide_alpha)

        if guide_alpha is None:
            guide_alpha = np.asarray(cleaned.split()[-1])

        themed.append(apply_liftbig_theme(cleaned))

    return themed
