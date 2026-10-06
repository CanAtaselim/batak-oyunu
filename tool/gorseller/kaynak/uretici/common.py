"""Ortak yardımcılar: font glifi -> SVG path, tür sembolleri, pip yerleşimi, kart montajı.

Üretilen SVG'ler Flutter (flutter_svg / vector_graphics) ile uyumlu olacak şekilde sade tutulur:
<text>, <filter>, <pattern>, <mask> kullanılmaz. Sadece path/circle/ellipse/rect/polygon,
linear/radial gradient, clipPath, transform ve opacity.
"""
import math
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

W, H = 250, 350          # kart viewBox
CX, CY = W / 2, H / 2
RANKS = ['A', 'K', 'Q', 'J', '10', '9', '8', '7', '6', '5', '4', '3', '2']
SUITS = ['S', 'H', 'D', 'C']   # maça, kupa, karo, sinek
RED = {'H', 'D'}


# ---------------------------------------------------------------- font -> path
class GlyphFont:
    def __init__(self, path):
        self.font = TTFont(path)
        self.gs = self.font.getGlyphSet()
        self.cmap = self.font.getBestCmap()
        self.upm = self.font['head'].unitsPerEm
        self.hmtx = self.font['hmtx']
        self.names = set(self.font.getGlyphOrder())

    def glyph(self, ch):
        g = self.cmap[ord(ch)]
        return g + '.lf' if g + '.lf' in self.names else g   # rakamlarda hizalı (lining) biçim

    def width(self, text, size, sx=1.0):
        sc = size / self.upm
        return sum(self.hmtx[self.glyph(ch)][0] for ch in text) * sc * sx

    def bounds(self, text, size, sx=1.0):
        """Metnin (x=0 başlangıç, y=0 taban) mürekkep sınırları: (xmin, ymin, xmax, ymax), SVG yönünde."""
        from fontTools.pens.boundsPen import BoundsPen
        sc = size / self.upm
        cur, box = 0.0, None
        for ch in text:
            g = self.glyph(ch)
            bp = BoundsPen(self.gs)
            self.gs[g].draw(TransformPen(bp, (sc * sx, 0, 0, -sc, cur, 0)))
            if bp.bounds:
                b = bp.bounds
                box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
            cur += self.hmtx[g][0] * sc * sx
        return box

    def fit_path(self, text, size, cx, y, max_w, sx=1.0):
        """Mürekkep genişliği max_w'yi aşmayacak ve cx'e ortalanacak şekilde metin."""
        b = self.bounds(text, size, sx)
        w = b[2] - b[0]
        if w > max_w:
            sx *= max_w / w
            b = self.bounds(text, size, sx)
        x0 = cx - (b[0] + b[2]) / 2
        return self.path(text, size, x0, y, anchor='start', sx=sx)

    def path(self, text, size, x, y, anchor='middle', sx=1.0, tracking=0.0):
        """Metni path 'd' olarak döndürür. (x, y) = taban çizgisi; anchor middle/start/end."""
        sc = size / self.upm
        total = self.width(text, size, sx) + tracking * (len(text) - 1)
        if anchor == 'middle':
            x0 = x - total / 2
        elif anchor == 'end':
            x0 = x - total
        else:
            x0 = x
        d = []
        cur = x0
        for ch in text:
            g = self.glyph(ch)
            pen = SVGPathPen(self.gs)
            tpen = TransformPen(pen, (sc * sx, 0, 0, -sc, cur, y))
            self.gs[g].draw(tpen)
            d.append(pen.getCommands())
            cur += self.hmtx[g][0] * sc * sx + tracking
        return ' '.join(d)


