from PIL import Image
import colorsys
from pathlib import Path
from collections import deque

ROOT = Path("/workspace/volt/export/night2")
src = Image.open(ROOT/"sheets/bots-breakapart-keyed.png").convert("RGBA")
w, h = src.size
px = src.load()

def is_fg(x,y):
    return px[x,y][3] > 40

visited = [[False]*w for _ in range(h)]
components = []
for y in range(h):
    for x in range(w):
        if visited[y][x] or not is_fg(x,y):
            continue
        q = deque([(x,y)])
        visited[y][x] = True
        cells = []
        minx=maxx=x; miny=maxy=y
        while q:
            cx,cy = q.popleft()
            cells.append((cx,cy))
            minx=min(minx,cx); maxx=max(maxx,cx)
            miny=min(miny,cy); maxy=max(maxy,cy)
            for nx,ny in ((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                if 0<=nx<w and 0<=ny<h and not visited[ny][nx] and is_fg(nx,ny):
                    visited[ny][nx]=True
                    q.append((nx,ny))
        area = len(cells)
        if area < 120:
            continue
        components.append((area, minx, miny, maxx, maxy, cells))

components.sort(key=lambda t: t[1])  # left to right
print("components", len(components))

# assign to groups by center x thirds
left, right = components[0][1], components[-1][3]
spans = [
    ("scout", left, left + (right-left)/3),
    ("popper", left + (right-left)/3, left + 2*(right-left)/3),
    ("warden", left + 2*(right-left)/3, right+1),
]

# clear old chunks except piles
for name,_,_ in spans:
    d = ROOT/"slices/debris"/name
    for p in d.glob(f"{name}_chunk_*.png"):
        p.unlink()

for name, a, b in spans:
    group = [c for c in components if a <= (c[1]+c[3])/2 < b]
    # keep largest ~8
    group = sorted(group, key=lambda t: -t[0])[:8]
    group = sorted(group, key=lambda t: t[1])
    print(name, "kept", len(group))
    for i, (area,minx,miny,maxx,maxy,cells) in enumerate(group, 1):
        pad=3
        box=(max(0,minx-pad), max(0,miny-pad), min(w,maxx+1+pad), min(h,maxy+1+pad))
        # extract only this component onto clear canvas
        cw, ch = box[2]-box[0], box[3]-box[1]
        out = Image.new("RGBA", (cw, ch), (0,0,0,0))
        opx = out.load()
        for cx,cy in cells:
            opx[cx-box[0], cy-box[1]] = px[cx,cy]
        out.save(ROOT/"slices/debris"/name/f"{name}_chunk_{i:02d}.png")
        print(" ", name, i, out.size, "area", area)
print("done")
