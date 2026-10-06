"""Ejder Diyarı: özgün fantastik deste. Dağ Kralı (K), Ay Büyücüsü (Q), Gölge Okçusu (J)."""
from common import *

PARCH = '#F2E8D0'
PARCH_D = '#E4D3AE'
BROWN = '#3B2A1A'
GOLD = '#C8963E'
GLOW = '#F2C14E'
SLATE = '#1E2A30'
SLATE_L = '#2B3B42'
EMBER = '#B3261E'
DARK = '#1F2A2E'
SKIN = '#E7B48F'
SKIN_D = '#C98C66'

GARMENT = {'S': '#2E3A59', 'H': '#8E1F2F', 'D': '#A8691A', 'C': '#2F5D46'}
GEM = {'S': '#6FA8FF', 'H': '#FF5A5A', 'D': '#FFD166', 'C': '#5EE6A0'}


def rune_ring(cx, cy, r_out, r_in, n, color, sw=1.4):
    """İki çember arasına rün benzeri çentikler."""
    out = [f'<circle cx="{cx}" cy="{cy}" r="{r_out}" fill="none" stroke="{color}" stroke-width="{sw * 1.3}"/>',
           f'<circle cx="{cx}" cy="{cy}" r="{r_in}" fill="none" stroke="{color}" stroke-width="{sw}"/>']
    for i in range(n):
        a = 360 * i / n
        m = (r_out + r_in) / 2
        h = (r_out - r_in) * 0.32
        kind = i % 4
        if kind == 0:
            d = f"M{cx} {cy - m - h} L {cx} {cy - m + h} M {cx - h * 0.6} {cy - m - h * 0.3} L {cx + h * 0.6} {cy - m + h * 0.3}"
        elif kind == 1:
            d = f"M{cx - h * 0.5} {cy - m + h} L {cx} {cy - m - h} L {cx + h * 0.5} {cy - m + h}"
        elif kind == 2:
            d = f"M{cx} {cy - m - h} L {cx} {cy - m + h} M {cx} {cy - m - h * 0.2} L {cx + h * 0.6} {cy - m - h * 0.8}"
        else:
            d = f"M{cx - h * 0.5} {cy - m} L {cx} {cy - m - h} L {cx + h * 0.5} {cy - m} L {cx} {cy - m + h} Z"
        out.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{sw}" stroke-linecap="round" '
                   f'transform="rotate({a:.1f} {cx} {cy})"/>')
    return ''.join(out)


def rune_diamond(x, y, r, color):
    return (f'<path d="M{x} {y - r} L {x + r * 0.7} {y} L {x} {y + r} L {x - r * 0.7} {y} Z" fill="none" stroke="{color}" stroke-width="1.3"/>'
            f'<path d="M{x} {y - r * 0.5} L {x} {y + r * 0.5}" stroke="{color}" stroke-width="1.3"/>')


