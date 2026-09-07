extends "res://scripts/game_presentation.gd"

# Chapter-aware gameplay presentation/configuration.
# The core board mechanics stay in game.gd; this layer swaps content, background,
# chapter icon and word layout before _ready() runs.

const FOREST_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_forest.webp")
const VILLAGE_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_village.webp")
const FOREST_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_forest.svg")
const VILLAGE_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_village.svg")

var chapter_id: String = "forest"
var chapter_number: int = 1
var chapter_title: String = "Лес"
var chapter_background: Texture2D = FOREST_BACKGROUND
var chapter_icon: Texture2D = FOREST_ICON
var chapter_words: Array = ["ВОЛК", "СОСНА", "ГРИБ", "ЕЛЬ", "ЛИСА"]
var chapter_clues: Array = [
	"Лесной хищник",
	"Хвойное дерево",
	"Растёт под деревьями",
	"Хвойное дерево",
	"Рыжая лесная охотница"
]
var chapter_gaps: Array = [
	[1, 2],
	[1, 2, 4],
	[0, 3],
	[0, 1],
	[1, 2]
]


func configure_chapter(new_chapter_id: String) -> void:
	chapter_id = new_chapter_id
	if new_chapter_id == "village":
		chapter_number = 2
		chapter_title = "Деревня"
		chapter_background = VILLAGE_BACKGROUND
		chapter_icon = VILLAGE_ICON
		chapter_words = ["ДОМ", "ХЛЕБ", "ПЕЧЬ", "КОЛОДЕЦ", "МЕЛЬНИЦА"]
		chapter_clues = [
			"В нём живут люди",
			"Его пекут из муки",
			"Даёт дому тепло",
			"Из него берут воду",
			"Превращает зерно в муку"
		]
		# Chapter 2 is slightly harder: 2–3 restored letters per word.
		chapter_gaps = [
			[1, 2],
			[1, 2],
			[1, 2],
			[1, 3, 5],
			[1, 3, 5]
		]
	else:
		chapter_id = "forest"
		chapter_number = 1
		chapter_title = "Лес"
		chapter_background = FOREST_BACKGROUND
		chapter_icon = FOREST_ICON
		chapter_words = ["ВОЛК", "СОСНА", "ГРИБ", "ЕЛЬ", "ЛИСА"]
		chapter_clues = [
			"Лесной хищник",
			"Хвойное дерево",
			"Растёт под деревьями",
			"Хвойное дерево",
			"Рыжая лесная охотница"
		]
		chapter_gaps = [
			[1, 2],
			[1, 2, 4],
			[0, 3],
			[0, 1],
			[1, 2]
		]


func _current_word() -> String:
	if chapter_words.is_empty():
		return ""
	var safe_index: int = clampi(word_index, 0, chapter_words.size() - 1)
	return String(chapter_words[safe_index])


func _reset_word_state() -> void:
	word_progress.clear()
	hint_revealed_slots.clear()
	pieces_without_goal = 0
	var word: String = _current_word()
	for _i in range(word.length()):
		word_progress.append(true)
	if word_index < 0 or word_index >= chapter_gaps.size():
		return
	var gap_indices: Array = chapter_gaps[word_index]
	for raw_index in gap_indices:
		var gap_index: int = int(raw_index)
		if gap_index >= 0 and gap_index < word_progress.size():
			word_progress[gap_index] = false


func _complete_word() -> void:
	last_completed_word = _current_word()
	completed_words.append(last_completed_word)
	score += 600 + combo * 120
	word_flash_timer = 1.0
	owl_happy_timer = 0.9
	_spawn_word_complete_fx()
	if completed_words.size() >= chapter_words.size():
		chapter_complete = true
		_play_sfx("chapter_complete")
		_spawn_chapter_fx()
		return
	_play_sfx("word_complete")
	word_index += 1
	_reset_word_state()


func _draw_background() -> void:
	draw_texture_rect(chapter_background, Rect2(Vector2.ZERO, BASE_SIZE), false)
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color(0.01, 0.025, 0.07, 0.18), true)


