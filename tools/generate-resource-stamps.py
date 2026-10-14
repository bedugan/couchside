"""Generate checked-in resource stamps from the one Lua catalog, with no libraries."""
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
SIZE, SCALE = 64, 2
# Original bitmap lettering. Each glyph uses five columns and seven rows.
FONT = {
    'A': ['01110','10001','10001','11111','10001','10001','10001'],
    'B': ['11110','10001','10001','11110','10001','10001','11110'],
    'C': ['01111','10000','10000','10000','10000','10000','01111'],
    'D': ['11110','10001','10001','10001','10001','10001','11110'],
    'E': ['11111','10000','10000','11110','10000','10000','11111'],
    'F': ['11111','10000','10000','11110','10000','10000','10000'],
    'G': ['01111','10000','10000','10111','10001','10001','01111'],
    'H': ['10001','10001','10001','11111','10001','10001','10001'],
    'I': ['11111','00100','00100','00100','00100','00100','11111'],
    'J': ['00111','00010','00010','00010','10010','10010','01100'],
    'K': ['10001','10010','10100','11000','10100','10010','10001'],
    'L': ['10000','10000','10000','10000','10000','10000','11111'],
    'M': ['10001','11011','10101','10101','10001','10001','10001'],
    'N': ['10001','11001','10101','10011','10001','10001','10001'],
    'O': ['01110','10001','10001','10001','10001','10001','01110'],
    'P': ['11110','10001','10001','11110','10000','10000','10000'],
    'Q': ['01110','10001','10001','10001','10101','10010','01101'],
    'R': ['11110','10001','10001','11110','10100','10010','10001'],
    'S': ['01111','10000','10000','01110','00001','00001','11110'],
    'T': ['11111','00100','00100','00100','00100','00100','00100'],
    'U': ['10001','10001','10001','10001','10001','10001','01110'],
    'V': ['10001','10001','10001','10001','10001','01010','00100'],
    'W': ['10001','10001','10001','10101','10101','10101','01010'],
    'X': ['10001','10001','01010','00100','01010','10001','10001'],
    'Y': ['10001','10001','01010','00100','00100','00100','00100'],
    'Z': ['11111','00001','00010','00100','01000','10000','11111'],
}


def letter_at(code, x, y):
    if not (-27.5 <= x < 27.5 and -17.5 <= y < 17.5):
        return False
    gx, gy = int((x + 27.5) // 5), int((y + 17.5) // 5)
    if gx == 5:
        return False
    char, column = (code[0], gx) if gx < 5 else (code[1], gx - 6)
    return FONT[char][gy][column] == '1'


def color_at(code, x, y):
    if letter_at(code, x, y):
        return (255, 246, 218, 255)
    # Half a UI pixel at 16px: follows the letters, without enclosing them.
    if any(letter_at(code, x + dx, y + dy) for dx, dy in
           ((-2, 0), (2, 0), (0, -2), (0, 2), (-1.5, -1.5),
            (-1.5, 1.5), (1.5, -1.5), (1.5, 1.5))):
        return (10, 15, 15, 255)
    return (0, 0, 0, 0)


def generate(code):
    pixels = bytearray()
    for row in range(SIZE):
        for column in range(SIZE):
            samples = [color_at(code, column + (sx + .5) / SCALE - SIZE / 2,
                                row + (sy + .5) / SCALE - SIZE / 2)
                       for sy in range(SCALE) for sx in range(SCALE)]
            total_alpha = sum(p[3] for p in samples)
            alpha = round(total_alpha / len(samples))
            rgb = [round(sum(p[c] * p[3] for p in samples) / total_alpha) if total_alpha else 0 for c in range(3)]
            pixels.extend((rgb[2], rgb[1], rgb[0], alpha))
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 0x28)
    return header + pixels


def main():
    catalog = (ROOT / 'Couchside_Gathering/ResourceCatalog.lua').read_text()
    stamps = re.findall(r'stamp = "([A-Z]{2})"', catalog)
    assert stamps and len(set(stamps)) == len(stamps), 'Empty or duplicate stamp codes'
    output = ROOT / 'Couchside_Gathering/Media'
    output.mkdir(exist_ok=True)
    for code in stamps:
        (output / f'stamp-{code.lower()}.tga').write_bytes(generate(code))
    print(f'Generated {len(stamps)} original stamps from ResourceCatalog.lua')


if __name__ == '__main__':
    main()
