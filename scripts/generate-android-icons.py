
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
    raise SystemExit(f"RR Mobiles icon not found: {SOURCE}")

if not MANIFEST.exists():
    raise SystemExit(f"AndroidManifest.xml not found: {MANIFEST}")

icon = Image.open(SOURCE).convert("RGBA")

# Generate launcher icons in Android mipmap folders
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

    fitted = icon.resize(
        (size, size),
        Image.Resampling.LANCZOS
    )

    fitted.save(target / "ic_launcher.png")
    fitted.save(target / "ic_launcher_round.png")

# Create adaptive icon foreground
drawable = RES / "drawable"
drawable.mkdir(parents=True, exist_ok=True)

foreground = Image.new(
    "RGBA", (432, 432), (0, 0, 0, 0)
)

safe_logo = icon.resize(
    (288, 288),
    Image.Resampling.LANCZOS
)

foreground.alpha_composite(safe_logo, (72, 72))
foreground.save(drawable / "ic_launcher_foreground.png")

# Create adaptive icon XML files
adaptive = RES / "mipmap-anydpi-v26"
adaptive.mkdir(parents=True, exist_ok=True)

adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'''

(adaptive / "ic_launcher.xml").write_text(adaptive_xml)
(adaptive / "ic_launcher_round.xml").write_text(adaptive_xml)

# Create adaptive icon background color
values = RES / "values"
values.mkdir(parents=True, exist_ok=True)

(values / "ic_launcher_background.xml").write_text(
    '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#06152F</color>
</resources>
'''
)

# Connect mipmap icons to AndroidManifest.xml
manifest_text = MANIFEST.read_text(encoding="utf-8")

application_pattern = r'<application\b[^>]*>'

match = re.search(application_pattern, manifest_text)

if not match:
    raise SystemExit("Application tag not found in AndroidManifest.xml")

application_tag = match.group(0)

application_tag = re.sub(
    r'\s+android:icon="[^"]*"',
    '',
    application_tag
)

application_tag = re.sub(
    r'\s+android:roundIcon="[^"]*"',
    '',
    application_tag
)

application_tag = application_tag[:-1] + (
    '\n        android:icon="@mipmap/ic_launcher"'
    '\n        android:roundIcon="@mipmap/ic_launcher_round">'
)

manifest_text = (
    manifest_text[:match.start()]
    + application_tag
    + manifest_text[match.end():]
)

MANIFEST.write_text(manifest_text, encoding="utf-8")

print("RR Mobiles mipmap icons generated and connected successfully!")
