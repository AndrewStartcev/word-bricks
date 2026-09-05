extends "res://scripts/game.gd"

# Presentation-only overrides. Core gameplay remains in game.gd.
# The application shell owns pause/settings/result windows.

var presentation_font: SystemFont = SystemFont.new()


func _init() -> void:
	presentation_font.font_names = PackedStringArray(["Rubik", "Nunito", "Trebuchet MS", "Verdana", "Arial"])


func _draw_owl() -> void:
	var texture: Texture2D = OWL_IDLE
	if game_over:
		texture = OWL_DEFEAT
	elif chapter_complete or owl_happy_timer > 0.0:
		texture = OWL_HAPPY
	elif owl_hint_timer > 0.0:
		texture = OWL_HINT
	elif _is_danger_state():
		texture = OWL_WORRIED

	# Larger mascot, intentionally peeking from behind the left HUD.
	draw_texture_rect(texture, Rect2(2.0, 610.0, 205.0, 205.0), false)


func _draw_top_hud() -> void:
	# Settings and pause are real Control buttons in app_runtime.gd.
	_draw_stat_box(Rect2(980.0, 20.0, 185.0, 60.0), ICON_SCORE, "Очки", str(score), Color("ffd253"))
	_draw_stat_box(Rect2(1175.0, 20.0, 150.0, 60.0), ICON_COMBO, "Комбо", "x%d" % maxi(combo, 1), Color("ffc33b"))
	_draw_stat_box(Rect2(1335.0, 20.0, 165.0, 60.0), ICON_TIME, "Время", _format_time(), Color.WHITE)


func _draw_left_panel() -> void:
	var panel: Rect2 = Rect2(125.0, 94.0, 330.0, 720.0)
	_draw_panel(panel, Color(0.010, 0.045, 0.105, 0.91), Color(0.09, 0.38, 0.66, 0.76))

	draw_texture_rect(ICON_CHAPTER, Rect2(148.0, 120.0, 56.0, 56.0), false)
	_draw_text("Глава 1", Vector2(220.0, 140.0), 18, Color(0.67, 0.78, 0.92))
	_draw_text("Лес", Vector2(220.0, 176.0), 32, Color("73e891"))

	_draw_text("%d / %d" % [completed_words.size(), WORDS.size()], Vector2(150.0, 221.0), 19, Color("7af09a"))
	draw_rect(Rect2(150.0, 238.0, 280.0, 10.0), Color(0.008, 0.026, 0.060, 0.90), true)
	var ratio: float = float(completed_words.size()) / float(WORDS.size())
	draw_rect(Rect2(150.0, 238.0, 280.0 * ratio, 10.0), Color("55d979"), true)

	draw_line(Vector2(145.0, 278.0), Vector2(435.0, 278.0), Color(0.14, 0.34, 0.58, 0.42), 1.0)
	_draw_text("Слово", Vector2(150.0, 312.0), 18, Color(0.64, 0.76, 0.91))
	_draw_current_word(WORD_ORIGIN)

	draw_texture_rect(ICON_CLUE, Rect2(150.0, 399.0, 24.0, 24.0), false)
	_draw_text(CLUES[word_index], Vector2(184.0, 420.0), 18, Color(0.82, 0.89, 0.98))

	var marker_y: float = 488.0
	_draw_text("Прогресс", Vector2(150.0, marker_y), 16, Color(0.52, 0.66, 0.82))
	for i in range(WORDS.size()):
		var marker_rect: Rect2 = Rect2(150.0 + float(i) * 53.0, marker_y + 18.0, 40.0, 8.0)
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


func _draw_right_panel() -> void:
	var panel: Rect2 = Rect2(990.0, 94.0, 315.0, 420.0)
	_draw_panel(panel, Color(0.010, 0.045, 0.105, 0.91), Color(0.09, 0.38, 0.66, 0.76))

	_draw_text("Дальше", Vector2(1020.0, 139.0), 20, Color(0.82, 0.90, 0.98))
	var preview_rect: Rect2 = Rect2(1015.0, 158.0, 265.0, 205.0)
	_draw_panel(preview_rect, Color(0.004, 0.020, 0.055, 0.90), Color(0.10, 0.31, 0.55, 0.62))
	_draw_next_piece(preview_rect)

	var hint_visual: Rect2 = Rect2(1015.0, 392.0, 265.0, 72.0)
	_draw_panel(hint_visual, Color(0.020, 0.082, 0.155, 0.97), Color(0.18, 0.43, 0.68, 0.72))
	draw_texture_rect(ICON_HINT, Rect2(1032.0, 409.0, 36.0, 36.0), false)
	_draw_text("Подсказка", Vector2(1080.0, 435.0), 19, Color("ffe06a"))
	_draw_text("×%d" % hint_charges, Vector2(1231.0, 435.0), 18, Color.WHITE)


func _draw_controls() -> void:
	pass


func _draw_settings_overlay() -> void:
	pass


func _draw_overlay(_title: String, _subtitle: String) -> void:
	pass


func _draw_text(text: String, baseline: Vector2, size: int, color: Color) -> void:
	draw_string(presentation_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _draw_text_centered(text: String, rect: Rect2, size: int, color: Color) -> void:
	var baseline_y: float = rect.position.y + rect.size.y * 0.5 + float(size) * 0.36
	draw_string(
		presentation_font,
		Vector2(rect.position.x, baseline_y),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		size,
		color
	)
