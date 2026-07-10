#!/usr/bin/env python3
"""Copy the Figma-embedded images the redesign actually uses into assets/.

Reads out/specs/*.json to map avatar-part thumbnails to their category rows
(by row label text), renames semantically with a fig_ prefix, and downscales
anything over 200 KB. Run from tools/figma_extract after extract_fig.py.
"""

import json
import shutil
from pathlib import Path

from PIL import Image

HERE = Path(__file__).parent
OUT = HERE / 'out'
APP = HERE.parent.parent
IMAGES = OUT / 'images'

# category row label -> asset slug
CATEGORIES = {
    'Face Shape': 'face',
    'Hairstyle': 'hair',
    'Eyes': 'eyes',
    'Mouth': 'mouth',
    'Accessory': 'acc',
    'Background': 'bg',
}

HERO_ASSETS = [
    # (hash prefix, destination, max width px)
    ('f61101bcec08', 'assets/images/avatars/fig_avatar_hero.png', 512),
    ('92bfda68e748', 'assets/images/decorations/fig_buzz_orbit.png', 800),
    ('d0b218f50335', 'assets/images/decorations/fig_orbit_rings.png', 800),
    ('9677f3b74ea5', 'assets/images/decorations/fig_constellation.png', None),
]


def find_image(prefix: str) -> Path:
    for p in IMAGES.iterdir():
        if p.name.startswith(prefix):
            return p
    raise FileNotFoundError(prefix)


def copy_scaled(src: Path, dest: Path, max_w):
    dest.parent.mkdir(parents=True, exist_ok=True)
    if max_w is None or src.stat().st_size <= 200_000:
        shutil.copyfile(src, dest)
        return src.stat().st_size, dest.stat().st_size
    img = Image.open(src)
    if img.width > max_w:
        img = img.resize((max_w, round(img.height * max_w / img.width)),
                         Image.LANCZOS)
    img.save(dest, optimize=True)
    return src.stat().st_size, dest.stat().st_size


def walk(node, fn):
    fn(node)
    for c in node.get('children', []):
        walk(c, fn)


def collect_rows(frame: dict) -> dict:
    """Map category slug -> ordered unique image hashes from that row."""
    rows = {}

    def visit(node):
        # a category row is a frame containing a TEXT child whose characters
        # match a known label
        texts = [c for c in node.get('children', [])
                 for c in ([c] + c.get('children', []))
                 if c.get('type') == 'TEXT']
        label = next((t['text']['characters'] for t in texts
                      if t.get('text', {}).get('characters') in CATEGORIES),
                     None)
        if not label:
            return
        slug = CATEGORIES[label]
        hashes = []

        def grab(n):
            for f in n.get('fills', []):
                if isinstance(f, dict) and f.get('image'):
                    if f['image'] not in hashes:
                        hashes.append(f['image'])

        walk(node, grab)
        if hashes and slug not in rows:
            rows[slug] = hashes

    walk(frame, visit)
    return rows


def main():
    manifest = {}

    for prefix, rel, max_w in HERO_ASSETS:
        src = find_image(prefix)
        before, after = copy_scaled(src, APP / rel, max_w)
        manifest[rel] = {'source': src.name, 'kb': after // 1024}
        print(f'{rel}  {before // 1024}KB -> {after // 1024}KB')

    section = json.loads(
        (OUT / 'specs' / 'Section 1.json').read_text('utf-8'))
    rows = collect_rows(section)
    for slug, hashes in rows.items():
        for i, h in enumerate(hashes, 1):
            src = find_image(h)
            rel = f'assets/images/avatars/parts/fig_{slug}_{i:02d}.png'
            before, after = copy_scaled(src, APP / rel, 128)
            manifest[rel] = {'source': src.name, 'kb': after // 1024}
        print(f'{slug}: {len(hashes)} thumbnails')

    (OUT / 'asset_manifest.json').write_text(
        json.dumps(manifest, indent=1), 'utf-8')
    print(f'total {len(manifest)} assets')


if __name__ == '__main__':
    main()