def dag_krali(s):
    g = GARMENT[s]
    fur = ''.join(f'<circle cx="{x}" cy="{98 + (4 if i % 2 else 0)}" r="10" fill="#EFE6D3"/>'
                  for i, x in enumerate(range(16, 130, 14)))
    spots = ''.join(f'<ellipse cx="{x}" cy="{100 + (4 if i % 2 else 0)}" rx="1.6" ry="3" fill="{BROWN}"/>'
                    for i, x in enumerate(range(23, 126, 28)))
    return (
        f'<path d="M0 150 L 0 118 C 12 100 36 94 50 92 L 90 92 C 104 94 128 100 140 118 L 140 150 Z" fill="{g}"/>'
        f'<path d="M12 150 L 18 124 M 128 150 L 122 124" stroke="{GOLD}" stroke-width="2"/>'
        + fur + spots +
        f'<ellipse cx="70" cy="62" rx="15" ry="17" fill="{SKIN}"/>'
        f'<path d="M50 60 C 44 92 52 126 70 148 C 88 126 96 92 90 60 C 84 74 78 78 70 78 C 62 78 56 74 50 60 Z" fill="#BDB6AA"/>'
        f'<path d="M62 84 C 62 104 64 120 68 138 M 78 84 C 78 104 76 120 72 138 M 70 82 L 70 142" stroke="#9D958A" stroke-width="1.5" fill="none"/>'
        f'<rect x="61" y="118" width="18" height="5" rx="2" fill="{GOLD}"/>'
        f'<rect x="64" y="132" width="12" height="4" rx="2" fill="{GOLD}"/>'
        f'<path d="M54 74 C 60 68 66 70 70 72 C 74 70 80 68 86 74 C 80 78 74 76 70 76 C 66 76 60 78 54 74 Z" fill="#A69E92"/>'
        f'<ellipse cx="70" cy="66" rx="5" ry="6" fill="{SKIN_D}"/>'
        f'<path d="M56 55 L 67 57 M 84 55 L 73 57" stroke="#A69E92" stroke-width="3.5" stroke-linecap="round"/>'
        f'<circle cx="63" cy="60" r="1.8" fill="{BROWN}"/><circle cx="77" cy="60" r="1.8" fill="{BROWN}"/>'
        f'<path d="M48 48 L 50 26 L 58 40 L 64 18 L 70 36 L 76 18 L 82 40 L 90 26 L 92 48 Z" fill="{GOLD}"/>'
        f'<path d="M48 45 L 92 45 L 93 54 L 47 54 Z" fill="#A87A2C"/>'
        f'<circle cx="70" cy="49.5" r="4" fill="{GEM[s]}" stroke="{BROWN}" stroke-width="0.8"/>'
        f'<path d="M54 47 L 56 52 M 59 47 L 58 52 M 82 47 L 84 52 M 86 47 L 85 52" stroke="{BROWN}" stroke-width="1"/>'
        + suit(s, 18, 22, 15, g)
    )


def ay_buyucusu(s):
    g = GARMENT[s]
    hair = '#DCE3F0'
    return (
        f'<path d="M44 50 C 30 80 28 120 22 150 L 118 150 C 112 120 110 80 96 50 C 92 26 48 26 44 50 Z" fill="{hair}"/>'
        f'<path d="M36 100 C 34 118 32 134 30 148 M 104 100 C 106 118 108 134 110 148" stroke="#B8C3D8" stroke-width="2" fill="none"/>'
        f'<path d="M10 150 C 14 122 32 108 52 104 L 88 104 C 108 108 126 122 130 150 Z" fill="{g}"/>'
        f'<path d="M52 108 C 38 94 34 80 38 66 L 60 100 Z" fill="{g}" stroke="{GOLD}" stroke-width="1.5"/>'
        f'<path d="M88 108 C 102 94 106 80 102 66 L 80 100 Z" fill="{g}" stroke="{GOLD}" stroke-width="1.5"/>'
        f'<rect x="63" y="82" width="14" height="20" fill="#E7BFA0"/>'
        f'<circle cx="70" cy="118" r="6" fill="{GEM[s]}" stroke="{GOLD}" stroke-width="2"/>'
        f'<path d="M56 66 L 40 50 L 57 76 Z" fill="#F1CDB0"/><path d="M84 66 L 100 50 L 83 76 Z" fill="#F1CDB0"/>'
        f'<ellipse cx="70" cy="68" rx="13" ry="18" fill="#F1CDB0"/>'
        f'<path d="M54 60 C 54 40 62 34 70 34 C 78 34 86 40 86 60 C 80 50 74 47 70 47 C 66 47 60 50 54 60 Z" fill="{hair}"/>'
        f'<path d="M60 67 Q 64 64 68 67 Q 64 68.5 60 67 Z M 72 67 Q 76 64 80 67 Q 76 68.5 72 67 Z" fill="#2B2F45"/>'
        f'<path d="M66 79 Q 70 81.5 74 79 Q 70 83 66 79 Z" fill="#B24A5A"/>'
        f'<path d="M56 55 C 62 51 78 51 84 55" fill="none" stroke="{GOLD}" stroke-width="2.4"/>'
        f'<path d="M70 38 A 8 8 0 1 0 70 54 A 6 6 0 1 1 70 38 Z" fill="{GLOW}" stroke="{GOLD}" stroke-width="0.8"/>'
        + suit(s, 18, 22, 15, g)
    )


