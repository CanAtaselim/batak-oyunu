"""Osmanlı destesi: Padişah (K), Valide Sultan (Q), Yeniçeri (J). İznik çinisi renkleri."""
from common import *

GOLD = '#C9A227'
GOLD_D = '#8F6E14'
IVORY = '#FBF5E6'
CREAM = '#F3E7CC'
RED = '#A31F24'
NAVY = '#1D2A4D'
TURQ = '#1C8C8C'
EMER = '#2E6B3A'
SKIN = '#E9BD95'
SKIN_D = '#CF9B72'
BEARD = '#2A1A12'
WHITE = '#F8F3E7'
SHADE = '#D9CDB3'

GARMENT = {'S': NAVY, 'H': RED, 'D': TURQ, 'C': EMER}
LINING = {'S': '#3B5391', 'H': '#C8474B', 'D': '#43B0AE', 'C': '#4F9160'}

TULIP = ("M20 0 C 26 10 34 14 34 26 C 34 36 28 42 20 44 C 12 42 6 36 6 26 C 6 14 14 10 20 0 Z "
         "M6 18 C -2 26 -1 40 11 45 L 18 45 C 10 38 7 30 6 18 Z "
         "M34 18 C 42 26 41 40 29 45 L 22 45 C 30 38 33 30 34 18 Z "
         "M19 45 L 21 45 L 21 64 L 19 64 Z "
         "M20 60 C 12 58 6 52 4 46 C 12 48 17 52 20 58 Z "
         "M20 60 C 28 58 34 52 36 46 C 28 48 23 52 20 58 Z")


def tulip(x, y, h, fill, rot=0, opacity=None):
    k = h / 64
    op = f' opacity="{opacity}"' if opacity is not None else ''
    return (f'<path d="{TULIP}" fill="{fill}"{op} '
            f'transform="rotate({rot} {x} {y}) translate({x - 20 * k:.2f},{y - 32 * k:.2f}) scale({k:.4f})"/>')


def cintemani(x, y, r, fill):
    """Çintemani: üç benek (Osmanlı kumaş motifi)."""
    return (f'<circle cx="{x}" cy="{y - r}" r="{r}" fill="{fill}"/>'
            f'<circle cx="{x - r * 1.05}" cy="{y + r * 0.7}" r="{r}" fill="{fill}"/>'
            f'<circle cx="{x + r * 1.05}" cy="{y + r * 0.7}" r="{r}" fill="{fill}"/>')


# ------------------------------------------------------------------ figürler (140x150 yerel)
def kaftan(g, lining, s, narrow=False):
    sh = 8 if narrow else 0
    return (
        f'<path d="M{0 + sh} 150 L{0 + sh} 124 C {10 + sh} 104 {34 + sh} 96 50 93 L 90 93 '
        f'C {106 - sh} 96 {130 - sh} 104 {140 - sh} 124 L {140 - sh} 150 Z" fill="{g}"/>'
        # kürk/sırma yaka
        f'<path d="M40 95 C 52 112 62 128 70 146 C 78 128 88 112 100 95 L 90 93 '
        f'C 82 106 76 118 70 128 C 64 118 58 106 50 93 Z" fill="{GOLD}"/>'
        f'<path d="M50 93 L 70 128 L 90 93 Z" fill="{lining}"/>'
        f'<path d="M58 97 L 70 118 L 82 97" fill="none" stroke="{GOLD}" stroke-width="1.2"/>'
        + cintemani(22 + sh, 132, 3.2, GOLD) + cintemani(118 - sh, 132, 3.2, GOLD)
    )


