from __future__ import annotations

import re
import shutil
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
ASSETS = GODOT / "assets"
ARCHIVE = ROOT / "unused_assets"

TEXT_EXTS = {".gd", ".tscn", ".tres", ".res", ".cfg", ".godot", ".gdshader", ".shader"}
ASSET_EXTS = {".png", ".webp", ".jpg", ".jpeg", ".svg", ".ogg", ".wav", ".mp3", ".ttf", ".otf"}
RES_RE = re.compile(r"res://[^\"'\s\)\]\},]+")


def godot_path(path: Path) -> str:
    return "res://" + path.relative_to(GODOT).as_posix()


def local_from_res(ref: str) -> Path | None:
    if not ref.startswith("res://"):
        return None
    return GODOT / ref[6:]


def refs_from_text(path: Path) -> set[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return set()
    return {m.group(0).rstrip(";,:.") for m in RES_RE.finditer(text)}


def reachable_resources() -> set[Path]:
    roots = [GODOT / "project.godot", GODOT / "main.tscn"]
    queue: deque[Path] = deque(p for p in roots if p.exists())
    visited: set[Path] = set()
    assets: set[Path] = set()

    while queue:
        path = queue.popleft().resolve()
        if path in visited or not path.exists():
            continue
        visited.add(path)
        if path.is_file() and path.suffix.lower() in ASSET_EXTS:
            assets.add(path)
            continue
        if not path.is_file() or (path.suffix.lower() not in TEXT_EXTS and path.name != "project.godot"):
            continue
        for ref in refs_from_text(path):
            target = local_from_res(ref)
            if target is None:
                continue
            target = target.resolve()
            if not target.exists():
                continue
            if target.suffix.lower() in ASSET_EXTS:
                assets.add(target)
            elif target.suffix.lower() in TEXT_EXTS or target.name == "project.godot":
                queue.append(target)
    return assets


def main() -> None:
    used = reachable_resources()
    all_assets = sorted(p.resolve() for p in ASSETS.rglob("*") if p.is_file() and p.suffix.lower() in ASSET_EXTS)
    unused = [p for p in all_assets if p not in used]

    print(f"reachable assets: {len(used)}")
    print(f"all project assets: {len(all_assets)}")
    print(f"unused assets: {len(unused)}")

    total = 0
    for src in unused:
        rel = src.relative_to(GODOT)
        dst = ARCHIVE / rel
        size = src.stat().st_size
        total += size
        print(f"MOVE {rel.as_posix()}  {size / 1024:.1f} KiB")
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))

    report = ROOT / "UNUSED_ASSETS_MOVED.md"
    lines = [
        "# Unused Godot assets moved out of project",
        "",
        "Generated from the transitive resource graph starting at `godot/project.godot` and `godot/main.tscn`.",
        "The files below are kept in the repository under `unused_assets/`, but are outside the Godot project and therefore cannot enter an `all_resources` Web export.",
        "",
        f"Moved: **{len(unused)} files**, **{total / (1024 * 1024):.2f} MiB**.",
        "",
    ]
    lines.extend(f"- `{p.relative_to(GODOT).as_posix()}`" for p in unused)
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
