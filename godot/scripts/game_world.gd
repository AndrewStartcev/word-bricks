extends "res://scripts/game_leveled.gd"

# Final campaign presentation layer. Level data comes from level_catalog.gd;
# this layer maps each location to its production art and chapter identity.

const SEA_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_sea.png")
const CITY_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_city.png")
const FAIRYTALES_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_fairytales.png")
const TOWER_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_tower.png")

const SEA_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_sea.svg")
const CITY_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_city.svg")
const FAIRYTALES_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_fairytales.svg")
const TOWER_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_tower.svg")


func configure_chapter(new_chapter_id: String) -> void:
	# Forest/Village configuration, including their production textures, remains in
	# game_chaptered.gd. The four later locations are layered here.
	if new_chapter_id == "forest" or new_chapter_id == "village":
		super.configure_chapter(new_chapter_id)
		return

	chapter_id = new_chapter_id
	match new_chapter_id:
		"sea":
			chapter_number = 3
			chapter_title = "Море"
			chapter_background = SEA_BACKGROUND
			chapter_icon = SEA_ICON
		"city":
			chapter_number = 4
			chapter_title = "Город"
			chapter_background = CITY_BACKGROUND
			chapter_icon = CITY_ICON
		"fairytales":
			chapter_number = 5
			chapter_title = "Сказки"
			chapter_background = FAIRYTALES_BACKGROUND
			chapter_icon = FAIRYTALES_ICON
		"tower":
			chapter_number = 6
			chapter_title = "Башня"
			chapter_background = TOWER_BACKGROUND
			chapter_icon = TOWER_ICON
		_:
			super.configure_chapter("forest")
			return

	# configure_level() immediately replaces these with the selected five-word
	# round from level_catalog.gd. Keep a valid fallback for direct scene testing.
	var fallback: Dictionary = LEVEL_CATALOG.get_level(chapter_id, 1)
	chapter_words = (fallback.get("words", []) as Array).duplicate()
	chapter_clues = (fallback.get("clues", []) as Array).duplicate()
	chapter_gaps.clear()
	for raw_word in chapter_words:
		chapter_gaps.append(_build_gap_indices(String(raw_word), 1))
