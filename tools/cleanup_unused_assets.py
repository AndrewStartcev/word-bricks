from __future__ import annotations

import re
import shutil
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
ARCHIVE = ROOT / "unused_assets"

TEXT_EXTS = {".gd", ".tscn", ".tres", ".res", ".cfg", ".godot", ".gdshader", ".shader"}
MEDIA_EXTS = {".png", ".webp", ".jpg", ".jpeg", ".svg", ".ogg", ".wav", ".mp3", ".ttf", ".otf"}
RES_RE = re.compile(r"res://[^\"'\s\)\]\},]+")


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


def reachable_media() -> set[Path]:
    roots = [GODOT / "project.godot", GODOT / "main.tscn"]
    queue: deque[Path] = deque(p for p in roots if p.exists())
    visited: set[Path] = set()
    media: set[Path] = set()

    while queue:
        path = queue.popleft().resolve()
        if path in visited or not path.exists():
            continue
        visited.add(path)
        if path.is_file() and path.suffix.lower() in MEDIA_EXTS:
            media.add(path)
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
            if target.suffix.lower() in MEDIA_EXTS:
                media.add(target)
            elif target.suffix.lower() in TEXT_EXTS or target.name == "project.godot":
                queue.append(target)
    return media


def main() -> None:
    used = reachable_media()
    all_media = sorted(
        p.resolve() for p in GODOT.rglob("*")
        if p.is_file() and p.suffix.lower() in MEDIA_EXTS and ".godot" not in p.parts and "build" not in p.parts
    )
    unused = [p for p in all_media if p not in used]

    print(f"reachable media: {len(used)}")
    print(f"all importable media inside Godot project: {len(all_media)}")
    print(f"unused media: {len(unused)}")

    total = 0
    moved_rel: list[str] = []
    for src in unused:
        rel = src.relative_to(GODOT)
        dst = ARCHIVE / rel
        size = src.stat().st_size
        total += size
        moved_rel.append(rel.as_posix())
        print(f"MOVE {rel.as_posix()}  {size / 1024:.1f} KiB")
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))

    report = ROOT / "UNUSED_ASSETS_MOVED.md"
    previous = []
    if report.exists():
        for line in report.read_text(encoding="utf-8").splitlines():
            if line.startswith("- `") and line.endswith("`"):
                previous.append(line[3:-1])
    combined = sorted(set(previous + moved_rel))
    lines = [
        "# Unused Godot media moved out of project",
        "",
        "Generated from the transitive resource graph starting at `godot/project.godot` and `godot/main.tscn`.",
        "Files are preserved under repository-root `unused_assets/`, outside the Godot project, so an `all_resources` Web export cannot include them.",
        "",
        f"Last cleanup moved: **{len(unused)} files**, **{total / (1024 * 1024):.2f} MiB**.",
        f"Total archived paths: **{len(combined)}**.",
        "",
    ]
    lines.extend(f"- `{p}`" for p in combined)
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
