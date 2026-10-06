"""Oyun masaları: 1080x1920 dikey arka planlar (Flutter'da BoxFit.cover).

Bölgeler (skill'deki koltuk düzeniyle aynı):
  koltuk 2 (üst)  : (540, 330)
  koltuk 3 (sol)  : (120, 860)
  koltuk 1 (sağ)  : (960, 860)
  orta / el alanı : (540, 860), r≈250  -> yere atılan 4 kağıt
  koltuk 0 (insan): (540, 1400) ve altı -> oyuncunun eli
Üst 0-170 arası skor çubuğu için sade bırakılır.
"""
import math, os, random
from common import rosette, eight_star, star_points, suit
from fantasy import rune_ring, rune_diamond

BW, BH = 1080, 1920
SEATS = {2: (540, 330), 3: (120, 860), 1: (960, 860)}
MID = (540, 860)


def doc(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {BW} {BH}" width="{BW}" height="{BH}">'
            f'<defs>{defs}</defs>{body}</svg>')


# ------------------------------------------------------------------ Osmanlı: halı
def board_osmanli():
    GOLD, RED, RED_D, NAVY, TURQ, IVORY = '#C9A227', '#7A161B', '#4E0D11', '#1D2A4D', '#1C8C8C', '#F3E7CC'
    defs = (f'<radialGradient id="field" cx="50%" cy="45%" r="70%"><stop offset="0" stop-color="#8E1C22"/>'
            f'<stop offset="1" stop-color="{RED_D}"/></radialGradient>'
            f'<radialGradient id="med" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#3A0A0D"/>'
            f'<stop offset="1" stop-color="#5E1015"/></radialGradient>'
            f'<linearGradient id="hand" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/>'
            f'<stop offset="1" stop-color="#000" stop-opacity="0.45"/></linearGradient>'
            f'<clipPath id="inner"><rect x="70" y="70" width="940" height="1780"/></clipPath>')
    out = [f'<rect width="{BW}" height="{BH}" fill="url(#field)"/>']
    lattice = []
    for i in range(0, 17):
        for j in range(0, 30):
            x = 70 + i * 60 + (30 if j % 2 else 0)
            y = 70 + j * 60
            lattice.append(eight_star(x, y, 13, GOLD, opacity=0.09))
    out.append(f'<g clip-path="url(#inner)">{"".join(lattice)}</g>')
    # kenar bordürü (kilim)
    out.append(f'<rect x="20" y="20" width="1040" height="1880" fill="none" stroke="{NAVY}" stroke-width="44"/>')
    for x in range(20, 1061, 40):
        for y in (20, 1900):
            out.append(f'<path d="M{x} {y - 14} L {x + 14} {y} L {x} {y + 14} L {x - 14} {y} Z" fill="{GOLD}" opacity="0.85"/>')
    for y in range(60, 1880, 40):
        for x in (20, 1060):
            out.append(f'<path d="M{x} {y - 14} L {x + 14} {y} L {x} {y + 14} L {x - 14} {y} Z" fill="{GOLD}" opacity="0.85"/>')
    out.append(f'<rect x="44" y="44" width="992" height="1832" fill="none" stroke="{GOLD}" stroke-width="4"/>')
    out.append(f'<rect x="56" y="56" width="968" height="1808" fill="none" stroke="{TURQ}" stroke-width="2"/>')
    # köşebentler
    for (cx, cy, a) in ((56, 56, 0), (1024, 56, 90), (1024, 1864, 180), (56, 1864, 270)):
        out.append(f'<g transform="rotate({a} {cx} {cy})">'
                   f'<path d="M{cx} {cy} L {cx + 170} {cy} A 170 170 0 0 1 {cx} {cy + 170} Z" fill="{NAVY}" opacity="0.9"/>'
                   f'<path d="M{cx} {cy} L {cx + 150} {cy} A 150 150 0 0 1 {cx} {cy + 150} Z" fill="none" stroke="{GOLD}" stroke-width="3"/>'
                   + rosette(cx + 60, cy + 60, 70, 8, GOLD, opacity=0.35) + '</g>')
    # göbek (orta madalyon) = yere atılan kağıtların alanı
    cx, cy = MID
    out += [f'<ellipse cx="{cx}" cy="{cy}" rx="330" ry="380" fill="{NAVY}" stroke="{GOLD}" stroke-width="6"/>',
            rosette(cx, cy, 360, 24, GOLD, petal_w=26, opacity=0.18),
            f'<ellipse cx="{cx}" cy="{cy}" rx="300" ry="350" fill="none" stroke="{TURQ}" stroke-width="3"/>',
            f'<circle cx="{cx}" cy="{cy}" r="262" fill="url(#med)" stroke="{GOLD}" stroke-width="4"/>',
            f'<circle cx="{cx}" cy="{cy}" r="248" fill="none" stroke="{GOLD}" stroke-width="1.5" opacity="0.6"/>',
            eight_star(cx, cy, 90, GOLD, opacity=0.08)]
    for a in range(0, 360, 45):
        r = math.radians(a - 90)
        out.append(eight_star(cx + 290 * math.cos(r) * 1.0, cy + 290 * math.sin(r) * 1.12, 14, GOLD))
    # madalyonun üst/alt uçları (salbek)
    for sgn in (-1, 1):
        y = cy + sgn * 400
        out.append(f'<path d="M{cx - 40} {y - sgn * 20} L {cx} {y + sgn * 40} L {cx + 40} {y - sgn * 20} Z" fill="{GOLD}"/>')
    # koltuk tablaları
    for (x, y) in SEATS.values():
        out.append(f'<circle cx="{x}" cy="{y}" r="78" fill="{RED_D}" stroke="{GOLD}" stroke-width="4"/>'
                   f'<circle cx="{x}" cy="{y}" r="66" fill="none" stroke="{TURQ}" stroke-width="2"/>')
    out.append(f'<rect x="0" y="1380" width="{BW}" height="540" fill="url(#hand)"/>')
    return doc(defs, '\n'.join(out))