# ---------------------------------------------------------------- tür sembolleri (100x100 kutu)
SUIT_D = {
    'H': "M50 90 C 22 68 4 50 4 31 C 4 15 16 5 29 5 C 39 5 46 11 50 19 "
         "C 54 11 61 5 71 5 C 84 5 96 15 96 31 C 96 50 78 68 50 90 Z",
    'D': "M50 3 C 59 21 73 37 91 50 C 73 63 59 79 50 97 C 41 79 27 63 9 50 C 27 37 41 21 50 3 Z",
    'S': "M50 3 C 61 20 95 38 95 61 C 95 75 85 83 73 83 C 64 83 57 79 53.5 72 "
         "C 54.5 82 58.5 90 67 96 L 33 96 C 41.5 90 45.5 82 46.5 72 "
         "C 43 79 36 83 27 83 C 15 83 5 75 5 61 C 5 38 39 20 50 3 Z",
    'C': "M50 7 A 20 20 0 1 1 49.9 7 Z "
         "M28 38 A 20 20 0 1 1 27.9 38 Z "
         "M72 38 A 20 20 0 1 1 71.9 38 Z "
         "M50 44 A 11 11 0 1 1 49.9 44 Z "
         "M46.5 60 C 46.5 76 42 88 33 96 L 67 96 C 58 88 53.5 76 53.5 60 Z",
}


def suit_d(s):
    return SUIT_D[s]


def suit(s, cx, cy, size, fill, rot=False, stroke=None, sw=0, opacity=None):
    k = size / 100
    tr = f"translate({cx - size / 2:.2f},{cy - size / 2:.2f}) scale({k:.4f})"
    if rot:
        tr = f"rotate(180 {cx:.2f} {cy:.2f}) " + tr
    extra = ''
    if stroke:
        extra += f' stroke="{stroke}" stroke-width="{sw / k:.2f}" stroke-linejoin="round"'
    if opacity is not None:
        extra += f' opacity="{opacity}"'
    return f'<path d="{SUIT_D[s]}" fill="{fill}" transform="{tr}"{extra}/>'


# ---------------------------------------------------------------- pip yerleşimi
L, M_, R = 82, 125, 168
T, B = 78, 272


def pip_positions(n):
    mid = (T + B) / 2
    if n == 2:
        return [(M_, T), (M_, B)]
    if n == 3:
        return [(M_, T), (M_, mid), (M_, B)]
    if n == 4:
        return [(L, T), (R, T), (L, B), (R, B)]
    if n == 5:
        return pip_positions(4) + [(M_, mid)]
    if n == 6:
        return pip_positions(4) + [(L, mid), (R, mid)]
    if n == 7:
        return pip_positions(6) + [(M_, (T + mid) / 2)]
    if n == 8:
        return pip_positions(6) + [(M_, (T + mid) / 2), (M_, (mid + B) / 2)]
    step = (B - T) / 3
    rows = [T, T + step, T + 2 * step, B]
    side = [(x, y) for y in rows for x in (L, R)]
    if n == 9:
        return side + [(M_, mid)]
    if n == 10:
        return side + [(M_, T + step / 2), (M_, B - step / 2)]
    raise ValueError(n)


def pips(s, n, color, size=None, **kw):
    size = size or (38 if n >= 9 else 42)
    out = []
    for (x, y) in pip_positions(n):
        out.append(suit(s, x, y, size, color, rot=y > CY + 1, **kw))
    return '\n'.join(out)


# ---------------------------------------------------------------- yardımcı şekiller
def rosette(cx, cy, r, n, fill, petal_w=None, opacity=None, rot0=0.0):
    """n yapraklı gül/rozet: merkezden dışa elipsler."""
    pw = petal_w or r * 0.28
    op = f' opacity="{opacity}"' if opacity is not None else ''
    out = []
    for i in range(n):
        a = rot0 + 360 * i / n
        out.append(f'<ellipse cx="{cx:.2f}" cy="{cy - r / 2:.2f}" rx="{pw:.2f}" ry="{r / 2:.2f}" '
                   f'fill="{fill}" transform="rotate({a:.2f} {cx:.2f} {cy:.2f})"{op}/>')
    return '\n'.join(out)


def star_points(cx, cy, r1, r2, n, rot0=-90):
    pts = []
    for i in range(2 * n):
        r = r1 if i % 2 == 0 else r2
        a = math.radians(rot0 + 180 * i / n)
        pts.append(f"{cx + r * math.cos(a):.2f},{cy + r * math.sin(a):.2f}")
    return ' '.join(pts)


