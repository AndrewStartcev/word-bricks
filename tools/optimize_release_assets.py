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


def save_webp(src: Path, dst: Path, *, quality: int, max_size=None, lossless=False) -> tuple[int, int]:
    before = src.stat().st_size
    with Image.open(src) as im:
        im.load()
        if max_size and (im.width > max_size[0] or im.height > max_size[1]):
            im.thumbnail(max_size, Image.Resampling.LANCZOS)
        kwargs = {"format": "WEBP", "method": 6}
        if lossless:
            kwargs.update(lossless=True, quality=100)
        else:
            kwargs.update(quality=quality)
        im.save(dst, **kwargs)
    after = dst.stat().st_size
    if src != dst:
        src.unlink()
    return before, after


def optimize_backgrounds() -> tuple[int, int, int]:
    count = before = after = 0
    folder = GODOT / "assets" / "backgrounds"
    for src in sorted(folder.glob("*.png")):
        dst = src.with_suffix(".webp")
        b, a = save_webp(src, dst, quality=90, max_size=(1600, 900))
        replace_refs(f"res://assets/backgrounds/{src.name}", f"res://assets/backgrounds/{dst.name}")
        count += 1; before += b; after += a
    return count, before, after


def optimize_comics() -> tuple[int, int, int]:
    count = before = after = 0
    folder = GODOT / "assets" / "comics"
    for src in sorted(folder.rglob("*.webp")):
        b = src.stat().st_size
        tmp = src.with_suffix(".tmp.webp")
        _, _ = save_webp(src, tmp, quality=92, max_size=(1280, 720))
        tmp.replace(src)
        count += 1; before += b; after += src.stat().st_size
    return count, before, after


def optimize_large_ui_pngs() -> tuple[int, int, int]:
    count = before = after = 0
    ui = GODOT / "assets" / "ui"
    for src in sorted(ui.rglob("*.png")):
        if src.stat().st_size < 100_000:
            continue
        dst = src.with_suffix(".webp")
        b = src.stat().st_size
        with Image.open(src) as im:
            im.load()
            im.save(dst, format="WEBP", method=6, lossless=True, quality=100)
        a = dst.stat().st_size
        if a >= b:
            dst.unlink()
            continue
        src.unlink()
        replace_refs("res://" + src.relative_to(GODOT).as_posix(), "res://" + dst.relative_to(GODOT).as_posix())
        count += 1; before += b; after += a
    return count, before, after


def optimize_owl() -> tuple[int, int, int]:
    count = before = after = 0
    folder = GODOT / "assets" / "characters" / "owl"
    for src in sorted(folder.glob("*.png")):
        dst = src.with_suffix(".webp")
        b = src.stat().st_size
        with Image.open(src) as im:
            im.load()
            im.save(dst, format="WEBP", method=6, lossless=True, quality=100)
        a = dst.stat().st_size
        if a >= b:
            dst.unlink()
            continue
        src.unlink()
        replace_refs("res://" + src.relative_to(GODOT).as_posix(), "res://" + dst.relative_to(GODOT).as_posix())
        count += 1; before += b; after += a
    return count, before, after


def main() -> None:
    total_before = total_after = 0
    for name, fn in [("backgrounds", optimize_backgrounds), ("comics", optimize_comics), ("large UI", optimize_large_ui_pngs), ("owl", optimize_owl)]:
        count, before, after = fn()
        total_before += before; total_after += after
        print(f"{name}: {count} files, {mib(before):.1f} MiB -> {mib(after):.1f} MiB")
    print(f"TOTAL optimized sources: {mib(total_before):.1f} MiB -> {mib(total_after):.1f} MiB (saved {mib(total_before-total_after):.1f} MiB)")


if __name__ == "__main__":
    main()
