from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
S = ROOT / "godot" / "scripts"


def replace_once(text: str, old: str, new: str, name: str) -> str:
    if old not in text:
        raise RuntimeError(f"Expected block not found: {name}")
    return text.replace(old, new, 1)


def patch_story() -> None:
    p = S / "app_runtime_story.gd"
    text = p.read_text(encoding="utf-8")
    old = '''const INTRO_FRAMES: Array[Texture2D] = [
\tpreload("res://assets/comics/intro/intro_01_world.webp"),
\tpreload("res://assets/comics/intro/intro_02_wizard.webp"),
\tpreload("res://assets/comics/intro/intro_03_disappearance.webp"),
\tpreload("res://assets/comics/intro/intro_04_owl.webp"),
\tpreload("res://assets/comics/intro/intro_05_journey.webp")
]
'''
    new = '''const INTRO_FRAME_PATHS: Array[String] = [
\t"res://assets/comics/intro/intro_01_world.webp",
\t"res://assets/comics/intro/intro_02_wizard.webp",
\t"res://assets/comics/intro/intro_03_disappearance.webp",
\t"res://assets/comics/intro/intro_04_owl.webp",
\t"res://assets/comics/intro/intro_05_journey.webp"
]
'''
    text = replace_once(text, old, new, "intro preload block")
    text = text.replace('INTRO_FRAMES[int(page[0])]', '_story_texture(INTRO_FRAME_PATHS[int(page[0])])')
    text = text.replace('INTRO_FRAMES[int(page[1])]', '_story_texture(INTRO_FRAME_PATHS[int(page[1])])')
    marker = '\nfunc _show_intro(page_index: int = 0) -> void:\n'
    helper = '''
func _story_texture(path: String) -> Texture2D:
\tvar resource: Resource = ResourceLoader.load(path)
\treturn resource as Texture2D


func _show_intro(page_index: int = 0) -> void:
'''
    text = replace_once(text, marker, '\n' + helper, "story helper insertion")
    p.write_text(text, encoding="utf-8")


def patch_chapters() -> None:
    p = S / "app_runtime_chapters.gd"
    text = p.read_text(encoding="utf-8")
    old = '''const VILLAGE_TRANSITION_FRAMES: Array[Texture2D] = [
\tpreload("res://assets/comics/village_unlock/village_unlock_01.webp"),
\tpreload("res://assets/comics/village_unlock/village_unlock_02.webp"),
\tpreload("res://assets/comics/village_unlock/village_unlock_03.webp")
]
'''
    new = '''const VILLAGE_TRANSITION_FRAME_PATHS: Array[String] = [
\t"res://assets/comics/village_unlock/village_unlock_01.webp",
\t"res://assets/comics/village_unlock/village_unlock_02.webp",
\t"res://assets/comics/village_unlock/village_unlock_03.webp"
]
'''
    text = replace_once(text, old, new, "village preload block")
    for i in range(3):
        text = text.replace(f'VILLAGE_TRANSITION_FRAMES[{i}]', f'_story_texture(VILLAGE_TRANSITION_FRAME_PATHS[{i}])')
    p.write_text(text, encoding="utf-8")


