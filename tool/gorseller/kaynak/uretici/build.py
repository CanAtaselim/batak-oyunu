"""Desteleri üretir: out/decks/<id>/svg/*.svg, out/decks/<id>/png/*.png ve kontrol sayfaları.

Kullanım: python3 build.py [deste_id ...] [--no-png] [--sheet]
Dosya adları: SA.svg, H10.svg, DQ.svg, C2.svg ... ve back.svg (skill'deki kayıt kodlarıyla aynı).
"""
import sys, os, asyncio, importlib
from common import RANKS, SUITS

DECKS = {
    'osmanli': ('ottoman', 'OttomanDeck'),
    'sehir': ('city', 'CityDeck'),
    'ejder': ('fantasy', 'FantasyDeck'),
}
OUT = 'out'


def load(did):
    mod, cls = DECKS[did]
    return getattr(importlib.import_module(mod), cls)()


def write_deck(deck):
    d = f'{OUT}/decks/{deck.id}/svg'
    os.makedirs(d, exist_ok=True)
    files = {}
    for s in SUITS:
        for r in RANKS:
            files[f'{s}{r}'] = deck.card(r, s)
    files['back'] = deck.back_svg()
    for k, v in files.items():
        open(f'{d}/{k}.svg', 'w').write(v)
    return files


async def render(jobs, scale=2):
    """jobs: [(svg_path, png_path, w, h)] -> Chromium ile PNG (şeffaf köşeler)."""
    from playwright.async_api import async_playwright
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(device_scale_factor=scale)
        for svg, png, w, h in jobs:
            await pg.set_viewport_size({'width': w, 'height': h})
            src = open(svg).read()
            await pg.set_content(f'<html><body style="margin:0;background:transparent">{src}</body></html>')
            await pg.locator('svg').screenshot(path=png, omit_background=True)
        await b.close()


def sheet(deck_ids, path, sample=None):
    cells = []
    for did in deck_ids:
        base = f'decks/{did}/svg'
        names = sample or [f'{s}{r}' for s in SUITS for r in RANKS] + ['back']
        imgs = ''.join(f'<img src="{base}/{n}.svg" width="125">' for n in names)
        cells.append(f'<h3 style="font:16px sans-serif;margin:8px">{did}</h3><div style="display:flex;flex-wrap:wrap;gap:6px">{imgs}</div>')
    open(f'{OUT}/{path}', 'w').write(f'<html><body style="background:#2b3a2f;margin:10px">{"".join(cells)}</body></html>')


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    ids = args or list(DECKS)
    for did in ids:
        deck = load(did)
        write_deck(deck)
        if '--no-png' not in sys.argv:
            d = f'{OUT}/decks/{did}'
            os.makedirs(f'{d}/png', exist_ok=True)
            jobs = [(f'{d}/svg/{f}', f'{d}/png/{f[:-4]}.png', 250, 350) for f in sorted(os.listdir(f'{d}/svg'))]
            asyncio.run(render(jobs))
        print('ok', did)