# ------------------------------------------------------------------ Şehir: çatı katı
def board_sehir():
    INK, CYAN, MAG, YEL = '#15151A', '#28D2E8', '#E0359B', '#FFC21A'
    rnd = random.Random(7)
    defs = ('<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
            '<stop offset="0" stop-color="#0B1030"/><stop offset="0.35" stop-color="#2A1450"/>'
            '<stop offset="0.36" stop-color="#1A1C2C"/><stop offset="1" stop-color="#101118"/></linearGradient>'
            '<radialGradient id="pad" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#2B2E45"/>'
            '<stop offset="1" stop-color="#1B1D2E"/></radialGradient>'
            '<radialGradient id="moon" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#FFF6D0"/>'
            '<stop offset="1" stop-color="#FFF6D0" stop-opacity="0"/></radialGradient>')
    out = [f'<rect width="{BW}" height="{BH}" fill="url(#sky)"/>',
           '<circle cx="850" cy="250" r="160" fill="url(#moon)" opacity="0.5"/>',
           '<circle cx="850" cy="250" r="62" fill="#FFF2C2"/>']
    for _ in range(70):
        x, y = rnd.uniform(0, BW), rnd.uniform(160, 560)
        out.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rnd.uniform(1, 2.6):.1f}" fill="#FFFFFF" opacity="{rnd.uniform(0.3, 0.9):.2f}"/>')
    # silüet: iki sıra bina
    for layer, (col, base, hmin, hmax) in enumerate((('#241B45', 690, 120, 330), ('#141527', 690, 60, 220))):
        x = -20
        while x < BW:
            w = rnd.randint(70, 150)
            h = rnd.randint(hmin, hmax)
            out.append(f'<rect x="{x}" y="{base - h}" width="{w}" height="{h + 2}" fill="{col}"/>')
            if layer == 1:
                for wx in range(x + 12, x + w - 14, 22):
                    for wy in range(base - h + 16, base - 10, 28):
                        if rnd.random() < 0.35:
                            out.append(f'<rect x="{wx}" y="{wy}" width="10" height="14" fill="{YEL}" opacity="0.85"/>')
            else:
                if rnd.random() < 0.4:
                    out.append(f'<rect x="{x + w / 2 - 3:.0f}" y="{base - h - 60}" width="6" height="60" fill="{col}"/>'
                               f'<circle cx="{x + w / 2:.0f}" cy="{base - h - 62}" r="6" fill="{MAG}"/>')
            x += w + rnd.randint(-10, 8)
    # çatı zemini: halftone + çizgiler
    out.append(f'<rect x="0" y="690" width="{BW}" height="12" fill="{CYAN}" opacity="0.8"/>')
    for i in range(0, 12):
        for j in range(0, 44):
            x = i * 96 + (48 if j % 2 else 0)
            y = 730 + j * 28
            r = 2.2 + 1.6 * (j / 44)
            out.append(f'<circle cx="{x}" cy="{y}" r="{r:.1f}" fill="#2A2C44"/>')
    # helikopter pisti = yere atılan kağıt alanı
    cx, cy = MID
    out += [f'<circle cx="{cx}" cy="{cy}" r="300" fill="{INK}" opacity="0.6"/>',
            f'<circle cx="{cx}" cy="{cy}" r="280" fill="url(#pad)" stroke="{YEL}" stroke-width="10"/>']
    for a in range(0, 360, 10):
        out.append(f'<path d="M{cx} {cy - 262} L {cx} {cy - 242}" stroke="{YEL}" stroke-width="8" '
                   f'transform="rotate({a} {cx} {cy})" opacity="{0.9 if a % 30 == 0 else 0.35}"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="230" fill="none" stroke="{CYAN}" stroke-width="3" opacity="0.6"/>')
    out.append(f'<polygon points="{star_points(cx, cy, 120, 55, 8)}" fill="#FFFFFF" opacity="0.05"/>')
    # neon koltuk halkaları
    for k, (x, y) in SEATS.items():
        c = (CYAN, MAG, YEL)[k % 3]
        out.append(f'<circle cx="{x}" cy="{y}" r="86" fill="{c}" opacity="0.12"/>'
                   f'<circle cx="{x}" cy="{y}" r="74" fill="{INK}" stroke="{c}" stroke-width="6"/>')
    out.append(f'<rect x="0" y="1360" width="{BW}" height="560" fill="#0C0D14" opacity="0.55"/>'
               f'<rect x="0" y="1360" width="{BW}" height="8" fill="{MAG}" opacity="0.8"/>')
    return doc(defs, '\n'.join(out))