def patch_full() -> None:
    p = S / "app_runtime_full.gd"
    text = p.read_text(encoding="utf-8")
    blocks = {
'''const SEA_TRANSITION_FRAMES: Array[Texture2D] = [
\tpreload("res://assets/comics/sea_unlock/sea_unlock_01.webp"),
\tpreload("res://assets/comics/sea_unlock/sea_unlock_02.webp"),
\tpreload("res://assets/comics/sea_unlock/sea_unlock_03.webp")
]
''': '''const SEA_TRANSITION_FRAME_PATHS: Array[String] = [
\t"res://assets/comics/sea_unlock/sea_unlock_01.webp",
\t"res://assets/comics/sea_unlock/sea_unlock_02.webp",
\t"res://assets/comics/sea_unlock/sea_unlock_03.webp"
]
''',
'''const CITY_TRANSITION_FRAMES: Array[Texture2D] = [
\tpreload("res://assets/comics/city_unlock/city_unlock_01.webp"),
\tpreload("res://assets/comics/city_unlock/city_unlock_02.webp"),
\tpreload("res://assets/comics/city_unlock/city_unlock_03.webp")
]
''': '''const CITY_TRANSITION_FRAME_PATHS: Array[String] = [
\t"res://assets/comics/city_unlock/city_unlock_01.webp",
\t"res://assets/comics/city_unlock/city_unlock_02.webp",
\t"res://assets/comics/city_unlock/city_unlock_03.webp"
]
''',
'''const FAIRYTALES_TRANSITION_FRAMES: Array[Texture2D] = [
\tpreload("res://assets/comics/fairytales_unlock/fairytales_unlock_01.webp"),
\tpreload("res://assets/comics/fairytales_unlock/fairytales_unlock_02.webp"),
\tpreload("res://assets/comics/fairytales_unlock/fairytales_unlock_03.webp")
]
''': '''const FAIRYTALES_TRANSITION_FRAME_PATHS: Array[String] = [
\t"res://assets/comics/fairytales_unlock/fairytales_unlock_01.webp",
\t"res://assets/comics/fairytales_unlock/fairytales_unlock_02.webp",
\t"res://assets/comics/fairytales_unlock/fairytales_unlock_03.webp"
]
''',
'''const TOWER_TRANSITION_FRAMES: Array[Texture2D] = [
\tpreload("res://assets/comics/tower_unlock/tower_unlock_01.webp"),
\tpreload("res://assets/comics/tower_unlock/tower_unlock_02.webp"),
\tpreload("res://assets/comics/tower_unlock/tower_unlock_03.webp")
]
''': '''const TOWER_TRANSITION_FRAME_PATHS: Array[String] = [
\t"res://assets/comics/tower_unlock/tower_unlock_01.webp",
\t"res://assets/comics/tower_unlock/tower_unlock_02.webp",
\t"res://assets/comics/tower_unlock/tower_unlock_03.webp"
]
''',
'''const FINALE_FRAMES: Array[Texture2D] = [
\tpreload("res://assets/comics/finale/finale_01.webp"),
\tpreload("res://assets/comics/finale/finale_02.webp"),
\tpreload("res://assets/comics/finale/finale_03.webp"),
\tpreload("res://assets/comics/finale/finale_04.webp")
]
''': '''const FINALE_FRAME_PATHS: Array[String] = [
\t"res://assets/comics/finale/finale_01.webp",
\t"res://assets/comics/finale/finale_02.webp",
\t"res://assets/comics/finale/finale_03.webp",
\t"res://assets/comics/finale/finale_04.webp"
]
'''
    }
    for old, new in blocks.items():
        text = replace_once(text, old, new, "full comic block")

    old_func = '''func _transition_frames(target_id: String) -> Array:
\tmatch target_id:
\t\t"village": return VILLAGE_TRANSITION_FRAMES
\t\t"sea": return SEA_TRANSITION_FRAMES
\t\t"city": return CITY_TRANSITION_FRAMES
\t\t"fairytales": return FAIRYTALES_TRANSITION_FRAMES
\t\t"tower": return TOWER_TRANSITION_FRAMES
\t\t_: return []
'''
    new_func = '''func _transition_frames(target_id: String) -> Array:
\tvar paths: Array[String] = []
\tmatch target_id:
\t\t"village": paths = VILLAGE_TRANSITION_FRAME_PATHS
\t\t"sea": paths = SEA_TRANSITION_FRAME_PATHS
\t\t"city": paths = CITY_TRANSITION_FRAME_PATHS
\t\t"fairytales": paths = FAIRYTALES_TRANSITION_FRAME_PATHS
\t\t"tower": paths = TOWER_TRANSITION_FRAME_PATHS
\t\t_: return []
\tvar frames: Array[Texture2D] = []
\tfor path in paths:
\t\tvar texture: Texture2D = _story_texture(path)
\t\tif texture != null:
\t\t\tframes.append(texture)
\treturn frames
'''
    text = replace_once(text, old_func, new_func, "transition frames function")
    text = text.replace('FINALE_FRAMES[int(page[0])]', '_story_texture(FINALE_FRAME_PATHS[int(page[0])])')
    text = text.replace('FINALE_FRAMES[int(page[1])]', '_story_texture(FINALE_FRAME_PATHS[int(page[1])])')
    p.write_text(text, encoding="utf-8")


def main() -> None:
    patch_story()
    patch_chapters()
    patch_full()
    print("Narrative textures converted from startup preloads to on-demand ResourceLoader loads.")


if __name__ == "__main__":
    main()
