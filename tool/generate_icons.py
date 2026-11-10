#!/usr/bin/env python3
"""Sinh bộ icon cho app "Cân cà phê".

Hình: nền xanh navy chuyển sắc + hạt cà phê trắng ở giữa.
Chạy lại bất cứ lúc nào:  python tool/generate_icons.py

Ghi ra:
  - android/app/src/main/res/mipmap-*/ic_launcher.png        (icon cũ, Android < 8)
  - android/app/src/main/res/drawable-*/ic_launcher_foreground.png (adaptive icon)
  - web/icons/*.png, web/favicon.png
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
WEB = ROOT / "web"

NAVY = (11, 79, 138)      # kNavY trong utils.dart
BLUE = (33, 150, 243)     # kBlue
WHITE = (255, 255, 255)

SS = 4  # vẽ lớn gấp 4 lần rồi thu nhỏ để viền mượt


def gradient(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), NAVY)
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        c = tuple(round(BLUE[i] + (NAVY[i] - BLUE[i]) * t) for i in range(3))
        d.line([(0, y), (size, y)], fill=c)
    return img.convert("RGBA")


def bean(size: int, long_ratio: float) -> Image.Image:
    """Hạt cà phê trắng, đường rãnh chạy dọc thân, xoay 45 độ."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    length = size * long_ratio
    height = length * 0.66
    cx = cy = size / 2

    d.ellipse(
        [cx - length / 2, cy - height / 2, cx + length / 2, cy + height / 2],
        fill=WHITE + (255,),
    )

    # rãnh giữa hạt: đường hơi uốn, hai đầu nằm trong thân hạt
    amp = height * 0.07
    pts = []
    for i in range(101):
        t = i / 100
        x = cx - length * 0.38 + length * 0.76 * t
        y = cy + amp * math.sin(2 * math.pi * t)
        pts.append((x, y))
    d.line(
        pts,
        fill=NAVY + (255,),
        width=max(2, int(size * 0.022)),
        joint="curve",
    )

    return layer.rotate(45, resample=Image.BICUBIC, expand=False)


def legacy_icon(size: int) -> Image.Image:
    s = size * SS
    base = gradient(s)
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, s - 1, s - 1], radius=int(s * 0.19), fill=255
    )
    base.putalpha(mask)
    out = Image.alpha_composite(base, bean(s, 0.56))
    return out.resize((size, size), Image.LANCZOS)


def adaptive_foreground(size: int) -> Image.Image:
    s = size * SS
    out = Image.alpha_composite(
        Image.new("RGBA", (s, s), (0, 0, 0, 0)), bean(s, 0.46)
    )
    return out.resize((size, size), Image.LANCZOS)


def maskable_icon(size: int, bg=NAVY) -> Image.Image:
    s = size * SS
    out = Image.alpha_composite(
        Image.new("RGBA", (s, s), bg + (255,)), bean(s, 0.44)
    )
    return out.resize((size, size), Image.LANCZOS)


def main() -> None:
    written = []

    # Icon cũ + adaptive icon, theo đúng KÍCH THƯỚC từng mật độ
    for dpi, legacy_px, fg_px in (
        ("mdpi", 48, 108),
        ("hdpi", 72, 162),
        ("xhdpi", 96, 216),
        ("xxhdpi", 144, 324),
        ("xxxhdpi", 192, 432),
    ):
        mip = RES / f"mipmap-{dpi}"
        mip.mkdir(parents=True, exist_ok=True)
        p = mip / "ic_launcher.png"
        legacy_icon(legacy_px).save(p)
        written.append(p)

        drawable = RES / f"drawable-{dpi}"
        drawable.mkdir(parents=True, exist_ok=True)
        p = drawable / "ic_launcher_foreground.png"
        adaptive_foreground(fg_px).save(p)
        written.append(p)

    # Lớp nền của adaptive icon (Android 8+)
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )
    written.append(anydpi / "ic_launcher.xml")

    values = RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "colors.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#0B4F8A</color>\n'
        "</resources>\n",
        encoding="utf-8",
    )
    written.append(values / "colors.xml")

    # Icon cho bản web
    WEB.mkdir(parents=True, exist_ok=True)
    for name, size, fn in (
        ("Icon-192.png", 192, legacy_icon),
        ("Icon-512.png", 512, legacy_icon),
        ("Icon-maskable-192.png", 192, maskable_icon),
        ("Icon-maskable-512.png", 512, maskable_icon),
    ):
        p = WEB / "icons" / name
        p.parent.mkdir(parents=True, exist_ok=True)
        fn(size).save(p)
        written.append(p)

    for name, size in (("favicon.png", 32),):
        p = WEB / name
        legacy_icon(size).save(p)
        written.append(p)

    for p in written:
        print(f"wrote {p.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
