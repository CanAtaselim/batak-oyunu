"""Şehir Muhafızları: özgün süper kahraman destesi (çizgi roman stili).
Atlas (K), Tayf (Q), Kıvılcım (J) — tamamen bu oyun için icat edilmiş karakterler."""
from common import *

INK = '#15151A'
PAPER = '#FFFDF4'
RED_ = '#E3263A'
BLUE = '#2446D8'
BLUE_D = '#1A33A6'
YEL = '#FFC21A'
GRN = '#13A05B'
CYAN = '#28D2E8'
STEEL = '#9AA6B8'
STEEL_L = '#CBD3DF'
SKIN = '#F2B98B'
SKIN_D = '#D9966A'

GARMENT = {'S': BLUE, 'H': RED_, 'D': '#FF9F1C', 'C': GRN}
TINT = {'S': '#DCE4FF', 'H': '#FFE0E4', 'D': '#FFF0CC', 'C': '#D8F3E4'}
ACCENT = {'S': YEL, 'H': YEL, 'D': BLUE, 'C': YEL}


def halftone(x0, y0, w, h, step, rmax, fill, corner='tr'):
    """Köşeden azalan yarım ton noktaları."""
    out = []
    diag = math.hypot(w, h)
    for i in range(int(w // step) + 1):
        for j in range(int(h // step) + 1):
            x = x0 + i * step + (step / 2 if j % 2 else 0)
            y = y0 + j * step
            if corner == 'tr':
                dist = math.hypot(x0 + w - x, y - y0)
            elif corner == 'bl':
                dist = math.hypot(x - x0, y0 + h - y)
            else:
                dist = math.hypot(x - (x0 + w / 2), y - (y0 + h / 2)) * 0.9
            r = rmax * (1 - dist / (diag * 0.6))
            if r > 0.35:
                out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{fill}"/>')
    return ''.join(out)


def burst(cx, cy, r, n, fill, rot=0):
    out = []
    for i in range(n):
        a1 = math.radians(rot + 360 * i / n - 360 / n / 4)
        a2 = math.radians(rot + 360 * i / n + 360 / n / 4)
        out.append(f'<polygon points="{cx},{cy} {cx + r * math.cos(a1):.1f},{cy + r * math.sin(a1):.1f} '
                   f'{cx + r * math.cos(a2):.1f},{cy + r * math.sin(a2):.1f}" fill="{fill}"/>')
    return ''.join(out)


def emblem(s, x, y, r):
    c = RED_ if s in RED else INK
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="{PAPER}"/>' + suit(s, x, y, r * 1.25, c))


def ink(inner, w=2.4):
    return f'<g stroke="{INK}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round">{inner}</g>'


def atlas(s):
    g = GARMENT[s]
    return ink(
        f'<path d="M16 150 L 22 100 C 30 90 44 88 50 94 L 90 94 C 96 88 110 90 118 100 L 124 150 Z" fill="#23264A"/>'
        f'<path d="M2 150 C 6 118 26 104 50 100 L 90 100 C 114 104 134 118 138 150 Z" fill="{g}"/>'
        f'<ellipse cx="28" cy="112" rx="22" ry="15" fill="{STEEL}"/>'
        f'<ellipse cx="112" cy="112" rx="22" ry="15" fill="{STEEL}"/>'
        f'<path d="M14 108 C 22 102 34 102 42 108" fill="none" stroke="{STEEL_L}"/>'
        f'<path d="M98 108 C 106 102 118 102 126 108" fill="none" stroke="{STEEL_L}"/>'
        f'<rect x="62" y="84" width="16" height="18" fill="{SKIN}"/>'
        + emblem(s, 70, 130, 13) +
        f'<path d="M46 76 C 44 46 56 30 70 30 C 84 30 96 46 94 76 L 88 90 L 52 90 Z" fill="{STEEL}"/>'
        f'<path d="M52 72 C 50 52 58 40 66 36" fill="none" stroke="{STEEL_L}" stroke-width="3"/>'
        f'<path d="M54 70 L 86 70 L 84 84 C 78 94 62 94 56 84 Z" fill="{SKIN}"/>'
        f'<path d="M63 84 L 77 84" fill="none"/>'
        f'<path d="M50 55 L 90 55 L 88 68 L 52 68 Z" fill="{CYAN}"/>'
        f'<path d="M56 59 L 70 59" stroke="#FFFFFF" stroke-width="2"/>'
        f'<path d="M64 33 L 70 6 L 76 33 Z" fill="{g}"/>'
    ) + suit(s, 18, 22, 15, g)


def tayf(s):
    g = GARMENT[s]
    hair = '#6B2FA0'
    return ink(
        f'<path d="M40 60 C 26 92 24 124 16 150 L 124 150 C 116 124 114 92 100 60 C 96 26 44 26 40 60 Z" fill="{hair}"/>'
        f'<path d="M34 110 C 32 124 30 136 28 148" fill="none" stroke="#9A5BD0" stroke-width="3"/>'
        f'<path d="M8 150 C 14 122 32 108 52 104 L 88 104 C 108 108 126 122 132 150 Z" fill="{g}"/>'
        f'<rect x="62" y="84" width="16" height="18" fill="{SKIN}"/>'
        f'<path d="M54 98 L 86 98 L 90 110 L 50 110 Z" fill="{INK}"/>'
        + emblem(s, 70, 132, 12) +
        f'<ellipse cx="70" cy="70" rx="15" ry="19" fill="{SKIN}"/>'
        f'<path d="M52 64 C 50 42 60 34 72 34 C 86 34 92 46 90 64 C 84 54 76 50 68 52 C 62 54 56 58 52 64 Z" fill="{hair}"/>'
        f'<path d="M52 66 C 56 60 66 60 70 63 C 74 60 84 60 88 66 C 86 74 78 74 70 70 C 62 74 54 74 52 66 Z" fill="{g}"/>'
        f'<ellipse cx="62" cy="67" rx="4" ry="2.2" fill="#FFFFFF" stroke-width="1"/>'
        f'<ellipse cx="78" cy="67" rx="4" ry="2.2" fill="#FFFFFF" stroke-width="1"/>'
        f'<path d="M65 80 Q 70 83 75 80 Q 70 86 65 80 Z" fill="{RED_}" stroke-width="1.2"/>'
    ) + suit(s, 18, 22, 15, g)


def kivilcim(s):
    g = GARMENT[s]
    sc = ACCENT[s]
    return ink(
        f'<path d="M84 96 C 100 90 120 100 136 86 C 132 104 114 114 96 110 Z" fill="{sc}"/>'
        f'<path d="M6 150 C 12 122 30 110 52 106 L 88 106 C 110 110 128 122 134 150 Z" fill="{g}"/>'
        f'<path d="M70 110 L 70 150" fill="none"/>'
        f'<rect x="62" y="86" width="16" height="16" fill="{SKIN}"/>'
        f'<path d="M50 102 C 58 94 82 94 90 102 C 84 110 56 110 50 102 Z" fill="{sc}"/>'
        + emblem(s, 98, 132, 10) +
        f'<ellipse cx="70" cy="74" rx="14" ry="17" fill="{SKIN}"/>'
        f'<path d="M52 66 L 42 52 L 55 54 L 48 34 L 61 46 L 63 24 L 72 42 L 81 24 L 83 46 L 95 34 L 89 54 L 99 52 L 88 66 C 82 58 58 58 52 66 Z" fill="#FF7A1A"/>'
        f'<path d="M52 56 L 88 56" stroke-width="4"/>'
        f'<circle cx="61" cy="56" r="7" fill="{STEEL}"/><circle cx="79" cy="56" r="7" fill="{STEEL}"/>'
        f'<circle cx="61" cy="56" r="4" fill="{CYAN}" stroke-width="1"/><circle cx="79" cy="56" r="4" fill="{CYAN}" stroke-width="1"/>'
        f'<ellipse cx="64" cy="71" rx="1.8" ry="2.6" fill="{INK}" stroke-width="0"/>'
        f'<ellipse cx="76" cy="71" rx="1.8" ry="2.6" fill="{INK}" stroke-width="0"/>'
        f'<path d="M61 81 Q 70 91 79 81 Z" fill="#FFFFFF" stroke-width="1.6"/>'
    ) + suit(s, 18, 22, 15, g)


class CityDeck(Deck):
    id = 'sehir'
    name = 'Şehir Muhafızları'
    red = RED_
    black = INK
    font = GlyphFont('fonts/bangers-latin-400-normal.woff2')
    index_size = 54
    index_y = 56

    def face(self, rank, s):
        return (f'<rect x="0.5" y="0.5" width="249" height="349" rx="14" fill="{PAPER}" stroke="{INK}" stroke-width="1"/>'
                + halftone(170, 8, 72, 64, 7, 2.6, TINT[s], 'tr')
                + halftone(8, 278, 72, 64, 7, 2.6, TINT[s], 'bl') +
                f'<rect x="5" y="5" width="240" height="340" rx="11" fill="none" stroke="{INK}" stroke-width="3"/>')

    def pips(self, s, n):
        return pips(s, n, self.color(s), stroke=INK, sw=1.6)

    def court(self, rank, s):
        fig = {'K': atlas, 'Q': tayf, 'J': kivilcim}[rank](s)
        defs, body = court_frame(fig, f'clip-{rank}{s}')
        rays = (f'<g clip-path="url(#cb-{rank}{s})">'
                + burst(125, 96, 200, 18, '#FFFFFF') + burst(125, 254, 200, 18, '#FFFFFF')
                + halftone(56, 16, 138, 318, 9, 2.2, GARMENT[s], 'c') + '</g>')
        # clipPath tanımı defs'e taşınır
        cdef = f'<clipPath id="cb-{rank}{s}"><rect x="56" y="16" width="138" height="318" rx="6"/></clipPath>'
        bg = f'<rect x="56" y="16" width="138" height="318" rx="6" fill="{TINT[s]}"/>'
        border = (f'<rect x="56" y="16" width="138" height="318" rx="6" fill="none" stroke="{INK}" stroke-width="3"/>'
                  f'<path d="M56 175 L 194 175" stroke="{INK}" stroke-width="3"/>')
        return defs + cdef, bg + rays + body + border

    def ace(self, s):
        c = self.color(s)
        big = s == 'S'
        r1 = 96 if big else 86
        return (f'<polygon points="{star_points(CX, CY, r1, r1 * 0.7, 14)}" fill="{YEL}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
                + halftone(CX - 60, CY - 60, 120, 120, 8, 2.4, '#FF9F1C', 'c') +
                f'<circle cx="{CX}" cy="{CY}" r="{50 if big else 44}" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>'
                + suit(s, CX, CY, 74 if big else 64, c, stroke=INK, sw=2.4))

    def back(self):
        defs = '<clipPath id="bk"><rect x="10" y="10" width="230" height="330" rx="9"/></clipPath>'
        out = [f'<rect x="0" y="0" width="250" height="350" rx="14" fill="{INK}"/>',
               f'<g clip-path="url(#bk)"><rect x="0" y="0" width="250" height="350" fill="{BLUE}"/>'
               + burst(CX, CY, 260, 24, BLUE_D) + halftone(10, 10, 230, 330, 12, 3, '#3D5CF0', 'c') + '</g>',
               f'<rect x="10" y="10" width="230" height="330" rx="9" fill="none" stroke="{PAPER}" stroke-width="3"/>',
               f'<polygon points="{star_points(CX, CY, 78, 58, 12)}" fill="{YEL}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>',
               f'<circle cx="{CX}" cy="{CY}" r="48" fill="{PAPER}" stroke="{INK}" stroke-width="3"/>',
               suit('S', CX - 17, CY - 17, 28, INK), suit('H', CX + 17, CY - 17, 28, RED_, stroke=INK, sw=1.4),
               suit('D', CX - 17, CY + 17, 28, RED_, stroke=INK, sw=1.4), suit('C', CX + 17, CY + 17, 28, INK)]
        for (x, y) in ((40, 40), (210, 40), (40, 310), (210, 310)):
            out.append(f'<polygon points="{star_points(x, y, 13, 6, 5)}" fill="{YEL}" stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>')
        return defs, '\n'.join(out)
