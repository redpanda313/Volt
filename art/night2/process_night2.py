from PIL import Image, ImageDraw, ImageFont
import colorsys
from pathlib import Path

ROOT = Path("/workspace/volt/export/night2")

def key_green(im):
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            hh, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
            if 0.22 <= hh <= 0.45 and s >= 0.35 and v >= 0.25 and g > r + 25 and g > b + 25:
                px[x, y] = (0, 0, 0, 0)
            elif g > max(r, b) + 40 and s > 0.2 and 0.18 <= hh <= 0.48:
                strength = min(1.0, (g - max(r, b) - 20) / 80.0)
                px[x, y] = (r, g, b, int(a * (1 - strength)))
    return im

def dens_cols(im, amin=35):
    px = im.load(); w, h = im.size
    return [sum(1 for y in range(h) if px[x, y][3] > amin) for x in range(w)]

def dens_rows(im, amin=35):
    px = im.load(); w, h = im.size
    return [sum(1 for x in range(w) if px[x, y][3] > amin) for y in range(h)]

def content_span(vals, thr):
    idx = [i for i, v in enumerate(vals) if v > thr]
    return (idx[0], idx[-1] + 1) if idx else (0, len(vals))

def equal_splits(left, right, n):
    return [(left + int((right-left)*i/n), left + int((right-left)*(i+1)/n)) for i in range(n)]

def bbox(im, x0, x1, y0=None, y1=None, amin=35, pad=4):
    px = im.load(); w, h = im.size
    y0 = 0 if y0 is None else y0
    y1 = h if y1 is None else y1
    minx, miny, maxx, maxy = x1, y1, x0, y0
    found = False
    for y in range(y0, y1):
        for x in range(x0, x1):
            if px[x, y][3] > amin:
                found = True
                minx = min(minx, x); maxx = max(maxx, x)
                miny = min(miny, y); maxy = max(maxy, y)
    if not found:
        return None
    return (max(0, minx-pad), max(0, miny-pad), min(w, maxx+1+pad), min(h, maxy+1+pad))

# --- Volt idle 4 frames ---
volt = key_green(Image.open(ROOT/"sheets/volt-idle-loop-green.png"))
volt.save(ROOT/"sheets/volt-idle-loop-keyed.png")
dc = dens_cols(volt)
thr = max(5, sorted([d for d in dc if d>0])[len([d for d in dc if d>0])//10] if any(dc) else 5)
left, right = content_span(dc, thr)
segs = equal_splits(left, right, 4)
# prefer valleys if possible
for i in range(1, 4):
    c = left + int((right-left)*i/4)
    win = range(max(left+10, c-40), min(right-10, c+40))
    best = min(win, key=lambda x: dc[x])
    # rebuild with valley cuts
cuts = [left]
for i in range(1, 4):
    c = left + int((right-left)*i/4)
    win = range(max(left+10, c-50), min(right-10, c+50))
    cuts.append(min(win, key=lambda x: dc[x]))
cuts.append(right)
segs = [(cuts[i], cuts[i+1]) for i in range(4)]
print("volt segs", segs)
for i, (a, b) in enumerate(segs, 1):
    box = bbox(volt, a, b)
    if not box: continue
    crop = volt.crop(box)
    crop.save(ROOT/f"slices/volt_idle/volt_idle_{i:02d}.png")
    print("idle", i, crop.size)

# --- Debris: 3 groups by x, then individual chunks via connected-ish column clusters ---
deb = key_green(Image.open(ROOT/"sheets/bots-breakapart-green.png"))
deb.save(ROOT/"sheets/bots-breakapart-keyed.png")
dc = dens_cols(deb)
thr = max(3, (max(dc) or 1) * 0.04)
left, right = content_span(dc, thr)
# three groups
gcuts = [left]
for i in (1, 2):
    c = left + int((right-left)*i/3)
    win = range(max(left+20, c-80), min(right-20, c+80))
    gcuts.append(min(win, key=lambda x: dc[x]))
gcuts.append(right)
groups = [("scout", gcuts[0], gcuts[1]), ("popper", gcuts[1], gcuts[2]), ("warden", gcuts[2], gcuts[3])]
print("debris groups", groups)

def split_pieces(im, x0, x1, min_w=18):
    d = dens_cols(im)
    # local density only in range
    filled = []
    for x in range(x0, x1):
        filled.append(d[x] > max(2, (max(d[x0:x1]) or 1)*0.05))
    segs=[]; ins=False; st=0
    for i,f in enumerate(filled):
        if f and not ins:
            ins=True; st=i
        elif not f and ins:
            if i-st >= min_w: segs.append((x0+st, x0+i))
            ins=False
    if ins and len(filled)-st >= min_w:
        segs.append((x0+st, x0+len(filled)))
    return segs

for name, a, b in groups:
    pieces = split_pieces(deb, a, b)
    print(name, "pieces", len(pieces), pieces)
    # if too few, save whole group plus try row splits
    outdir = ROOT/"slices/debris"/name
    if len(pieces) < 3:
        box = bbox(deb, a, b)
        if box:
            deb.crop(box).save(outdir/f"{name}_pile.png")
        # grid split 2x3
        box = bbox(deb, a, b)
        if box:
            gx0, gy0, gx1, gy1 = box
            cols, rows = 3, 2
            n=0
            for ry in range(rows):
                for cx in range(cols):
                    sx0 = gx0 + int((gx1-gx0)*cx/cols)
                    sx1 = gx0 + int((gx1-gx0)*(cx+1)/cols)
                    sy0 = gy0 + int((gy1-gy0)*ry/rows)
                    sy1 = gy0 + int((gy1-gy0)*(ry+1)/rows)
                    sub = bbox(deb, sx0, sx1, sy0, sy1, pad=2)
                    if not sub: continue
                    crop = deb.crop(sub)
                    # skip nearly empty
                    if sum(1 for p in crop.getdata() if p[3]>40) < 80: continue
                    n += 1
                    crop.save(outdir/f"{name}_chunk_{n:02d}.png")
            print(name, "grid chunks", n)
    else:
        for i,(pa,pb) in enumerate(pieces,1):
            box = bbox(deb, pa, pb)
            if not box: continue
            crop = deb.crop(box)
            if sum(1 for p in crop.getdata() if p[3]>40) < 80: continue
            crop.save(outdir/f"{name}_chunk_{i:02d}.png")
            print(" wrote", name, i, crop.size)

# --- HUD to 1080x1920 ---
hud_raw = Image.open(ROOT/"sheets/hud-refine-raw.png").convert("RGBA")
hw, hh = hud_raw.size
# place on portrait canvas
out_w, out_h = 1080, 1920
canvas = Image.new("RGBA", (out_w, out_h), (8, 12, 28, 255))
# scale HUD art to fit width with margin
scale = (out_w - 80) / hw
nh = int(hh * scale)
nw = out_w - 80
hud = hud_raw.resize((nw, nh), Image.Resampling.LANCZOS)
# if still short, ok; paste near top
y = 80
canvas.paste(hud, (40, y), hud if hud.mode=="RGBA" else None)
# ensure portrait
canvas.convert("RGB").save(ROOT/"hud/hud_portrait_9x16.png")
# also export transparent HUD on clear bg cropped
keyed_like = hud_raw.copy()
# make near-navy soft transparent for piece use? keep as concept mock
hud_raw.save(ROOT/"hud/hud_elements_sheet.png")
print("hud", canvas.size, "src", hud_raw.size)
print("done")