def face(cx, cy, rx, ry, lashes=False, lips=None):
    out = (f'<rect x="{cx - 7}" y="{cy + ry - 8}" width="14" height="16" fill="{SKIN_D}"/>'
           f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{SKIN}"/>'
           f'<ellipse cx="{cx - rx - 1}" cy="{cy + 2}" rx="3" ry="5" fill="{SKIN_D}"/>'
           f'<ellipse cx="{cx + rx + 1}" cy="{cy + 2}" rx="3" ry="5" fill="{SKIN_D}"/>'
           f'<ellipse cx="{cx - 6}" cy="{cy - 3}" rx="2.4" ry="1.6" fill="{BEARD}"/>'
           f'<ellipse cx="{cx + 6}" cy="{cy - 3}" rx="2.4" ry="1.6" fill="{BEARD}"/>'
           f'<path d="M{cx - 10} {cy - 8} Q {cx - 6} {cy - 11} {cx - 2} {cy - 8}" fill="none" stroke="{BEARD}" stroke-width="1.4" stroke-linecap="round"/>'
           f'<path d="M{cx + 2} {cy - 8} Q {cx + 6} {cy - 11} {cx + 10} {cy - 8}" fill="none" stroke="{BEARD}" stroke-width="1.4" stroke-linecap="round"/>'
           f'<path d="M{cx} {cy - 2} L {cx - 2.5} {cy + 6} L {cx + 1} {cy + 6.5}" fill="none" stroke="{SKIN_D}" stroke-width="1.3" stroke-linecap="round"/>')
    if lashes:
        out += (f'<path d="M{cx - 9} {cy - 4} L {cx - 10.5} {cy - 6}" stroke="{BEARD}" stroke-width="1"/>'
                f'<path d="M{cx + 9} {cy - 4} L {cx + 10.5} {cy - 6}" stroke="{BEARD}" stroke-width="1"/>'
                f'<circle cx="{cx - 9}" cy="{cy + 6}" r="3.2" fill="#E07A6A" opacity="0.35"/>'
                f'<circle cx="{cx + 9}" cy="{cy + 6}" r="3.2" fill="#E07A6A" opacity="0.35"/>')
    if lips:
        out += f'<path d="M{cx - 4} {cy + 11} Q {cx} {cy + 14} {cx + 4} {cy + 11} Q {cx} {cy + 12} {cx - 4} {cy + 11} Z" fill="{lips}"/>'
    return out


def arch(fill):
    """Başın arkasında mihrap kemeri."""
    return (f'<path d="M22 150 L 22 70 C 22 40 44 18 70 8 C 96 18 118 40 118 70 L 118 150 Z" '
            f'fill="{fill}" opacity="0.13"/>')


def padisah(s):
    g, ln = GARMENT[s], LINING[s]
    return (
        arch(g) + kaftan(g, ln, s) +
        face(70, 70, 15, 19) +
        # sakal ve bıyık
        f'<path d="M55 70 C 55 90 62 102 70 104 C 78 102 85 90 85 70 C 81 78 76 82 70 82 C 64 82 59 78 55 70 Z" fill="{BEARD}"/>'
        f'<path d="M59 79 C 63 75 67 76 70 78 C 73 76 77 75 81 79 C 77 81 73 80 70 80 C 67 80 63 81 59 79 Z" fill="{BEARD}"/>'
        # kavuk
        f'<ellipse cx="70" cy="36" rx="34" ry="26" fill="{WHITE}"/>'
        f'<path d="M40 28 C 55 38 85 38 100 28" fill="none" stroke="{SHADE}" stroke-width="2"/>'
        f'<path d="M37 38 C 55 48 85 48 103 38" fill="none" stroke="{SHADE}" stroke-width="2"/>'
        f'<path d="M42 18 C 56 26 84 26 98 18" fill="none" stroke="{SHADE}" stroke-width="2"/>'
        f'<path d="M38 48 C 50 57 90 57 102 48 L 102 53 C 90 62 50 62 38 53 Z" fill="{GOLD}"/>'
        # sorguç
        f'<path d="M71 34 C 62 24 61 12 67 3 C 74 12 77 23 73 34 Z" fill="{WHITE}" stroke="{SHADE}" stroke-width="0.8"/>'
        f'<path d="M71 32 C 69 22 68 14 67 6" fill="none" stroke="{GOLD}" stroke-width="1"/>'
        f'<circle cx="71" cy="36" r="6" fill="{GOLD}"/><circle cx="71" cy="36" r="3" fill="{RED}"/>'
        + suit(s, 22, 22, 16, GARMENT[s])
    )


