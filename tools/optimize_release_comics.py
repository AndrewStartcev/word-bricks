from __future__ import annotations

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
COMICS = ROOT / "godot" / "assets" / "comics"
TEXT_EXTENSIONS = {".gd", ".tscn", ".tres", ".md", ".json", ".cfg"}
QUALITY = 88


def convert_png_to_webp(path: Path) -> tuple[str, str]:
    target = path.with_suffix(".webp")
    with Image.open(path) as image:
        image.load()
        if image.mode not in ("RGB", "RGBA"):
            image = image.convert("RGBA" if "A" in image.getbands() else "RGB")
        image.save(target, "WEBP", quality=QUALITY, method=6)
    old_ref = "res://" + path.relative_to(ROOT / "godot").as_posix()
    new_ref = "res://" + target.relative_to(ROOT / "godot").as_posix()
    path.unlink()
    return old_ref, new_ref


def rewrite_references(replacements: dict[str, str]) -> None:
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_EXTENSIONS:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        updated = text
        for old, new in replacements.items():
            updated = updated.replace(old, new)
            updated = updated.replace(old.removeprefix("res://"), new.removeprefix("res://"))
        if updated != text:
            path.write_text(updated, encoding="utf-8", newline="\n")


def main() -> None:
    if not COMICS.exists():
        raise SystemExit("Comics directory not found")
    replacements: dict[str, str] = {}
    pngs = sorted(COMICS.rglob("*.png"))
    if not pngs:
        print("No PNG comics found; nothing to optimize.")
        return
    before = sum(path.stat().st_size for path in pngs)
    for path in pngs:
        old_ref, new_ref = convert_png_to_webp(path)
        replacements[old_ref] = new_ref
    rewrite_references(replacements)
    webps = sorted(COMICS.rglob("*.webp"))
    after = sum(path.stat().st_size for path in webps)
    print(f"Converted {len(pngs)} comic images: {before / 1024 / 1024:.1f} MiB -> {after / 1024 / 1024:.1f} MiB")


if __name__ == "__main__":
    main()
