"""Recolour a Catppuccin Kvantum theme into another palette, role by role."""

import json
import os
import re
import sys

src_dir, map_file, out_dir, name = sys.argv[1:]
spec = json.load(open(map_file))
colours = {k.lower(): v.lower() for k, v in spec["map"].items()}
src_blue, dst_blue = spec["srcBlue"].lower(), spec["dstBlue"].lower()


def rgb(h):
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def hexa(c):
    return "".join(f"{round(min(255, max(0, x))):02x}" for x in c)


def shade(c):
    """Move the target blue the way this shade moves away from the source blue."""
    if src_blue == dst_blue:
        return c
    s, b, d = rgb(c), rgb(src_blue), rgb(dst_blue)
    # least-squares blend factor, towards white for lighter shades and black for darker
    if sum(s) >= sum(b):
        den = sum((255 - y) ** 2 for y in b)
        t = max(0.0, sum((x - y) * (255 - y) for x, y in zip(s, b)) / den) if den else 0.0
        return hexa([y + (255 - y) * t for y in d])
    den = sum(y * y for y in b)
    t = max(0.0, sum((y - x) * y for x, y in zip(s, b)) / den) if den else 0.0
    return hexa([y * (1 - t) for y in d])


texts = {}
for f in os.listdir(src_dir):
    texts[f] = open(os.path.join(src_dir, f)).read()

# blues outside the palette (hover and pressed tints of the accent) follow the new blue
found = {m.lower() for t in texts.values() for m in re.findall(r"#([0-9a-fA-F]{6})(?:[0-9a-fA-F]{2})?(?![0-9a-fA-F])", t)}
for c in found - colours.keys():
    r, g, b = rgb(c)
    if b > r + 40 and b > g:
        colours[c] = shade(c)

# one pass, so a replaced colour is never replaced again; an alpha byte (#rrggbbaa) is kept
pattern = re.compile("#(" + "|".join(colours) + r")((?:[0-9a-fA-F]{2})?)(?![0-9a-fA-F])", re.IGNORECASE)
os.makedirs(os.path.join(out_dir, name))
for f, text in texts.items():
    ext = os.path.splitext(f)[1]
    with open(os.path.join(out_dir, name, name + ext), "w") as o:
        o.write(pattern.sub(lambda m: "#" + colours[m.group(1).lower()] + m.group(2), text))
