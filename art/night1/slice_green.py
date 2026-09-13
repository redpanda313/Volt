from PIL import Image
from pathlib import Path
import colorsys

OUT = Path("/workspace/volt/export/slices")
OUT.mkdir(parents=True, exist_ok=True)

def key_green(im, sat_min=0.35, val_min=0.25, hue_lo=0.22, hue_hi=0.45, green_bias=25):
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            rf, gf, bf = r / 255.0, g / 255.0, b / 255.0
            h_, s, v = colorsys.rgb_to_hsv(rf, gf, bf)
            # Hue-key lime green; protect copper (red-heavy) and cobalt (blue-heavy)
            if hue_lo <= h_ <= hue_hi and s >= sat_min and v >= val_min and g > r + green_bias and g > b + green_bias:
                px[x, y] = (0, 0, 0, 0)
            elif g > max(r, b) + 40 and s > 0.2 and 0.18 <= h_ <= 0.48:
                # soft edge
                strength = min(1.0, (g - max(r, b) - 20) / 80.0)
                na = int(a * (1 - strength))
                px[x, y] = (r, g, b, max(0, na))
    return im

def opaque_cols(im, alpha_min=30):
    px = im.load()
    w, h = im.size
    cols = []
    for x in range(w):
        hit = False
        for y in range(h):
            if px[x, y][3] > alpha_min:
                hit = True
                break
        cols.append(hit)
    return cols

def find_segments(cols, min_gap=8, min_width=20):
    segs = []
    in_seg = False
    start = 0
    for i, filled in enumerate(cols):
        if filled and not in_seg:
            in_seg = True
            start = i
        elif not filled and in_seg:
            if i - start >= min_width:
                segs.append((start, i))
            in_seg = False
    if in_seg and len(cols) - start >= min_width:
        segs.append((start, len(cols)))
    # merge tiny gaps
    if not segs:
        return segs
    merged = [segs[0]]
    for a, b in segs[1:]:
        pa, pb = merged[-1]
        if a - pb < min_gap:
            merged[-1] = (pa, b)
        else:
            merged.append((a, b))
    return merged

def bbox_for_range(im, x0, x1, alpha_min=30, pad=6):
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = x1, h, x0, 0
    found = False
    for y in range(h):
        for x in range(x0, x1):
            if px[x, y][3] > alpha_min:
                found = True
                minx = min(minx, x)
                maxx = max(maxx, x)
                miny = min(miny, y)
                maxy = max(maxy, y)
    if not found:
        return None
    return (
        max(0, minx - pad),
        max(0, miny - pad),
        min(w, maxx + 1 + pad),
        min(h, maxy + 1 + pad),
    )

def process(path, names):
    raw = Image.open(path)
    keyed = key_green(raw)
    sheet_out = Path("/workspace/volt/export/sheets") / (Path(path).stem.replace("-green", "") + "-keyed.png")
    keyed.save(sheet_out)
    cols = opaque_cols(keyed)
    segs = find_segments(cols)
    print(path, "segments", len(segs), segs)
    # if segment count mismatches names, fall back to equal splits of content span
    if len(segs) != len(names):
        filled = [i for i, c in enumerate(cols) if c]
        if filled:
            left, right = filled[0], filled[-1] + 1
            width = right - left
            segs = []
            for i in range(len(names)):
                a = left + int(width * i / len(names))
                b = left + int(width * (i + 1) / len(names))
                segs.append((a, b))
            print("fallback equal segs", segs)
    for name, (a, b) in zip(names, segs):
        box = bbox_for_range(keyed, a, b)
        if not box:
            print("skip empty", name)
            continue
        crop = keyed.crop(box)
        out = OUT / f"{name}.png"
        crop.save(out)
        print("wrote", out, crop.size)

process(
    "/workspace/volt/export/sheets/volt-poses-green.png",
    ["volt_idle", "volt_attack", "volt_dodge"],
)
process(
    "/workspace/volt/export/sheets/bots-scout-popper-warden-green.png",
    ["scout_idle", "popper_idle", "warden_idle"],
)
print("done")
