#!/usr/bin/env python3
"""Cut night2 HUD chrome into transparent overlays for the 9:16 playfield.

Does not replace Sable sources. Writes derived slices next to them so Godot
can swap TextureRects later without another layout pass.
"""
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "art/night2/hud/hud_elements_sheet.png"
PORTRAIT = ROOT / "art/night2/hud/hud_portrait_9x16.png"
OUT = ROOT / "art/night2/hud"
OUT.mkdir(parents=True, exist_ok=True)


def near_bg(px, bg, tol=18):
    return all(abs(int(px[i]) - int(bg[i])) <= tol for i in range(3))


def flood_clear(im: Image.Image, seeds, bg, tol=18):
    im = im.convert("RGBA")
    w, h = im.size
    pix = im.load()
    seen = [[False] * w for _ in range(h)]
    q = deque()
    for x, y in seeds:
        if 0 <= x < w and 0 <= y < h:
            q.append((x, y))
            seen[y][x] = True
    while q:
        x, y = q.popleft()
        r, g, b, a = pix[x, y]
        if a == 0 or not near_bg((r, g, b), bg, tol):
            continue
        pix[x, y] = (r, g, b, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                seen[ny][nx] = True
                q.append((nx, ny))
    return im


def content_bbox(im: Image.Image, alpha_min=20, pad=6):
    px = im.load()
    w, h = im.size
    minx, miny, maxx, maxy = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
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


def main() -> None:
    sheet = Image.open(SHEET).convert("RGBA")
    bg = sheet.getpixel((2, 2))[:3]
    keyed = flood_clear(sheet, [(2, 2), (sheet.width - 3, 2), (2, sheet.height - 3)], bg, tol=22)
    box = content_bbox(keyed)
    if box:
        keyed.crop(box).save(OUT / "hud_chrome_sheet.png")
        print("sheet chrome", box, keyed.crop(box).size)

    # Top capsule only — stay above the altitude rail / HEIGHT chip.
    top = keyed.crop((0, 0, keyed.width, int(keyed.height * 0.24)))
    tbox = content_bbox(top, pad=4)
    if tbox:
        top_im = top.crop(tbox).convert("RGBA")
        panel = (10, 16, 32, 255)
        px = top_im.load()
        tw, th = top_im.size
        for y in range(th):
            for x in range(tw):
                r, g, b, a = px[x, y]
                if a > 0 and r > 210 and g > 210 and b > 210:
                    px[x, y] = panel
        top_im.save(OUT / "hud_top.png")
        print("top", tbox, top_im.size)

    # Left altitude rail.
    meter = keyed.crop((0, int(keyed.height * 0.22), int(keyed.width * 0.28), int(keyed.height * 0.92)))
    mbox = content_bbox(meter, pad=4)
    if mbox:
        meter.crop(mbox).save(OUT / "hud_meter.png")
        print("meter", mbox, meter.crop(mbox).size)

    # Portrait: punch playfield + outer navy so we have a 9:16 overlay hook.
    portrait = Image.open(PORTRAIT).convert("RGBA")
    pbg = portrait.getpixel((2, 2))[:3]
    punched = flood_clear(
        portrait,
        [
            (2, 2),
            (portrait.width - 3, 2),
            (2, portrait.height - 3),
            (portrait.width // 2, int(portrait.height * 0.72)),
        ],
        pbg,
        tol=20,
    )
    punched.save(OUT / "hud_chrome.png")
    print("portrait chrome", punched.size, "opaque", sum(1 for p in punched.getdata() if p[3] > 20))


if __name__ == "__main__":
    main()
