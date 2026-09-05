extends "res://scripts/game_chaptered.gd"

# Location + level aware gameplay. A location is now a 10-level journey; each
# level keeps the proven five-word round so one session stays short and pleasant.

const LEVEL_CATALOG = preload("res://scripts/level_catalog.gd")

var round_number: int = 1
var round_title: String = "Лесные звери"


func configure_level(location_id: String, level_number: int) -> void:
	configure_chapter(location_id)
	round_number = clampi(level_number, 1, LEVEL_CATALOG.LEVELS_PER_LOCATION)
	var data: Dictionary = LEVEL_CATALOG.get_level(location_id, round_number)
	if data.is_empty():
		return
	round_title = String(data.get("title", "Уровень %d" % round_number))
	chapter_words = (data.get("words", []) as Array).duplicate()
	chapter_clues = (data.get("clues", []) as Array).duplicate()
	chapter_gaps.clear()
	for raw_word in chapter_words:
		chapter_gaps.append(_build_gap_indices(String(raw_word), round_number))


func _build_gap_indices(word: String, level_number: int) -> Array:
	var length: int = word.length()
	if length <= 1:
		return []
	var target_count: int = 2
	if level_number >= 4:
		target_count = 3
	if level_number >= 8:
		target_count = 4
	target_count = mini(target_count, length - 1)

	var result: Array = []
	var candidates: Array[int] = []
	candidates.append(1 if length > 2 else length - 1)
	candidates.append(maxi(0, length - 2))
	candidates.append(floori(float(length) * 0.5))
	candidates.append(length - 1)
	candidates.append(0)
	if length > 4:
		candidates.append(2)
	if length > 5:
		candidates.append(length - 3)

	for index in candidates:
		if index >= 0 and index < length and not result.has(index):
			result.append(index)
			if result.size() >= target_count:
				return result
	for index in range(length):
		if not result.has(index):
			result.append(index)
			if result.size() >= target_count:
				break
	return result


func _drop_interval() -> float:
	# Difficulty rises across the map, but not enough to turn later rounds into a
	# reflex game. Vocabulary remains the main challenge.
	var map_pressure: float = float(round_number - 1) * 0.022
	var word_pressure: float = float(completed_words.size()) * 0.035
	return maxf(0.34, 0.90 - map_pressure - word_pressure)


func _draw_left_panel() -> void:
	var panel: Rect2 = Rect2(125.0, 94.0, 330.0, 720.0)
	_draw_panel(panel, Color(0.010, 0.045, 0.105, 0.91), Color(0.09, 0.38, 0.66, 0.76))

	draw_texture_rect(chapter_icon, Rect2(148.0, 120.0, 56.0, 56.0), false)
	_draw_text("Локация %d" % chapter_number, Vector2(220.0, 140.0), 16, Color(0.67, 0.78, 0.92))
	_draw_text(chapter_title, Vector2(220.0, 174.0), 29, Color("73e891"))
	_draw_text("Уровень %d / %d" % [round_number, LEVEL_CATALOG.LEVELS_PER_LOCATION], Vector2(150.0, 214.0), 17, Color("7dc9ff"))
	_draw_text(round_title, Vector2(150.0, 240.0), 16, Color(0.72, 0.82, 0.94))

	var total_words: int = maxi(1, chapter_words.size())
	draw_rect(Rect2(150.0, 260.0, 280.0, 8.0), Color(0.008, 0.026, 0.060, 0.90), true)
	var ratio: float = float(completed_words.size()) / float(total_words)
	draw_rect(Rect2(150.0, 260.0, 280.0 * ratio, 8.0), Color("55d979"), true)

	draw_line(Vector2(145.0, 292.0), Vector2(435.0, 292.0), Color(0.14, 0.34, 0.58, 0.42), 1.0)
	_draw_text("Слово", Vector2(150.0, 321.0), 17, Color(0.64, 0.76, 0.91))
	_draw_current_word(Vector2(145.0, 336.0))

	draw_texture_rect(ICON_CLUE, Rect2(150.0, 409.0, 24.0, 24.0), false)
	var clue: String = ""
	if word_index >= 0 and word_index < chapter_clues.size():
		clue = String(chapter_clues[word_index])
	_draw_text(clue, Vector2(184.0, 430.0), 16, Color(0.82, 0.89, 0.98))

	var marker_y: float = 492.0
	_draw_text("Слова уровня", Vector2(150.0, marker_y), 15, Color(0.52, 0.66, 0.82))
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
		draw_texture_rect(ICON_CHECK, Rect2(150.0, 554.0, 24.0, 24.0), false)
		_draw_text(last_word, Vector2(185.0, 575.0), 18, Color("73e891"))


func _word_slot_center(slot_index: int) -> Vector2:
	var word: String = _current_word()
	var layout: Dictionary = _word_layout(word.length())
	var slot_size: float = float(layout["slot"])
	var gap: float = float(layout["gap"])
	var origin: Vector2 = Vector2(145.0, 336.0)
	return origin + Vector2(float(slot_index) * (slot_size + gap) + slot_size * 0.5, slot_size * 0.5)