def golge_okcusu(s):
    g = GARMENT[s]
    cloak = '#2E3B32'
    return (
        f'<path d="M22 150 C 8 100 28 40 78 12" fill="none" stroke="#6B4423" stroke-width="4.5" stroke-linecap="round"/>'
        f'<path d="M22 150 L 78 12" stroke="#D8CFC0" stroke-width="0.8"/>'
        + ''.join(f'<path d="M{100 + i * 6} 104 L {110 + i * 6} {36 + i * 4}" stroke="#8B6A45" stroke-width="2"/>'
                  f'<path d="M{110 + i * 6} {36 + i * 4} l -4 8 l 8 -2 Z" fill="{EMBER if i == 1 else "#E8E0D0"}"/>'
                  for i in range(3)) +
        f'<path d="M4 150 C 8 120 30 106 50 102 L 90 102 C 110 106 132 120 136 150 Z" fill="{cloak}"/>'
        f'<path d="M56 104 L 70 138 L 84 104 Z" fill="{g}"/>'
        f'<path d="M36 112 L 110 146" stroke="#6B4423" stroke-width="5"/>'
        f'<path d="M42 100 C 34 66 44 30 70 20 C 96 30 106 66 98 100 L 86 100 C 88 80 84 60 70 56 C 56 60 52 80 54 100 Z" fill="#26332B"/>'
        f'<ellipse cx="70" cy="80" rx="14" ry="18" fill="{SKIN}"/>'
        f'<path d="M54 76 C 54 60 62 55 70 55 C 78 55 86 60 86 76 C 80 70 60 70 54 76 Z" fill="#141C17" opacity="0.85"/>'
        f'<ellipse cx="64" cy="77" rx="2.6" ry="1.5" fill="{GLOW}"/><ellipse cx="76" cy="77" rx="2.6" ry="1.5" fill="{GLOW}"/>'
        f'<path d="M64 90 Q 70 92 76 90" stroke="{SKIN_D}" stroke-width="1.4" fill="none"/>'
        f'<circle cx="70" cy="104" r="6" fill="{GOLD}"/><circle cx="70" cy="104" r="3.2" fill="{GEM[s]}"/>'
        + suit(s, 18, 22, 15, g)
    )


