"""Generate Couchside-owned geometric TGA symbols, without third-party assets."""
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1] / "Couchside_Gathering" / "Media"
SIZE, SCALE = 64, 2
SYMBOLS = {
    "diamond-purple": ("diamond", "c684ff"),
    "square-blue": ("square", "64b6ff"),
    "triangle-green": ("triangle", "86e66e"),
    "circle-orange": ("circle", "ffb45c"),
    "star-yellow": ("star", "ffe165"),
    "cross-red": ("cross", "ff7777"),
    "hexagon-teal": ("hexagon", "64ded5"),
}


def polygon(shape):
    if shape == "diamond":
        return [(0, -1), (1, 0), (0, 1), (-1, 0)]
    if shape == "square":
        return [(-.8, -.8), (.8, -.8), (.8, .8), (-.8, .8)]
    if shape == "triangle":
        return [(0, -1), (1, .85), (-1, .85)]
    if shape == "hexagon":
        return [(math.cos(i * math.pi / 3), math.sin(i * math.pi / 3)) for i in range(6)]
    if shape == "star":
        return [(math.sin(i * math.pi / 5) * (1 if i % 2 == 0 else .45),
                 -math.cos(i * math.pi / 5) * (1 if i % 2 == 0 else .45)) for i in range(10)]
    return [(-.3, -1), (.3, -1), (.3, -.3), (1, -.3), (1, .3), (.3, .3),
            (.3, 1), (-.3, 1), (-.3, .3), (-1, .3), (-1, -.3), (-.3, -.3)]


def inside(shape, x, y, radius):
    x, y = x / radius, y / radius
    if shape == "circle":
        return x * x + y * y <= 1
    points = polygon(shape)
    hit = False
    a = points[-1]
    for b in points:
        if (a[1] > y) != (b[1] > y) and x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]:
            hit = not hit
        a = b
    return hit


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    for name, (shape, hex_color) in SYMBOLS.items():
        color = tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
        pixels = bytearray()
        for row in range(SIZE):
            for column in range(SIZE):
                samples = []
                for sy in range(SCALE):
                    for sx in range(SCALE):
                        x = column + (sx + .5) / SCALE - SIZE / 2
                        y = row + (sy + .5) / SCALE - SIZE / 2
                        if inside(shape, x, y, 24):
                            samples.append((*color, 255))
                        elif inside(shape, x, y, 26):
                            samples.append((255, 245, 220, 255))
                        elif inside(shape, x, y, 30):
                            samples.append((15, 12, 18, 255))
                        else:
                            samples.append((0, 0, 0, 0))
                alpha = sum(p[3] for p in samples) / len(samples)
                rgb = [round(sum(p[c] * p[3] for p in samples) / sum(p[3] for p in samples))
                       if alpha else 0 for c in range(3)]
                pixels.extend((rgb[2], rgb[1], rgb[0], round(alpha)))
        header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
        (ROOT / (name + ".tga")).write_bytes(header + pixels)
    print(f"Generated {len(SYMBOLS)} original 64x64 RGBA symbols")


if __name__ == "__main__":
    main()
