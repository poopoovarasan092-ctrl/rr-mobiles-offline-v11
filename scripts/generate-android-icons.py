
#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "public" / "icon-512.png"
ANDROID = ROOT / "android" / "app" / "src" / "main"
RES = ANDROID / "res"
MANIFEST = ANDROID / "AndroidManifest.xml"

if not SOURCE.exists():
    raise SystemExit("RR logo icon-512.png is missing")

if not MANIFEST.exists():
    raise SystemExit("AndroidManifest.xml is missing")

icon = Image.open(SOURCE).convert("RGBA")

sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in sizes.items():
    target = RES / folder
    target.mkdir(parents=True, exist_ok=True)

    image = icon.resize(
        (size, size),
        Image.Resampling.LANCZOS
    )

    image.save(target / "ic_launcher.png")
    image.save(target / "ic_launcher_round.png")

# Remove adaptive icon definitions so Android uses PNG mipmaps
adaptive = RES / "mipmap-anydpi-v26"

for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
    file = adaptive / name
    if file.exists():
        file.unlink()

# Set Android launcher icon references
content = MANIFEST.read_text(encoding="utf-8")

match = re.search(r'<application\b[^>]*>', content)

if not match:
    raise SystemExit("Application tag not found")

tag = match.group(0)

tag = re.sub(r'\s+android:icon="[^"]*"', '', tag)
tag = re.sub(r'\s+android:roundIcon="[^"]*"', '', tag)

tag = tag[:-1] + (
    '\n        android:icon="@mipmap/ic_launcher"'
    '\n        android:roundIcon="@mipmap/ic_launcher_round">'
)

content = content[:match.start()] + tag + content[match.end():]
MANIFEST.write_text(content, encoding="utf-8")

print("RR Mobiles PNG mipmap launcher icons installed.")
