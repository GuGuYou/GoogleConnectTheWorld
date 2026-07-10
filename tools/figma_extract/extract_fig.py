#!/usr/bin/env python3
"""Decode a local Figma .fig export into JSON + per-frame design specs.

Usage:
    python extract_fig.py "path/to/file.fig" [--out out] [--specs]

Pipeline:
    .fig (ZIP) -> canvas.fig (fig-kiwi container)
        chunk0: raw-deflate compressed kiwi binary schema (embedded in file)
        chunk1: zstd (or raw-deflate) compressed kiwi-encoded `Message`
    -> out/canvas.json        full node tree (nodeChanges reparented by GUID)
    -> out/images/<sha>.png   embedded raster assets with proper extensions
    -> out/image_manifest.json  image hash -> referencing node names
    -> out/specs/<frame>.json + out/specs/spec_summary.md  (--specs)

Kiwi format reference: https://github.com/evanw/kiwi (binary schema + data
encoding). Unknown/undecodable constructs are logged and skipped, never fatal.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import zipfile
import zlib
from collections import Counter, defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Kiwi primitives
# ---------------------------------------------------------------------------

class ByteBuffer:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def eof(self) -> bool:
        return self.pos >= len(self.data)

    def read_byte(self) -> int:
        b = self.data[self.pos]
        self.pos += 1
        return b

    def read_bytes(self, n: int) -> bytes:
        out = self.data[self.pos:self.pos + n]
        if len(out) != n:
            raise EOFError('unexpected end of buffer')
        self.pos += n
        return out

    def read_var_uint(self) -> int:
        value = 0
        shift = 0
        while True:
            b = self.read_byte()
            value |= (b & 127) << shift
            shift += 7
            if not (b & 128) or shift >= 35:
                break
        return value & 0xFFFFFFFF

    def read_var_int(self) -> int:
        v = self.read_var_uint()
        value = (v >> 1) ^ -(v & 1)
        # wrap to signed 32
        value &= 0xFFFFFFFF
        return value - 0x100000000 if value >= 0x80000000 else value

    def read_var_uint64(self) -> int:
        value = 0
        shift = 0
        while True:
            b = self.read_byte()
            if shift == 56:
                value |= b << shift
                break
            value |= (b & 127) << shift
            if not (b & 128):
                break
            shift += 7
        return value

    def read_var_int64(self) -> int:
        v = self.read_var_uint64()
        return (v >> 1) ^ -(v & 1)

    def read_var_float(self) -> float:
        first = self.data[self.pos]
        if first == 0:
            self.pos += 1
            return 0.0
        bits = struct.unpack_from('<I', self.data, self.pos)[0]
        self.pos += 4
        # kiwi rotates the exponent byte to the front for the zero shortcut
        bits = ((bits << 23) | (bits >> 9)) & 0xFFFFFFFF
        return struct.unpack('<f', struct.pack('<I', bits))[0]

    def read_string(self) -> str:
        end = self.data.index(b'\x00', self.pos)
        s = self.data[self.pos:end].decode('utf-8', errors='replace')
        self.pos = end + 1
        return s

    def read_byte_array(self) -> bytes:
        return self.read_bytes(self.read_var_uint())


# ---------------------------------------------------------------------------
# Kiwi binary schema
# ---------------------------------------------------------------------------

BUILTIN_TYPES = {
    -1: 'bool', -2: 'byte', -3: 'int', -4: 'uint',
    -5: 'float', -6: 'string', -7: 'int64', -8: 'uint64',
}
KINDS = {0: 'ENUM', 1: 'STRUCT', 2: 'MESSAGE'}


def decode_binary_schema(data: bytes) -> dict:
    bb = ByteBuffer(data)
    count = bb.read_var_uint()
    definitions = []
    for _ in range(count):
        name = bb.read_string()
        kind = KINDS[bb.read_byte()]
        field_count = bb.read_var_uint()
        fields = []
        for _ in range(field_count):
            fname = bb.read_string()
            ftype = bb.read_var_int()
            is_array = bool(bb.read_byte() & 1)
            value = bb.read_var_uint()
            fields.append({'name': fname, 'type': ftype,
                           'isArray': is_array, 'value': value})
        definitions.append({'name': name, 'kind': kind, 'fields': fields})
    # resolve type indices to names
    for d in definitions:
        for f in d['fields']:
            t = f['type']
            if d['kind'] == 'ENUM':
                f['typeName'] = None
            elif t in BUILTIN_TYPES:
                f['typeName'] = BUILTIN_TYPES[t]
            else:
                f['typeName'] = definitions[t]['name']
    return {d['name']: d for d in definitions}


# ---------------------------------------------------------------------------
# Kiwi data decoding (schema-driven, defensive)
# ---------------------------------------------------------------------------

class KiwiDecoder:
    def __init__(self, schema: dict):
        self.schema = schema
        self.warnings = Counter()

    def decode(self, type_name: str, bb: ByteBuffer):
        d = self.schema[type_name]
        if d['kind'] == 'ENUM':
            v = bb.read_var_uint()
            for f in d['fields']:
                if f['value'] == v:
                    return f['name']
            self.warnings[f'unknown enum value {type_name}={v}'] += 1
            return v
        if d['kind'] == 'STRUCT':
            return {f['name']: self.decode_field(f, bb) for f in d['fields']}
        # MESSAGE: sequence of (field id, value) pairs terminated by 0
        obj = {}
        by_id = {f['value']: f for f in d['fields']}
        while True:
            fid = bb.read_var_uint()
            if fid == 0:
                return obj
            f = by_id.get(fid)
            if f is None:
                # cannot skip unknown message fields safely
                raise ValueError(f'unknown field id {fid} in {type_name}')
            obj[f['name']] = self.decode_field(f, bb)

    def decode_field(self, f: dict, bb: ByteBuffer):
        t = f['typeName']
        if f['isArray']:
            if t == 'byte':
                return bb.read_byte_array()
            return [self.decode_value(t, bb) for _ in range(bb.read_var_uint())]
        return self.decode_value(t, bb)

    def decode_value(self, t: str, bb: ByteBuffer):
        if t == 'bool':
            return bb.read_byte() != 0
        if t == 'byte':
            return bb.read_byte()
        if t == 'int':
            return bb.read_var_int()
        if t == 'uint':
            return bb.read_var_uint()
        if t == 'float':
            return bb.read_var_float()
        if t == 'string':
            return bb.read_string()
        if t == 'int64':
            return bb.read_var_int64()
        if t == 'uint64':
            return bb.read_var_uint64()
        return self.decode(t, bb)


# ---------------------------------------------------------------------------
# fig-kiwi container
# ---------------------------------------------------------------------------

ZSTD_MAGIC = b'\x28\xb5\x2f\xfd'


def read_fig_chunks(canvas: bytes) -> tuple[int, list[bytes]]:
    if canvas[:8] != b'fig-kiwi':
        raise ValueError('not a fig-kiwi file')
    version = struct.unpack_from('<I', canvas, 8)[0]
    chunks = []
    off = 12
    while off + 4 <= len(canvas):
        size = struct.unpack_from('<I', canvas, off)[0]
        off += 4
        chunks.append(canvas[off:off + size])
        off += size
    return version, chunks


def decompress_chunk(chunk: bytes) -> bytes:
    if chunk[:4] == ZSTD_MAGIC:
        import zstandard
        return zstandard.ZstdDecompressor().decompress(
            chunk, max_output_size=512 * 1024 * 1024)
    return zlib.decompress(chunk, -15)


# ---------------------------------------------------------------------------
# JSON helpers
# ---------------------------------------------------------------------------

def jsonable(value):
    if isinstance(value, bytes):
        if len(value) <= 64:
            return {'__hex__': value.hex()}
        return {'__bytes_len__': len(value)}
    if isinstance(value, dict):
        return {k: jsonable(v) for k, v in value.items()}
    if isinstance(value, list):
        return [jsonable(v) for v in value]
    if isinstance(value, float):
        return round(value, 4)
    return value


def guid_str(guid: dict) -> str:
    return f"{guid.get('sessionID', 0)}:{guid.get('localID', 0)}"


# ---------------------------------------------------------------------------
# Node tree
# ---------------------------------------------------------------------------

def build_tree(message: dict) -> list[dict]:
    nodes = {}
    for nc in message.get('nodeChanges', []):
        g = nc.get('guid')
        if g:
            nc['_id'] = guid_str(g)
            nc['_children'] = []
            nodes[nc['_id']] = nc
    roots = []
    for nc in nodes.values():
        pi = nc.get('parentIndex')
        parent = nodes.get(guid_str(pi['guid'])) if pi and pi.get('guid') else None
        if parent is not None:
            nc['_pos'] = pi.get('position', '')
            parent['_children'].append(nc)
        else:
            roots.append(nc)
    for nc in nodes.values():
        nc['_children'].sort(key=lambda c: c.get('_pos', ''))
    return roots


# ---------------------------------------------------------------------------
# Spec extraction
# ---------------------------------------------------------------------------

def color_hex(c: dict, opacity: float = 1.0) -> str:
    r = round(c.get('r', 0) * 255)
    g = round(c.get('g', 0) * 255)
    b = round(c.get('b', 0) * 255)
    a = c.get('a', 1) * opacity
    base = f'#{r:02X}{g:02X}{b:02X}'
    return base if a >= 0.999 else f'{base}@{a:.2f}'


def paint_spec(p: dict):
    ptype = p.get('type', 'SOLID')
    opacity = p.get('opacity', 1.0)
    if p.get('visible') is False:
        return None
    if ptype == 'SOLID':
        return color_hex(p.get('color', {}), opacity)
    if str(ptype).startswith('GRADIENT'):
        stops = [
            {'at': round(s.get('position', 0), 3),
             'color': color_hex(s.get('color', {}), opacity)}
            for s in p.get('stops', [])
        ]
        return {'gradient': ptype, 'stops': stops}
    if ptype == 'IMAGE':
        img = p.get('image') or {}
        h = img.get('hash')
        hexhash = h['__hex__'] if isinstance(h, dict) and '__hex__' in h else (
            h.hex() if isinstance(h, bytes) else None)
        return {'image': hexhash, 'name': img.get('name')}
    return {'paint': ptype}


def mat_mul(a, b):
    # 2x3 affine matrices [[m00,m01,m02],[m10,m11,m12]]
    return [
        [a[0][0] * b[0][0] + a[0][1] * b[1][0],
         a[0][0] * b[0][1] + a[0][1] * b[1][1],
         a[0][0] * b[0][2] + a[0][1] * b[1][2] + a[0][2]],
        [a[1][0] * b[0][0] + a[1][1] * b[1][0],
         a[1][0] * b[0][1] + a[1][1] * b[1][1],
         a[1][0] * b[0][2] + a[1][1] * b[1][2] + a[1][2]],
    ]


def node_matrix(nc: dict):
    t = nc.get('transform')
    if not t:
        return [[1, 0, 0], [0, 1, 0]]
    return [[t.get('m00', 1), t.get('m01', 0), t.get('m02', 0)],
            [t.get('m10', 0), t.get('m11', 0), t.get('m12', 0)]]


def text_spec(nc: dict):
    td = nc.get('textData') or {}
    chars = td.get('characters')
    if chars is None:
        return None
    font = nc.get('fontName') or {}
    spec = {
        'characters': chars,
        'font': font.get('family'),
        'style': font.get('style'),
        'size': nc.get('fontSize'),
        'letterSpacing': (nc.get('letterSpacing') or {}).get('value'),
        'align': nc.get('textAlignHorizontal'),
    }
    lh = nc.get('lineHeight') or {}
    if lh:
        spec['lineHeight'] = f"{round(lh.get('value', 0), 2)} {lh.get('units', '')}"
    return {k: v for k, v in spec.items() if v is not None}


def effects_spec(nc: dict):
    out = []
    for e in nc.get('effects', []) or []:
        if e.get('visible') is False:
            continue
        item = {'type': e.get('type'), 'radius': round(e.get('radius', 0), 2)}
        if e.get('color'):
            item['color'] = color_hex(e['color'])
        off = e.get('offset') or {}
        if off:
            item['offset'] = [round(off.get('x', 0), 1), round(off.get('y', 0), 1)]
        if e.get('spread'):
            item['spread'] = round(e['spread'], 2)
        out.append(item)
    return out or None


def corner_spec(nc: dict):
    radii = [nc.get(k) for k in (
        'rectangleTopLeftCornerRadius', 'rectangleTopRightCornerRadius',
        'rectangleBottomLeftCornerRadius', 'rectangleBottomRightCornerRadius')]
    if any(r is not None for r in radii):
        vals = [round(r or 0, 1) for r in radii]
        if len(set(vals)) == 1:
            return vals[0]
        return vals
    cr = nc.get('cornerRadius')
    return round(cr, 1) if cr else None


def node_spec(nc: dict, parent_mat, stats: dict):
    mat = mat_mul(parent_mat, node_matrix(nc))
    size = nc.get('size') or {}
    w, h = size.get('x'), size.get('y')
    fills = [s for s in (paint_spec(p) for p in nc.get('fillPaints', []) or []) if s]
    strokes = [s for s in (paint_spec(p) for p in nc.get('strokePaints', []) or []) if s]
    spec = {
        'name': nc.get('name'),
        'type': nc.get('type'),
        'xy': [round(mat[0][2], 1), round(mat[1][2], 1)],
    }
    if w is not None:
        spec['wh'] = [round(w, 1), round(h, 1)]
    if nc.get('visible') is False:
        spec['hidden'] = True
    if fills:
        spec['fills'] = fills
    if strokes:
        spec['strokes'] = strokes
        if nc.get('strokeWeight'):
            spec['strokeWeight'] = round(nc['strokeWeight'], 1)
    corner = corner_spec(nc)
    if corner is not None:
        spec['radius'] = corner
    eff = effects_spec(nc)
    if eff:
        spec['effects'] = eff
    if nc.get('opacity') is not None and nc['opacity'] < 0.999:
        spec['opacity'] = round(nc['opacity'], 2)
    text = text_spec(nc)
    if text:
        spec['text'] = text
        f = text.get('font')
        if f:
            stats['fonts'][(f, text.get('style'), text.get('size'))] += 1
    for fill in fills + strokes:
        if isinstance(fill, str):
            stats['colors'][fill.split('@')[0]] += 1
        elif isinstance(fill, dict) and 'stops' in fill:
            for s in fill['stops']:
                stats['colors'][s['color'].split('@')[0]] += 1
        elif isinstance(fill, dict) and fill.get('image'):
            stats['images'][fill['image']].append(nc.get('name') or '?')
    children = [node_spec(c, mat, stats) for c in nc.get('_children', [])]
    if children:
        spec['children'] = children
    return spec


def summarize_spec(spec: dict, lines: list[str], depth: int = 0, max_depth: int = 7):
    if depth > max_depth:
        return
    ind = '  ' * depth
    parts = [f"{ind}- **{spec.get('name') or '?'}** ({spec.get('type')})"]
    if 'xy' in spec and 'wh' in spec:
        parts.append(f"[{spec['xy'][0]},{spec['xy'][1]} {spec['wh'][0]}x{spec['wh'][1]}]")
    if spec.get('hidden'):
        parts.append('(hidden)')
    fills = spec.get('fills')
    if fills:
        f0 = fills[0]
        if isinstance(f0, str):
            parts.append(f'fill:{f0}')
        elif 'stops' in f0:
            parts.append('fill:' + '->'.join(s['color'] for s in f0['stops']))
        elif f0.get('image'):
            parts.append(f"img:{(f0.get('name') or f0['image'] or '')[:12]}")
    if 'radius' in spec:
        parts.append(f"r:{spec['radius']}")
    if 'text' in spec:
        t = spec['text']
        parts.append(
            f"text:\"{t['characters'][:40]}\" {t.get('font')} {t.get('style')} {t.get('size')}px")
    lines.append(' '.join(str(p) for p in parts))
    for c in spec.get('children', []):
        summarize_spec(c, lines, depth + 1, max_depth)


# ---------------------------------------------------------------------------
# Image export
# ---------------------------------------------------------------------------

def sniff_ext(data: bytes) -> str:
    if data[:8] == b'\x89PNG\r\n\x1a\n':
        return '.png'
    if data[:2] == b'\xff\xd8':
        return '.jpg'
    if data[:4] == b'RIFF' and data[8:12] == b'WEBP':
        return '.webp'
    if data[:6] in (b'GIF87a', b'GIF89a'):
        return '.gif'
    return '.bin'


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('fig', help='path to .fig file')
    ap.add_argument('--out', default=str(Path(__file__).parent / 'out'))
    ap.add_argument('--specs', action='store_true', help='emit per-frame specs')
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    zf = zipfile.ZipFile(args.fig)
    canvas = zf.read('canvas.fig')
    version, chunks = read_fig_chunks(canvas)
    print(f'fig-kiwi version {version}, {len(chunks)} chunks: '
          f'{[len(c) for c in chunks]}')

    schema = decode_binary_schema(decompress_chunk(chunks[0]))
    print(f'schema: {len(schema)} definitions')

    decoder = KiwiDecoder(schema)
    data = decompress_chunk(chunks[1])
    print(f'data chunk decompressed: {len(data)} bytes')
    message = decoder.decode('Message', ByteBuffer(data))
    node_changes = message.get('nodeChanges', [])
    print(f"message type={message.get('type')} nodeChanges={len(node_changes)} "
          f"blobs={len(message.get('blobs', []))}")
    if decoder.warnings:
        for w, n in decoder.warnings.most_common(10):
            print(f'  warn x{n}: {w}', file=sys.stderr)

    roots = build_tree(message)
    type_counts = Counter(nc.get('type') for nc in node_changes)
    print('node types:', dict(type_counts.most_common()))

    # full tree dump (children nested, internal keys prefixed with _)
    def strip(nc):
        d = {k: jsonable(v) for k, v in nc.items()
             if k not in ('_children', '_pos', 'guid', 'parentIndex')}
        d['id'] = nc.get('_id')
        kids = nc.get('_children')
        if kids:
            d['children'] = [strip(c) for c in kids]
        return d

    with open(out / 'canvas.json', 'w', encoding='utf-8') as f:
        json.dump([strip(r) for r in roots], f, ensure_ascii=False, indent=1)
    print(f"wrote {out / 'canvas.json'}")

    # image export
    img_dir = out / 'images'
    img_dir.mkdir(exist_ok=True)
    exported = {}
    for info in zf.infolist():
        if info.filename.startswith('images/') and not info.is_dir():
            blob = zf.read(info)
            sha = Path(info.filename).name
            ext = sniff_ext(blob)
            (img_dir / f'{sha}{ext}').write_bytes(blob)
            exported[sha] = f'{sha}{ext}'
    print(f'exported {len(exported)} images -> {img_dir}')

    if not args.specs:
        return

    # locate user-visible canvases and their top-level frames
    spec_dir = out / 'specs'
    spec_dir.mkdir(exist_ok=True)
    summary = ['# Figma spec summary', '']
    all_stats = {'colors': Counter(), 'fonts': Counter(),
                 'images': defaultdict(list)}

    def find_canvases(nodes):
        found = []
        for n in nodes:
            if n.get('type') == 'CANVAS':
                found.append(n)
            found.extend(find_canvases(n.get('_children', [])))
        return found

    for cv in find_canvases(roots):
        if (cv.get('name') or '').lower() == 'internal only canvas':
            continue
        frames = [c for c in cv.get('_children', [])
                  if c.get('type') in ('FRAME', 'SYMBOL', 'SECTION')]
        summary.append(f"## Canvas: {cv.get('name')} — {len(frames)} top frames")
        summary.append('')
        for fr in frames:
            stats = {'colors': Counter(), 'fonts': Counter(),
                     'images': defaultdict(list)}
            spec = node_spec(fr, [[1, 0, 0], [0, 1, 0]], stats)
            safe = ''.join(ch if ch.isalnum() or ch in '-_ ' else '_'
                           for ch in (fr.get('name') or 'frame')).strip()
            with open(spec_dir / f'{safe}.json', 'w', encoding='utf-8') as f:
                json.dump(spec, f, ensure_ascii=False, indent=1)
            summary.append(f"### Frame: {fr.get('name')} "
                           f"({spec.get('wh', ['?', '?'])[0]}x{spec.get('wh', ['?', '?'])[1]})")
            summary.append('')
            lines = []
            summarize_spec(spec, lines)
            summary.extend(lines)
            summary.append('')
            for k in ('colors', 'fonts'):
                all_stats[k].update(stats[k])
            for h, names in stats['images'].items():
                all_stats['images'][h].extend(names)

    summary.append('## Color frequency (candidate tokens)')
    summary.append('')
    for color, n in all_stats['colors'].most_common(40):
        summary.append(f'- `{color}` x{n}')
    summary.append('')
    summary.append('## Font usage')
    summary.append('')
    for (fam, style, size), n in all_stats['fonts'].most_common(40):
        summary.append(f'- {fam} {style} {size}px x{n}')

    manifest = {h: {'file': exported.get(h),
                    'nodes': sorted(set(all_stats['images'][h]))}
                for h in all_stats['images']}
    # include unreferenced images too
    for sha, fname in exported.items():
        manifest.setdefault(sha, {'file': fname, 'nodes': []})

    with open(out / 'image_manifest.json', 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    (spec_dir / 'spec_summary.md').write_text(
        '\n'.join(summary), encoding='utf-8')
    print(f"wrote {spec_dir / 'spec_summary.md'} and image_manifest.json")


if __name__ == '__main__':
    main()