class FantasyDeck(Deck):
    id = 'ejder'
    name = 'Ejder Diyarı'
    red = EMBER
    black = DARK
    font = GlyphFont('fonts/cinzel-latin-900-normal.woff2')
    index_size = 44
    index_y = 52

    def defs(self):
        return (f'<radialGradient id="parch" cx="50%" cy="50%" r="70%">'
                f'<stop offset="0" stop-color="#F8F0DC"/><stop offset="1" stop-color="{PARCH_D}"/></radialGradient>'
                f'<radialGradient id="glow" cx="50%" cy="50%" r="50%">'
                f'<stop offset="0" stop-color="{GLOW}" stop-opacity="0.75"/><stop offset="1" stop-color="{GLOW}" stop-opacity="0"/></radialGradient>'
                f'<radialGradient id="eye" cx="50%" cy="50%" r="55%">'
                f'<stop offset="0" stop-color="#FFE08A"/><stop offset="0.6" stop-color="#F0A020"/><stop offset="1" stop-color="#9C4A0C"/></radialGradient>'
                f'<radialGradient id="vign" cx="50%" cy="50%" r="75%">'
                f'<stop offset="0" stop-color="{SLATE_L}"/><stop offset="1" stop-color="#11181C"/></radialGradient>')

    def face(self, rank, s):
        return (f'<rect x="0.5" y="0.5" width="249" height="349" rx="14" fill="url(#parch)" stroke="{BROWN}" stroke-width="1"/>'
                f'<rect x="6" y="6" width="238" height="338" rx="10" fill="none" stroke="{BROWN}" stroke-width="1.8"/>'
                f'<rect x="10" y="10" width="230" height="330" rx="7" fill="none" stroke="{GOLD}" stroke-width="0.8"/>'
                + rune_diamond(226, 26, 9, GOLD) + rune_diamond(24, 324, 9, GOLD))

    def court(self, rank, s):
        fig = {'K': dag_krali, 'Q': ay_buyucusu, 'J': golge_okcusu}[rank](s)
        defs, body = court_frame(fig, f'clip-{rank}{s}')
        bg = (f'<rect x="56" y="16" width="138" height="318" rx="6" fill="{PARCH_D}"/>'
              + rune_ring(125, 96, 60, 50, 20, GOLD, 1.1) + rune_ring(125, 254, 60, 50, 20, GOLD, 1.1))
        cdef = f'<clipPath id="cb-{rank}{s}"><rect x="56" y="16" width="138" height="318" rx="6"/></clipPath>'
        bg = f'<g clip-path="url(#cb-{rank}{s})">{bg}</g>'
        border = (f'<rect x="56" y="16" width="138" height="318" rx="6" fill="none" stroke="{BROWN}" stroke-width="2"/>'
                  f'<path d="M56 175 L 194 175" stroke="{BROWN}" stroke-width="2"/>'
                  + f'<path d="M{CX} 168 L {CX + 6} 175 L {CX} 182 L {CX - 6} 175 Z" fill="{GOLD}" stroke="{BROWN}" stroke-width="1"/>')
        return defs + cdef, bg + body + border

    def ace(self, s):
        c = self.color(s)
        big = s == 'S'
        out = [f'<circle cx="{CX}" cy="{CY}" r="{56 if big else 50}" fill="url(#glow)"/>',
               rune_ring(CX, CY, 74 if big else 66, 60 if big else 54, 24, GOLD, 1.5)]
        if big:
            for a in (0, 90, 180, 270):
                out.append(f'<g transform="rotate({a} {CX} {CY})"><path d="M{CX} {CY - 96} L {CX + 7} {CY - 80} L {CX} {CY - 76} L {CX - 7} {CY - 80} Z" fill="{GOLD}" stroke="{BROWN}" stroke-width="1"/></g>')
        out.append(suit(s, CX, CY, 76 if big else 66, c, stroke=GOLD, sw=2.2))
        return '\n'.join(out)

    def back(self):
        defs = '<clipPath id="bk"><rect x="12" y="12" width="226" height="326" rx="8"/></clipPath>'
        scales = []
        for j in range(0, 24):
            for i in range(-1, 12):
                x = 12 + i * 22 + (11 if j % 2 else 0)
                y = 12 + j * 14
                scales.append(f'<path d="M{x - 11} {y} A 11 11 0 0 0 {x + 11} {y}" fill="none" stroke="#34474F" stroke-width="1.2"/>')
        cx, cy = CX, CY
        out = [f'<rect x="0" y="0" width="250" height="350" rx="14" fill="#11181C"/>',
               f'<g clip-path="url(#bk)"><rect x="0" y="0" width="250" height="350" fill="url(#vign)"/>{"".join(scales)}</g>',
               f'<rect x="7" y="7" width="236" height="336" rx="11" fill="none" stroke="{GOLD}" stroke-width="2"/>',
               f'<rect x="12" y="12" width="226" height="326" rx="8" fill="none" stroke="{GOLD}" stroke-width="0.8" opacity="0.7"/>',
               f'<circle cx="{cx}" cy="{cy}" r="86" fill="#11181C" opacity="0.6"/>',
               rune_ring(cx, cy, 86, 70, 28, GOLD, 1.6),
               f'<circle cx="{cx}" cy="{cy}" r="64" fill="url(#glow)" opacity="0.5"/>',
               f'<path d="M{cx - 62} {cy} C {cx - 34} {cy - 40} {cx + 34} {cy - 40} {cx + 62} {cy} '
               f'C {cx + 34} {cy + 40} {cx - 34} {cy + 40} {cx - 62} {cy} Z" fill="url(#eye)" stroke="#0B0F12" stroke-width="3"/>',
               f'<ellipse cx="{cx}" cy="{cy}" rx="7" ry="27" fill="#120D08"/>',
               f'<ellipse cx="{cx - 14}" cy="{cy - 12}" rx="6" ry="3.5" fill="#FFF6D8" opacity="0.8"/>']
        for (x, y) in ((cx, 40), (cx, 310)):
            out.append(rune_diamond(x, y, 12, GOLD))
        return defs, '\n'.join(out)