def valide(s):
    g, ln = GARMENT[s], LINING[s]
    pearls = ''.join(f'<circle cx="{70 + 17 * math.sin(t / 8 * 3.1416 - 1.57):.2f}" '
                     f'cy="{92 + 8 * math.cos(t / 8 * 3.1416 - 1.57):.2f}" r="2" fill="{WHITE}"/>'
                     for t in range(9))
    return (
        arch(g) +
        # saç
        f'<path d="M52 56 C 46 80 46 100 40 118 L 56 116 C 56 96 58 80 60 62 Z" fill="{BEARD}"/>'
        f'<path d="M88 56 C 94 80 94 100 100 118 L 84 116 C 84 96 82 80 80 62 Z" fill="{BEARD}"/>'
        + kaftan(g, ln, s, narrow=True) +
        face(70, 70, 14, 18, lashes=True, lips='#B23A3F') + pearls +
        # hotoz
        f'<path d="M52 56 L 55 18 C 58 8 82 8 85 18 L 88 56 Z" fill="{g}"/>'
        f'<path d="M54 30 L 86 30 M 53 42 L 87 42" stroke="{GOLD}" stroke-width="2"/>'
        f'<path d="M50 50 C 60 58 80 58 90 50 L 90 57 C 80 64 60 64 50 57 Z" fill="{GOLD}"/>'
        + ''.join(f'<circle cx="{x}" cy="54.5" r="1.8" fill="{RED}"/>' for x in (58, 66, 74, 82)) +
        # tül
        f'<path d="M55 20 C 36 44 30 86 16 132 L 30 134 C 38 98 46 62 58 34 Z" fill="{WHITE}" opacity="0.6"/>'
        f'<path d="M85 20 C 104 44 110 86 124 132 L 110 134 C 102 98 94 62 82 34 Z" fill="{WHITE}" opacity="0.6"/>'
        # sorguç
        f'<path d="M70 10 C 66 4 68 -2 74 -6 C 72 0 72 5 72 10 Z" fill="{WHITE}"/>'
        f'<circle cx="70" cy="12" r="4" fill="{GOLD}"/><circle cx="70" cy="12" r="2" fill="{TURQ}"/>'
        # küpeler
        f'<circle cx="55" cy="80" r="2.2" fill="{GOLD}"/><circle cx="85" cy="80" r="2.2" fill="{GOLD}"/>'
        + suit(s, 22, 22, 16, GARMENT[s])
    )


def yeniceri(s):
    g, ln = GARMENT[s], LINING[s]
    return (
        arch(g) +
        # börkün arkaya sarkan yatırtması
        f'<path d="M86 18 C 104 24 116 46 120 92 L 106 96 C 104 60 98 38 84 30 Z" fill="{WHITE}"/>'
        f'<path d="M92 30 C 104 42 110 60 112 92" fill="none" stroke="{SHADE}" stroke-width="2"/>'
        + kaftan(g, ln, s, narrow=True) +
        face(70, 76, 14, 17) +
        # kıvrık bıyık
        f'<path d="M70 86 C 64 82 56 82 50 86 C 48 84 46 80 47 77 C 50 83 58 80 64 81 C 67 81 69 82 70 83 '
        f'C 71 82 73 81 76 81 C 82 80 90 83 93 77 C 94 80 92 84 90 86 C 84 82 76 82 70 86 Z" fill="{BEARD}"/>'
        # börk
        f'<path d="M55 64 L 51 14 C 58 6 82 6 89 14 L 85 64 Z" fill="{WHITE}"/>'
        f'<path d="M58 60 L 55 18 M 82 60 L 85 18" stroke="{SHADE}" stroke-width="1.5"/>'
        f'<path d="M53 56 L 87 56 L 87 64 L 53 64 Z" fill="{GOLD}"/>'
        # kaşıklık
        f'<path d="M66 26 L 74 26 L 73 56 L 67 56 Z" fill="{GOLD}"/>'
        f'<path d="M70 16 L 75 23 L 70 30 L 65 23 Z" fill="{GOLD}"/>'
        f'<circle cx="70" cy="23" r="2" fill="{RED}"/>'
        + suit(s, 22, 22, 16, GARMENT[s])
    )