# ------------------------------------------------------------------ Ejder: meyhane masası
def board_ejder():
    GOLD, GLOW = '#C8963E', '#F2C14E'
    rnd = random.Random(3)
    defs = ('<radialGradient id="vig" cx="50%" cy="45%" r="75%"><stop offset="0" stop-color="#000" stop-opacity="0"/>'
            '<stop offset="1" stop-color="#000" stop-opacity="0.75"/></radialGradient>'
            '<radialGradient id="cand" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#F2C14E" stop-opacity="0.55"/>'
            '<stop offset="1" stop-color="#F2C14E" stop-opacity="0"/></radialGradient>'
            '<radialGradient id="rune" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#2A1A0E"/>'
            '<stop offset="0.8" stop-color="#1E130A"/><stop offset="1" stop-color="#F2C14E" stop-opacity="0.25"/></radialGradient>')
    out = []
    tones = ['#4A3020', '#3F2919', '#523522', '#46301E', '#3B2617']
    x, i = 0, 0
    while x < BW:
        w = rnd.randint(150, 200)
        out.append(f'<rect x="{x}" y="0" width="{w}" height="{BH}" fill="{tones[i % len(tones)]}"/>')
        for _ in range(14):
            gx = x + rnd.uniform(10, w - 10)
            amp = rnd.uniform(4, 14)
            d = f'M{gx:.0f} 0 ' + ' '.join(f'Q {gx + amp * (1 if k % 2 else -1):.0f} {k * 240 + 120} {gx:.0f} {(k + 1) * 240}' for k in range(8))
            out.append(f'<path d="{d}" fill="none" stroke="#2C1C10" stroke-width="{rnd.uniform(1, 2.5):.1f}" opacity="0.5"/>')
        # budak
        if rnd.random() < 0.6:
            kx, ky = x + rnd.uniform(30, w - 30), rnd.uniform(200, 1700)
            out.append(f'<ellipse cx="{kx:.0f}" cy="{ky:.0f}" rx="14" ry="30" fill="#2C1C10" opacity="0.6"/>'
                       f'<ellipse cx="{kx:.0f}" cy="{ky:.0f}" rx="24" ry="48" fill="none" stroke="#2C1C10" stroke-width="2" opacity="0.4"/>')
        out.append(f'<rect x="{x + w - 3}" y="0" width="3" height="{BH}" fill="#1E130A"/>')
        x += w
        i += 1
    # mum ışıkları
    for (cx, cy) in ((110, 180), (970, 180), (110, 1500), (970, 1500)):
        out.append(f'<circle cx="{cx}" cy="{cy}" r="260" fill="url(#cand)"/>')
    # oyma rün çemberi = kağıt alanı
    cx, cy = MID
    out += [f'<circle cx="{cx}" cy="{cy}" r="300" fill="url(#rune)"/>',
            rune_ring(cx, cy, 300, 262, 40, GOLD, 4),
            rune_ring(cx, cy, 250, 236, 1, GLOW, 1.5).split('<path')[0],
            f'<circle cx="{cx}" cy="{cy}" r="236" fill="none" stroke="{GLOW}" stroke-width="1.5" opacity="0.5"/>']
    for a in (0, 90, 180, 270):
        out.append(f'<g transform="rotate({a} {cx} {cy})">{rune_diamond(cx, cy - 330, 24, GOLD)}</g>')
    # koltuk rün halkaları
    for (x, y) in SEATS.values():
        out.append(f'<circle cx="{x}" cy="{y}" r="80" fill="#1E130A" opacity="0.7"/>' + rune_ring(x, y, 80, 64, 16, GOLD, 2.5))
    out.append(f'<rect width="{BW}" height="{BH}" fill="url(#vig)"/>')
    return doc(defs, '\n'.join(out))


BOARDS = {'osmanli': board_osmanli, 'sehir': board_sehir, 'ejder': board_ejder}

if __name__ == '__main__':
    os.makedirs('out/boards', exist_ok=True)
    for k, f in BOARDS.items():
        open(f'out/boards/{k}.svg', 'w').write(f())
        print('ok', k)