def eight_star(cx, cy, r, fill, opacity=None, stroke=None, sw=0):
    """İki karenin üst üste binmesiyle 8 köşeli yıldız (Selçuklu/Osmanlı motifi)."""
    op = f' opacity="{opacity}"' if opacity is not None else ''
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ''
    s = r * 0.7071
    sq = f"{cx - s:.2f},{cy - s:.2f} {cx + s:.2f},{cy - s:.2f} {cx + s:.2f},{cy + s:.2f} {cx - s:.2f},{cy + s:.2f}"
    dm = f"{cx:.2f},{cy - r:.2f} {cx + r:.2f},{cy:.2f} {cx:.2f},{cy + r:.2f} {cx - r:.2f},{cy:.2f}"
    return (f'<polygon points="{sq}" fill="{fill}"{op}{st}/>'
            f'<polygon points="{dm}" fill="{fill}"{op}{st}/>')


def circle_path(cx, cy, r):
    return f"M{cx - r:.2f} {cy:.2f} A {r:.2f} {r:.2f} 0 1 0 {cx + r:.2f} {cy:.2f} A {r:.2f} {r:.2f} 0 1 0 {cx - r:.2f} {cy:.2f} Z"


# ---------------------------------------------------------------- kart montajı
def svg_doc(body, w=W, h=H, defs=''):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
            f'<defs>{defs}</defs>{body}</svg>')


class Deck:
    """Her deste bunu genişletir."""
    id = 'base'
    name = 'Base'
    red = '#C00'
    black = '#111'
    font = None
    index_size = 46
    index_y = 54
    index_suit_y = 76
    index_suit_size = 25
    index_x = 30
    index_sx = {}
    index_max_w = 40

    def color(self, s):
        return self.red if s in RED else self.black

    # -- alt sınıfların doldurduğu parçalar
    def defs(self):
        return ''

    def face(self, rank, s):
        raise NotImplementedError

    def ace(self, s):
        return suit(s, CX, CY, 120, self.color(s))

    def court(self, rank, s):
        raise NotImplementedError

    def pips(self, s, n):
        return pips(s, n, self.color(s))

    def back(self):
        raise NotImplementedError

    def index_extra(self, rank, s):
        return ''

    # -- montaj
    def index(self, rank, s):
        c = self.color(s)
        sx = 0.74 if rank == '10' else self.index_sx.get(rank, 1.0)
        d = self.font.fit_path(rank, self.index_size, self.index_x, self.index_y, self.index_max_w, sx=sx)
        one = (f'<path d="{d}" fill="{c}"/>' +
               suit(s, self.index_x, self.index_suit_y, self.index_suit_size, c))
        return (f'<g>{one}</g><g transform="rotate(180 {CX} {CY})">{one}</g>' +
                self.index_extra(rank, s))

    def card(self, rank, s):
        extra_defs = []
        body = [self.face(rank, s)]
        if rank == 'A':
            body.append(self.ace(s))
        elif rank in ('K', 'Q', 'J'):
            res = self.court(rank, s)
            if isinstance(res, tuple):
                extra_defs.append(res[0]); res = res[1]
            body.append(res)
        else:
            body.append(self.pips(s, int(rank)))
        body.append(self.index(rank, s))
        return svg_doc('\n'.join(body), defs=self.defs() + ''.join(extra_defs))

    def back_svg(self):
        res = self.back()
        extra = ''
        if isinstance(res, tuple):
            extra, res = res
        return svg_doc(res, defs=self.defs() + extra)


def court_frame(fig_svg, clip_id, x0=56, y0=16, x1=194, y1=334, fig_w=140, anchor_y=142, zoom=1.12):
    """Yarım figürü üst yarıya çizer, 180° döndürüp alt yarıya kopyalar (çift başlı kart).
    Figür 140 genişlikte yerel koordinatlarda çizilir; yerel anchor_y satırı kartın ortasına oturur."""
    k = (x1 - x0) / fig_w * zoom
    tx = CX - fig_w / 2 * k
    ty = CY - anchor_y * k
    defs = (f'<clipPath id="{clip_id}"><rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{CY - y0}" rx="6"/></clipPath>')
    half = (f'<g clip-path="url(#{clip_id})"><g transform="translate({tx:.2f},{ty:.2f}) scale({k:.4f})">'
            f'{fig_svg}</g></g>')
    body = f'{half}<g transform="rotate(180 {CX} {CY})">{half}</g>'
    return defs, body