class OttomanDeck(Deck):
    id = 'osmanli'
    name = 'Osmanlı'
    red = RED
    black = NAVY
    font = GlyphFont('fonts/playfair-display-latin-900-normal.woff2')

    def face(self, rank, s):
        return (f'<rect x="0.5" y="0.5" width="249" height="349" rx="14" fill="{IVORY}" stroke="#D8C8A0" stroke-width="1"/>'
                f'<rect x="6" y="6" width="238" height="338" rx="10" fill="none" stroke="{GOLD}" stroke-width="1.3"/>'
                f'<rect x="9" y="9" width="232" height="332" rx="8" fill="none" stroke="{RED}" stroke-width="0.6" opacity="0.6"/>'
                + eight_star(226, 24, 7, GOLD) + eight_star(24, 326, 7, GOLD))

    def court(self, rank, s):
        fig = {'K': padisah, 'Q': valide, 'J': yeniceri}[rank](s)
        defs, body = court_frame(fig, f'clip-{rank}{s}')
        frame = (f'<rect x="56" y="16" width="138" height="318" rx="6" fill="{CREAM}"/>')
        border = (f'<rect x="56" y="16" width="138" height="318" rx="6" fill="none" stroke="{GOLD}" stroke-width="1.6"/>'
                  f'<path d="M56 175 L 194 175" stroke="{GOLD}" stroke-width="1.6"/>'
                  + eight_star(125, 175, 6, GOLD))
        return defs, frame + body + border

    def ace(self, s):
        c = self.color(s)
        big = s == 'S'
        r = 68 if big else 60
        out = [f'<circle cx="{CX}" cy="{CY}" r="{r}" fill="{CREAM}" stroke="{GOLD}" stroke-width="2"/>',
               rosette(CX, CY, r - 4, 16, GARMENT[s], opacity=0.16),
               f'<circle cx="{CX}" cy="{CY}" r="{r - 22}" fill="{IVORY}" stroke="{GOLD}" stroke-width="1"/>']
        for a in (0, 90, 180, 270):
            out.append(f'<g transform="rotate({a} {CX} {CY})">{tulip(CX, CY - r - 26, 40, GOLD)}</g>')
        if big:
            out += [f'<circle cx="{CX + (r + 8) * math.cos(t * 0.3927):.2f}" '
                    f'cy="{CY + (r + 8) * math.sin(t * 0.3927):.2f}" r="2.2" fill="{RED}"/>'
                    for t in range(16)]
        out.append(suit(s, CX, CY, 78 if big else 70, c, stroke=GOLD, sw=2))
        return '\n'.join(out)

    def back(self):
        defs = '<clipPath id="bk"><rect x="14" y="14" width="222" height="322" rx="6"/></clipPath>'
        out = [f'<rect x="0" y="0" width="250" height="350" rx="14" fill="{NAVY}"/>']
        stars = []
        for i in range(-1, 9):
            for j in range(-1, 12):
                x = 14 + i * 30 + (15 if j % 2 else 0)
                y = 14 + j * 30
                stars.append(eight_star(x, y, 8, GOLD, opacity=0.33))
                stars.append(f'<circle cx="{x}" cy="{y}" r="2" fill="{TURQ}"/>')
        out.append(f'<g clip-path="url(#bk)">{"".join(stars)}</g>')
        out += [f'<rect x="8" y="8" width="234" height="334" rx="10" fill="none" stroke="{GOLD}" stroke-width="2.4"/>',
                f'<rect x="14" y="14" width="222" height="322" rx="6" fill="none" stroke="{RED}" stroke-width="1.4"/>',
                f'<ellipse cx="{CX}" cy="{CY}" rx="72" ry="104" fill="#7E171C" stroke="{GOLD}" stroke-width="3"/>',
                f'<ellipse cx="{CX}" cy="{CY}" rx="64" ry="96" fill="none" stroke="{GOLD}" stroke-width="1" opacity="0.7"/>',
                rosette(CX, CY, 64, 12, GOLD, opacity=0.28),
                f'<circle cx="{CX}" cy="{CY}" r="36" fill="#7E171C" stroke="{GOLD}" stroke-width="1.5"/>',
                tulip(CX, CY - 2, 58, GOLD),
                tulip(CX, CY - 72, 34, GOLD, opacity=0.9),
                tulip(CX, CY + 72, 34, GOLD, rot=180, opacity=0.9)]
        return defs, '\n'.join(out)
