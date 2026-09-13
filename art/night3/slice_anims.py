from PIL import Image
import colorsys
from pathlib import Path

ROOT = Path("/workspace/volt/export/night3")

def key_green(im):
    im = im.convert("RGBA")
    px = im.load(); w,h = im.size
    for y in range(h):
        for x in range(w):
            r,g,b,a = px[x,y]
            if a==0: continue
            hh,s,v = colorsys.rgb_to_hsv(r/255,g/255,b/255)
            if 0.22 <= hh <= 0.45 and s >= 0.35 and v >= 0.25 and g > r+25 and g > b+25:
                px[x,y]=(0,0,0,0)
            elif g > max(r,b)+40 and s>0.2 and 0.18<=hh<=0.48:
                strength=min(1.0,(g-max(r,b)-20)/80)
                px[x,y]=(r,g,b,int(a*(1-strength)))
    return im

def dens_cols(im, y0, y1, amin=35):
    px=im.load(); w,_=im.size
    out=[]
    for x in range(w):
        c=0
        for y in range(y0,y1):
            if px[x,y][3]>amin: c+=1
        out.append(c)
    return out

def dens_rows(im, amin=35):
    px=im.load(); w,h=im.size
    return [sum(1 for x in range(w) if px[x,y][3]>amin) for y in range(h)]

def content_span(vals, thr):
    idx=[i for i,v in enumerate(vals) if v>thr]
    return (idx[0], idx[-1]+1) if idx else (0,len(vals))

def valley_splits(dens, left, right, n):
    cuts=[left]
    for i in range(1,n):
        c=left+int((right-left)*i/n)
        win=range(max(left+8,c-45), min(right-8,c+45))
        cuts.append(min(win, key=lambda x: dens[x]))
    cuts.append(right)
    return [(cuts[i], cuts[i+1]) for i in range(n)]

def bbox(im, x0,x1,y0,y1, amin=35, pad=3):
    px=im.load(); w,h=im.size
    minx,miny,maxx,maxy=x1,y1,x0,y0
    found=False
    for y in range(y0,y1):
        for x in range(x0,x1):
            if px[x,y][3]>amin:
                found=True
                minx=min(minx,x); maxx=max(maxx,x)
                miny=min(miny,y); maxy=max(maxy,y)
    if not found: return None
    return (max(0,minx-pad), max(0,miny-pad), min(w,maxx+1+pad), min(h,maxy+1+pad))

def row_bands(im, nrows):
    dr=dens_rows(im)
    thr=max(5,(max(dr) or 1)*0.05)
    top,bot=content_span(dr, thr)
    # valley splits vertically
    cuts=[top]
    for i in range(1,nrows):
        c=top+int((bot-top)*i/nrows)
        win=range(max(top+10,c-40), min(bot-10,c+40))
        cuts.append(min(win, key=lambda y: dr[y]))
    cuts.append(bot)
    return [(cuts[i], cuts[i+1]) for i in range(nrows)]

def slice_grid(path, out_map, frames_per_row):
    """out_map: list of (name, outdir) per row"""
    raw=Image.open(path)
    im=key_green(raw)
    keyed=ROOT/"sheets"/(Path(path).stem.replace("-green","")+"-keyed.png")
    im.save(keyed)
    bands=row_bands(im, len(out_map))
    print(Path(path).name, "bands", bands)
    for (y0,y1),(name,outdir),nframes in zip(bands, out_map, frames_per_row if isinstance(frames_per_row,list) else [frames_per_row]*len(out_map)):
        outdir=Path(outdir); outdir.mkdir(parents=True, exist_ok=True)
        dens=dens_cols(im, y0, y1)
        thr=max(2,(max(dens) or 1)*0.04)
        left,right=content_span(dens, thr)
        segs=valley_splits(dens, left, right, nframes)
        print(" ", name, "segs", segs)
        for i,(a,b) in enumerate(segs,1):
            box=bbox(im,a,b,y0,y1)
            if not box: continue
            crop=im.crop(box)
            # drop near-empty
            if sum(1 for p in crop.getdata() if (p[3] if len(p)>3 else 255)>40) < 100:
                continue
            crop.save(outdir/f"{name}_{i:02d}.png")
            print("   wrote", name, i, crop.size)

slice_grid(
    ROOT/"sheets/volt-idle-attack-green.png",
    [("idle", ROOT/"slices/volt/idle"), ("attack", ROOT/"slices/volt/attack")],
    6,
)
slice_grid(
    ROOT/"sheets/volt-dash-hurt-green.png",
    [("dash", ROOT/"slices/volt/dash"), ("knockback", ROOT/"slices/volt/knockback")],
    6,
)
slice_grid(
    ROOT/"sheets/bots-walkhop-green.png",
    [("scout_walk", ROOT/"slices/bots/scout"), ("popper_hop", ROOT/"slices/bots/popper"), ("warden_walk", ROOT/"slices/bots/warden")],
    4,
)

# README
(ROOT/"README.md").write_text("""# Volt jam — night3 anim pack

Godot 2D SpriteFrames-ready RGBA frames (chroma-cut `#00FF00`).

## Volt
- `slices/volt/idle/idle_01..06.png` — breathing idle loop
- `slices/volt/attack/attack_01..06.png` — wind-up → swing → recover
- `slices/volt/dash/dash_01..06.png` — dash/dodge
- `slices/volt/knockback/knockback_01..06.png` — hit → recoil → recover

## Bots (optional pile motion)
- `slices/bots/scout/scout_walk_01..04.png`
- `slices/bots/popper/popper_hop_01..04.png`
- `slices/bots/warden/warden_walk_01..04.png`

Greenscreen masters in `sheets/`.
""")
print("done")
for p in sorted(ROOT.rglob("*.png")):
    if "slices" in str(p):
        print(p.relative_to(ROOT))
