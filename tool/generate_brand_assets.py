from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BRANDING_DIR = ROOT / "assets" / "branding"
WEB_DIR = ROOT / "web"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"

SIZE = 1024
CORAL = (232, 93, 63, 255)
TEAL = (24, 107, 91, 255)
MINT = (143, 240, 218, 255)
IVORY = (255, 247, 238, 255)
INK = (24, 19, 15, 255)
SLATE = (31, 36, 46, 255)


def ensure_dirs() -> None:
    BRANDING_DIR.mkdir(parents=True, exist_ok=True)


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    gradient = Image.new("RGBA", (size, size))
    pixels = gradient.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        for x in range(size):
            pixels[x, y] = (r, g, b, 255)
    return gradient


def radial_blob(size: int, center: tuple[float, float], radius: float, color: tuple[int, int, int], alpha: int) -> Image.Image:
    blob = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = blob.load()
    cx, cy = center
    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            distance = (dx * dx + dy * dy) ** 0.5
            if distance > radius:
                continue
            strength = 1 - (distance / radius)
            pixels[x, y] = (
                color[0],
                color[1],
                color[2],
                int(alpha * (strength ** 1.8)),
            )
    return blob.filter(ImageFilter.GaussianBlur(radius=38))


def rounded_panel(size: int) -> Image.Image:
    panel = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (size, size), 0)
    inset = 70
    radius = 220
    ImageDraw.Draw(mask).rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=255,
    )

    base = vertical_gradient(size, (24, 19, 15), (18, 22, 30))
    base = ImageChops.screen(base, radial_blob(size, (240, 260), 360, (232, 93, 63), 175))
    base = ImageChops.screen(base, radial_blob(size, (780, 770), 390, (61, 191, 168), 140))
    panel.paste(base, (0, 0), mask)

    border = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        outline=(255, 255, 255, 34),
        width=6,
    )
    panel.alpha_composite(border)
    return panel


def line_gradient(size: int, start: tuple[int, int], end: tuple[int, int], color_a: tuple[int, int, int], color_b: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pixels = image.load()
    x1, y1 = start
    x2, y2 = end
    vx = x2 - x1
    vy = y2 - y1
    denom = (vx * vx + vy * vy) or 1
    for y in range(size):
        for x in range(size):
            t = ((x - x1) * vx + (y - y1) * vy) / denom
            t = max(0.0, min(1.0, t))
            r = int(color_a[0] * (1 - t) + color_b[0] * t)
            g = int(color_a[1] * (1 - t) + color_b[1] * t)
            b = int(color_a[2] * (1 - t) + color_b[2] * t)
            pixels[x, y] = (r, g, b, 255)
    return image


def draw_radar(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    center = (592, 564)
    rings = [
        (318, 10, (143, 240, 218, 44)),
        (244, 12, (143, 240, 218, 70)),
        (170, 14, (143, 240, 218, 112)),
    ]
    for radius, width, color in rings:
        draw.ellipse(
            (
                center[0] - radius,
                center[1] - radius,
                center[0] + radius,
                center[1] + radius,
            ),
            outline=color,
            width=width,
        )

    for radius, start, end, width in [
        (342, 205, 348, 14),
        (282, 216, 354, 16),
        (212, 224, 8, 18),
    ]:
        draw.arc(
            (
                center[0] - radius,
                center[1] - radius,
                center[0] + radius,
                center[1] + radius,
            ),
            start=start,
            end=end,
            fill=(232, 93, 63, 188),
            width=width,
        )

    dot = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    dot_draw = ImageDraw.Draw(dot)
    dot_draw.ellipse((566, 538, 618, 590), fill=IVORY)
    dot_draw.ellipse((579, 551, 605, 577), fill=CORAL)
    canvas.alpha_composite(dot.filter(ImageFilter.GaussianBlur(radius=2)))


def n_mask(size: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    points = [
        (304, 804),
        (422, 804),
        (592, 535),
        (616, 535),
        (616, 804),
        (742, 804),
        (742, 220),
        (622, 220),
        (450, 492),
        (428, 492),
        (428, 220),
        (304, 220),
    ]
    draw.polygon(points, fill=255)
    return mask.filter(ImageFilter.GaussianBlur(radius=0.4))


def glyph_layer(size: int) -> Image.Image:
    mask = n_mask(size)
    gradient = line_gradient(
        size,
        (286, 220),
        (742, 790),
        (255, 247, 238),
        (232, 93, 63),
    )
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_mask = ImageChops.offset(mask, 18, 20).filter(ImageFilter.GaussianBlur(radius=18))
    shadow_color = Image.new("RGBA", (size, size), (7, 10, 16, 138))
    shadow.paste(shadow_color, (0, 0), shadow_mask)
    layer.alpha_composite(shadow)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_mask = mask.filter(ImageFilter.GaussianBlur(radius=26))
    glow_color = Image.new("RGBA", (size, size), (232, 93, 63, 170))
    glow.paste(glow_color, (0, 0), glow_mask)
    layer.alpha_composite(glow)

    fill = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fill.paste(gradient, (0, 0), mask)
    layer.alpha_composite(fill)

    outline = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(outline).line(
        [(316, 244), (430, 244), (604, 522), (604, 244), (730, 244)],
        fill=(255, 255, 255, 92),
        width=12,
        joint="curve",
    )
    layer.alpha_composite(outline.filter(ImageFilter.GaussianBlur(radius=5)))
    return layer


def spark_layer(size: int) -> Image.Image:
    sparkle = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sparkle)
    center = (730, 262)
    arms = [
        [(center[0], center[1] - 72), (center[0] + 18, center[1]), (center[0], center[1] + 72), (center[0] - 18, center[1])],
        [(center[0] - 54, center[1]), (center[0], center[1] + 14), (center[0] + 54, center[1]), (center[0], center[1] - 14)],
    ]
    draw.polygon(arms[0], fill=(232, 93, 63, 230))
    draw.polygon(arms[1], fill=(255, 244, 233, 220))
    return sparkle.filter(ImageFilter.GaussianBlur(radius=0.5))


def make_mark() -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), INK)
    canvas = ImageChops.screen(canvas, radial_blob(SIZE, (270, 240), 320, (232, 93, 63), 95))
    canvas = ImageChops.screen(canvas, radial_blob(SIZE, (790, 806), 350, (61, 191, 168), 78))
    canvas.alpha_composite(rounded_panel(SIZE))
    draw_radar(canvas)
    canvas.alpha_composite(glyph_layer(SIZE))
    canvas.alpha_composite(spark_layer(SIZE))

    frame = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        (72, 72, SIZE - 72, SIZE - 72),
        radius=220,
        outline=(255, 255, 255, 26),
        width=4,
    )
    canvas.alpha_composite(frame)
    return canvas


def save_resized(image: Image.Image, path: Path, size: int) -> None:
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(path)


def main() -> None:
    ensure_dirs()
    mark = make_mark()

    master = BRANDING_DIR / "nightradar_mark.png"
    mark.save(master)

    save_resized(mark, WEB_DIR / "favicon.png", 64)
    save_resized(mark, WEB_DIR / "icons" / "Icon-192.png", 192)
    save_resized(mark, WEB_DIR / "icons" / "Icon-512.png", 512)
    save_resized(mark, WEB_DIR / "icons" / "Icon-maskable-192.png", 192)
    save_resized(mark, WEB_DIR / "icons" / "Icon-maskable-512.png", 512)

    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android_sizes.items():
        save_resized(mark, ANDROID_RES / folder / "ic_launcher.png", size)


if __name__ == "__main__":
    main()