func _draw_left_panel() -> void:
	var panel: Rect2 = Rect2(125.0, 94.0, 330.0, 720.0)
	_draw_panel(panel, Color(0.010, 0.045, 0.105, 0.91), Color(0.09, 0.38, 0.66, 0.76))

	draw_texture_rect(chapter_icon, Rect2(148.0, 120.0, 56.0, 56.0), false)
	_draw_text("Глава %d" % chapter_number, Vector2(220.0, 140.0), 18, Color(0.67, 0.78, 0.92))
	_draw_text(chapter_title, Vector2(220.0, 176.0), 32, Color("73e891"))

	var total_words: int = maxi(1, chapter_words.size())
	_draw_text("%d / %d" % [completed_words.size(), total_words], Vector2(150.0, 221.0), 19, Color("7af09a"))
	draw_rect(Rect2(150.0, 238.0, 280.0, 10.0), Color(0.008, 0.026, 0.060, 0.90), true)
	var ratio: float = float(completed_words.size()) / float(total_words)
	draw_rect(Rect2(150.0, 238.0, 280.0 * ratio, 10.0), Color("55d979"), true)

	draw_line(Vector2(145.0, 278.0), Vector2(435.0, 278.0), Color(0.14, 0.34, 0.58, 0.42), 1.0)
	_draw_text("Слово", Vector2(150.0, 312.0), 18, Color(0.64, 0.76, 0.91))
	_draw_current_word(WORD_ORIGIN)

	draw_texture_rect(ICON_CLUE, Rect2(150.0, 399.0, 24.0, 24.0), false)
	var clue: String = ""
	if word_index >= 0 and word_index < chapter_clues.size():
		clue = String(chapter_clues[word_index])
	_draw_text(clue, Vector2(184.0, 420.0), 17, Color(0.82, 0.89, 0.98))

	var marker_y: float = 488.0
	_draw_text("Прогресс", Vector2(150.0, marker_y), 16, Color(0.52, 0.66, 0.82))
	var marker_step: float = 280.0 / float(total_words)
	for i in range(total_words):
		var marker_rect: Rect2 = Rect2(150.0 + float(i) * marker_step, marker_y + 18.0, maxf(18.0, marker_step - 13.0), 8.0)
		var marker_color: Color = Color(0.08, 0.17, 0.29, 0.92)
		if i < completed_words.size():
			marker_color = Color("65df86")
		elif i == completed_words.size():
			marker_color = Color("4faeff")
		draw_rect(marker_rect, marker_color, true)

	if not completed_words.is_empty():
		var last_word: String = completed_words[completed_words.size() - 1]
		draw_texture_rect(ICON_CHECK, Rect2(150.0, 552.0, 24.0, 24.0), false)
		_draw_text(last_word, Vector2(185.0, 573.0), 18, Color("73e891"))


func _draw_current_word(origin: Vector2) -> void:
	var word: String = _current_word()
	var layout: Dictionary = _word_layout(word.length())
	var slot_size: float = float(layout["slot"])
	var gap: float = float(layout["gap"])
	var font_size: int = int(layout["font"])
	for i in range(word.length()):
		var rect: Rect2 = Rect2(origin.x + float(i) * (slot_size + gap), origin.y, slot_size, slot_size)
		var collected: bool = word_progress[i]
		var hinted: bool = hint_revealed_slots.has(i)
		var fill: Color = Color(0.012, 0.047, 0.11, 0.98)
		var border: Color = Color(0.14, 0.37, 0.68, 0.88)
		var value: String = "_"
		if collected:
			fill = Color(0.025, 0.21, 0.44, 0.96)
			border = Color("4fb8ff")
			value = word.substr(i, 1)
		elif hinted:
			border = Color("f5b93f")
			value = word.substr(i, 1)
		_draw_panel(rect, fill, border)
		_draw_text_centered(value, rect, font_size, Color.WHITE)


func _word_slot_center(slot_index: int) -> Vector2:
	var word: String = _current_word()
	var layout: Dictionary = _word_layout(word.length())
	var slot_size: float = float(layout["slot"])
	var gap: float = float(layout["gap"])
	return WORD_ORIGIN + Vector2(float(slot_index) * (slot_size + gap) + slot_size * 0.5, slot_size * 0.5)


func _word_layout(letter_count: int) -> Dictionary:
	var count: int = maxi(1, letter_count)
	var gap: float = 7.0 if count <= 5 else 4.0
	var slot_size: float = minf(54.0, (280.0 - gap * float(count - 1)) / float(count))
	slot_size = maxf(29.0, slot_size)
	var font_size: int = clampi(roundi(slot_size * 0.57), 17, 31)
	return {"slot": slot_size, "gap": gap, "font": font_size}
