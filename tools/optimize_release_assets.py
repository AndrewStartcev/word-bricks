from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"


def mib(n: int) -> float:
    return n / (1024 * 1024)


def replace_refs(old: str, new: str) -> None:
    for base in (GODOT / "scripts", GODOT / "scenes", GODOT / "docs"):
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in {".gd", ".tscn", ".md", ".json"}:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if old in text:
                path.write_text(text.replace(old, new), encoding="utf-8")


def reencode_webp(path: Path, *, quality: int, max_size=None) -> tuple[int, int]:
    before = path.stat().st_size
    tmp = path.with_suffix(".tmp.webp")
    with Image.open(path) as im:
        im.load()
        if max_size and (im.width > max_size[0] or im.height > max_size[1]):
            im.thumbnail(max_size, Image.Resampling.LANCZOS)
        im.save(tmp, format="WEBP", method=6, quality=quality)
    tmp.replace(path)
    return before, path.stat().st_size


def optimize_backgrounds() -> tuple[int, int, int]:
    count = before = after = 0
    folder = GODOT / "assets" / "backgrounds"
    for src in sorted(folder.glob("*.webp")):
        b, a = reencode_webp(src, quality=91, max_size=(1440, 810))
        count += 1; before += b; after += a
    return count, before, after


def optimize_comics() -> tuple[int, int, int]:
    count = before = after = 0
    folder = GODOT / "assets" / "comics"
    for src in sorted(folder.rglob("*.webp")):
        b, a = reencode_webp(src, quality=93, max_size=(1024, 576))
        count += 1; before += b; after += a
    return count, before, after


def dedupe_assets() -> tuple[int, int]:
    # These files were deliberately duplicated by the designer for semantic folders,
    # but the rendered images are identical. Point runtime at one canonical file so
    # Godot imports/exports only one texture for each visual.
    pairs = [
        ("assets/ui/loading/loading_decor_books.webp", "assets/ui/decor/decor_books_stack.webp"),
        ("assets/ui/loading/loading_decor_lantern.webp", "assets/ui/decor/decor_lantern.webp"),
        ("assets/ui/loading/loading_decor_crystals.webp", "assets/ui/decor/decor_crystals.webp"),
        ("assets/ui/transitions/chapter_title_plate.webp", "assets/ui/panels/panel_header_long.webp"),
        ("assets/ui/transitions/chapter_card.webp", "assets/ui/panels/panel_modal_small.webp"),
    ]
    removed = saved = 0
    for duplicate_rel, canonical_rel in pairs:
        duplicate = GODOT / duplicate_rel
        canonical = GODOT / canonical_rel
        if not duplicate.exists() or not canonical.exists():
            continue
        replace_refs("res://" + duplicate_rel, "res://" + canonical_rel)
        saved += duplicate.stat().st_size
        duplicate.unlink()
        removed += 1
    return removed, saved


def main() -> None:
    total_before = total_after = 0
    for name, fn in [("backgrounds", optimize_backgrounds), ("comics", optimize_comics)]:
        count, before, after = fn()
        total_before += before; total_after += after
        print(f"{name}: {count} files, {mib(before):.1f} MiB -> {mib(after):.1f} MiB")
    removed, dedupe_saved = dedupe_assets()
    print(f"dedupe: {removed} duplicate files removed, {mib(dedupe_saved):.1f} MiB source bytes removed")
    print(f"REENCODE saved: {mib(total_before-total_after):.1f} MiB; total direct source reduction this pass: {mib(total_before-total_after+dedupe_saved):.1f} MiB")


if __name__ == "__main__":
    main()
