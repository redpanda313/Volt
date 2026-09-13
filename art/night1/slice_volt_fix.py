from PIL import Image
import colorsys
from pathlib import Path

src = Path("/workspace/volt/export/sheets/volt-poses-green.png")
im = Image.open(src).convert("RGBA")
px = im.load()
w, h = im.size
# hue key
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        rf, gf, bf = r/255, g/255, b/255
        hh, s, v = colorsys.rgb_to_hsv(rf, gf, bf)
        if 0.22 <= hh <= 0.45 and s >= 0.35 and v >= 0.25 and g > r + 25 and g > b + 25:
            px[x, y] = (0,0,0,0)
        elif g > max(r,b)+40 and s>0.2 and 0.18<=hh<=0.48:
            strength = min(1.0, (g-max(r,b)-20)/80)
            px[x, y] = (r,g,b, int(a*(1-strength)))

# column density
dens = []
for x in range(w):
    c = 0
    for y in range(h):
        if px[x,y][3] > 40:
            c += 1
    dens.append(c)

# find deep valleys between characters (low density stretches)
avg = sum(1 for d in dens if d>0) and sum(d for d in dens if d>0)/max(1,sum(1 for d in dens if d>0))
threshold = max(8, avg * 0.08)
filled = [d > threshold for d in dens]
# segments
segs=[]
in_s=False
st=0
for i,f in enumerate(filled):
    if f and not in_s:
        in_s=True; st=i
    elif not f and in_s:
        if i-st>40: segs.append((st,i))
        in_s=False
if in_s and w-st>40: segs.append((st,w))
print("segs", segs, "count", len(segs))

names=["volt_idle","volt_attack","volt_dodge"]
if len(segs)!=3:
    # force three cuts at local minima of dens in content span
    xs=[i for i,d in enumerate(dens) if d>threshold]
    left,right=xs[0],xs[-1]
    # search two valleys
    third=(right-left)/3
    cuts=[]
    for k in (1,2):
        center=int(left+k*third)
        window=range(max(left+20,center-60), min(right-20,center+60))
        best=min(window, key=lambda i: dens[i])
        cuts.append(best)
    segs=[(left,cuts[0]),(cuts[0],cuts[1]),(cuts[1],right+1)]
    print("forced segs", segs)

out_dir=Path("/workspace/volt/export/slices")
for name,(a,b) in zip(names,segs):
    minx,miny,maxx,maxy=b,h,a,0
    found=False
    for y in range(h):
        for x in range(a,b):
            if px[x,y][3]>40:
                found=True
                minx=min(minx,x); maxx=max(maxx,x)
                miny=min(miny,y); maxy=max(maxy,y)
    if not found: continue
    pad=4
    box=(max(0,minx-pad),max(0,miny-pad),min(w,maxx+1+pad),min(h,maxy+1+pad))
    crop=im.crop(box)
    # strip leftover green fringe
    cpx=crop.load()
    cw,ch=crop.size
    for y in range(ch):
        for x in range(cw):
            r,g,b,a=cpx[x,y]
            if a==0: continue
            hh,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
            if 0.22<=hh<=0.45 and s>0.4 and g>r+20 and g>b+20:
                cpx[x,y]=(0,0,0,0)
    crop.save(out_dir/f"{name}.png")
    print("wrote", name, crop.size)

# verify alpha
for p in out_dir.glob("*.png"):
    t=Image.open(p)
    modes=t.mode
    alphas=0
    if t.mode=="RGBA":
        a=t.getchannel("A")
        alphas=sum(1 for v in a.getdata() if v==0)
    print(p.name, t.size, modes, "transparent_px", alphas)
