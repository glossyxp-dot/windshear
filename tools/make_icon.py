#!/usr/bin/env python3
"""
WindShear icon generator.

Builds the scalable vector master at assets/icon.svg:
  * dark "leaf" plate with two heavy rounded corners
  * four checkerboard feather clusters (top / bottom / left / right)
  * steel lens ring + blue glass with a top highlight
  * three airflow arrows (one straight, two curving outward)

The SVG uses gradients and paths only. Godot 4 imports it cleanly through
ThorVG, and ImageMagick or rsvg can rasterise it to PNG.

Run:  python3 tools/make_icon.py
"""

from __future__ import annotations

import pathlib
import subprocess
import sys

W = H = 512
CX, CY = 240.0, 205.0          # lens centre
LENS_R = 116.0                 # blue glass radius
RING_R = 128.0                 # steel ring radius

DARK = "#141414"
LIGHT = "#e9e9e9"
ARROW = "#39414a"
PLATE_TOP = "#4a4a4a"
PLATE_BOT = "#272727"
EDGE = "#cfcfcf"

out: list[str] = []


def add(s: str) -> None:
    """Appends one line of SVG."""
    out.append(s)


def fmt(v: float) -> str:
    """Formats a number for SVG output."""
    return f"{v:.2f}".rstrip("0").rstrip(".")


def tri_cluster(apex, b1, b2, rows=8, cx=0.0, cy=0.0):
    """Builds a checkerboard triangle pointing from apex toward the base."""
    ax, ay = apex
    bx, by = b1
    tx, ty = b2

    def lattice(r):
        if r == 0:
            return [(ax, ay)]
        pts = []
        for k in range(r + 1):
            f = k / r
            px = ax + r / rows * ((1 - f) * (bx - ax) + f * (tx - ax))
            py = ay + r / rows * ((1 - f) * (by - ay) + f * (ty - ay))
            pts.append((px, py))
        return pts

    rows_pts = [lattice(r) for r in range(rows + 1)]
    shapes = []
    for r in range(1, rows + 1):
        for k in range(r):
            p1 = rows_pts[r - 1][k]
            p2 = rows_pts[r][k]
            p3 = rows_pts[r][k + 1]
            shapes.append((p1, p2, p3, DARK if (r + k) % 2 == 0 else LIGHT))
        for k in range(r - 1):
            p1 = rows_pts[r - 1][k]
            p2 = rows_pts[r - 1][k + 1]
            p3 = rows_pts[r][k + 1]
            shapes.append((p1, p2, p3, LIGHT if (r + k) % 2 == 0 else DARK))
    return shapes


def poly(points, fill, opacity=None, stroke=None, stroke_w=0.0):
    """Builds a polygon, with an optional stroke."""
    pts = " ".join(f"{fmt(x)},{fmt(y)}" for x, y in points)
    s = f'<polygon points="{pts}" fill="{fill}"'
    if opacity is not None:
        s += f' opacity="{opacity}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{fmt(stroke_w)}" stroke-linejoin="round"'
    return s + "/>"


def build() -> str:
    """Returns the complete SVG document."""
    add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
    add("  <defs>")
    add('    <linearGradient id="plate" x1="0" y1="0" x2="0.35" y2="1">')
    add(f'      <stop offset="0" stop-color="{PLATE_TOP}"/>')
    add(f'      <stop offset="0.55" stop-color="#353535"/>')
    add(f'      <stop offset="1" stop-color="{PLATE_BOT}"/>')
    add("    </linearGradient>")
    add('    <radialGradient id="ring" cx="0.38" cy="0.28" r="0.85">')
    add('      <stop offset="0" stop-color="#787d83"/>')
    add('      <stop offset="0.55" stop-color="#4d5157"/>')
    add('      <stop offset="1" stop-color="#2f3236"/>')
    add("    </radialGradient>")
    add('    <radialGradient id="glass" cx="0.36" cy="0.24" r="0.92">')
    add('      <stop offset="0" stop-color="#8fb7ef"/>')
    add('      <stop offset="0.42" stop-color="#4a86e8"/>')
    add('      <stop offset="1" stop-color="#2a5fc2"/>')
    add("    </radialGradient>")
    add('    <radialGradient id="shine" cx="0.5" cy="0.5" r="0.5">')
    add('      <stop offset="0" stop-color="#ffffff" stop-opacity="0.72"/>')
    add('      <stop offset="0.7" stop-color="#dbe9ff" stop-opacity="0.25"/>')
    add('      <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>')
    add("    </radialGradient>")
    add("  </defs>")

    # The plate has two heavy rounded corners.
    plate = ("M 442 16 L 442 262 A 152 152 0 0 1 290 414 L 76 414 L 76 168 "
             "A 152 152 0 0 1 228 16 Z")
    add(f'  <path d="{plate}" fill="url(#plate)"/>')
    add(f'  <path d="{plate}" fill="none" stroke="{EDGE}" stroke-width="2.5" '
        f'stroke-opacity="0.55" stroke-linejoin="round"/>')

    # Four checkerboard feather clusters point away from the centre.
    clusters = [
        ((240, 20), (196, 98), (284, 98)),    # top    (points up)
        ((240, 398), (196, 320), (284, 320)),  # bottom (points down)
        ((84, 210), (160, 172), (160, 248)),   # left   (points left)
        ((396, 210), (320, 172), (320, 248)),  # right  (points right)
    ]
    add('  <g>')
    for apex, b1, b2 in clusters:
        for p1, p2, p3, fill in tri_cluster(apex, b1, b2):
            add("    " + poly([p1, p2, p3], fill))
    add("  </g>")

    # Steel lens ring, blue glass and a small highlight.
    add(f'  <circle cx="{fmt(CX)}" cy="{fmt(CY)}" r="{fmt(RING_R)}" fill="url(#ring)"/>')
    add(f'  <circle cx="{fmt(CX)}" cy="{fmt(CY)}" r="{fmt(LENS_R)}" fill="url(#glass)"/>')
    add(f'  <ellipse cx="240" cy="136" rx="76" ry="46" fill="url(#shine)"/>')

    # Three airflow arrows: one straight, two curving out.
    add(f'  <g fill="none" stroke="{ARROW}" stroke-width="7" stroke-linecap="round">')
    add('    <path d="M 240 118 L 240 278"/>')
    add('    <path d="M 206 126 C 214 176, 206 224, 184 262"/>')
    add('    <path d="M 274 126 C 266 176, 274 224, 296 262"/>')
    add("  </g>")
    add("  <g fill=\"" + ARROW + "\">")
    add("    " + poly([(240, 296), (227, 274), (253, 274)], ARROW))
    add("    " + poly([(179, 281), (170, 258), (196, 265)], ARROW))
    add("    " + poly([(301, 281), (310, 258), (284, 265)], ARROW))
    add("  </g>")

    add("</svg>")
    return "\n".join(out) + "\n"


def main() -> int:
    """Writes the SVG and asks rsvg-convert for the PNG."""
    root = pathlib.Path(__file__).resolve().parent.parent
    assets = root / "assets"
    assets.mkdir(parents=True, exist_ok=True)

    svg = build()
    svg_path = assets / "icon.svg"
    svg_path.write_text(svg, encoding="utf-8")
    print(f"wrote {svg_path}")

    png_path = assets / "icon.png"
    try:
        subprocess.run(
            ["rsvg-convert", "-w", str(W), "-h", str(H), str(svg_path), "-o", str(png_path)],
            check=True,
        )
        print(f"wrote {png_path}")
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print(f"rasterise skipped: {exc}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
