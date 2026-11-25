
#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "public" / "icon-512.png"
ANDROID = ROOT / "android" / "app" / "src" / "main"
RES = ANDROID / "res"

if not SOURCE.exists():
    raise SystemExit(f"Missing app icon: {SOURCE}")

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
    fitted = icon.resize((size, size), Image.Resampling.LANCZOS)
    fitted.save(target / "ic_launcher.png")
    fitted.save(target / "ic_launcher_round.png")

drawable = RES / "drawable"
drawable.mkdir(parents=True, exist_ok=True)

foreground = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
safe_logo = icon.resize((288, 288), Image.Resampling.LANCZOS)
foreground.alpha_composite(safe_logo, (72, 72))
foreground.save(drawable / "ic_launcher_foreground.png")

adaptive = RES / "mipmap-anydpi-v26"
adaptive.mkdir(parents=True, exist_ok=True)

xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'''

(adaptive / "ic_launcher.xml").write_text(xml)
(adaptive / "ic_launcher_round.xml").write_text(xml)

values = RES / "values"
values.mkdir(parents=True, exist_ok=True)
(values / "ic_launcher_background.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources><color name="ic_launcher_background">#06152F</color></resources>'
)

manifest = ANDROID / "AndroidManifest.xml"
if manifest.exists():
    content = manifest.read_text()
    content = content.replace(
        'android:icon="@mipmap/ic_launcher"',
        'android:icon="@mipmap/ic_launcher" '
        'android:roundIcon="@mipmap/ic_launcher_round"'
    )
    manifest.write_text(content)

print("RR Mobiles launcher icons generated.")
