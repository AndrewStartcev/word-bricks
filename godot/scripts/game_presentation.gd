extends "res://scripts/game.gd"

# Presentation-only overrides. Core gameplay remains in game.gd.
# The application shell owns pause/settings/result windows.

const UI_HUD_BOX_LARGE: Texture2D = preload("res://assets/ui/panels/hud_box_large.png")
const UI_HUD_BOX_SMALL: Texture2D = preload("res://assets/ui/panels/hud_box_small.png")
const UI_SIDEBAR_LEFT: Texture2D = preload("res://assets/ui/panels/sidebar_panel_left.png")
const UI_SIDEBAR_RIGHT: Texture2D = preload("res://assets/ui/panels/sidebar_panel_right.png")
const UI_SIDEBAR_INNER: Texture2D = preload("res://assets/ui/panels/sidebar_inner_box.png")

var presentation_font: SystemFont = SystemFont.new()


func _init() -> void:
	presentation_font.font_names = PackedStringArray(["Rubik", "Nunito", "Trebuchet MS", "Verdana", "Arial"])


func _process(delta: float) -> void:
	# A hard-drop can leave a tiny shake timer active on the exact frame when a
	# modal pauses gameplay. Clear it before the parent early-return so the board
	# cannot keep vibrating behind pause/result windows.
	if _is_paused() or game_over or chapter_complete:
		board_shake_timer = 0.0
	super._process(delta)


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

	draw_texture_rect(texture, Rect2(2.0, 610.0, 205.0, 205.0), false)


func _draw_top_hud() -> void:
	_draw_hud_stat(Rect2(980.0, 16.0, 184.0, 69.0), ICON_SCORE, "Очки", str(score), Color("ffd253"), true)
	_draw_hud_stat(Rect2(1170.0, 13.0, 146.0, 73.0), ICON_COMBO, "Комбо", "x%d" % maxi(combo, 1), Color("ffc33b"), false)
	_draw_hud_stat(Rect2(1322.0, 13.0, 146.0, 73.0), ICON_TIME, "Время", _format_time(), Color.WHITE, false)


func _draw_hud_stat(rect: Rect2, icon: Texture2D, title: String, value: String, value_color: Color, large: bool) -> void:
	draw_texture_rect(UI_HUD_BOX_LARGE if large else UI_HUD_BOX_SMALL, rect, false)
	var icon_size: float = 32.0
	var icon_x: float = rect.position.x + 16.0
	var icon_y: float = rect.position.y + (rect.size.y - icon_size) * 0.5
	draw_texture_rect(icon, Rect2(icon_x, icon_y, icon_size, icon_size), false)

	# Center both text rows inside the usable area to keep left/right breathing room.
	var text_x: float = rect.position.x + 52.0
	var text_width: float = rect.size.x - 68.0
	_draw_text_centered(title, Rect2(text_x, rect.position.y + 4.0, text_width, 28.0), 14, Color("c8d5e8"))
	_draw_text_centered(value, Rect2(text_x, rect.position.y + 29.0, text_width, 31.0), 21, value_color)


func _draw_left_panel() -> void:
	var panel: Rect2 = Rect2(125.0, 94.0, 330.0, 720.0)
	draw_texture_rect(UI_SIDEBAR_LEFT, panel, false)

	draw_texture_rect(ICON_CHAPTER, Rect2(165.0, 120.0, 52.0, 52.0), false)
	_draw_text("Глава 1", Vector2(232.0, 140.0), 18, Color(0.72, 0.80, 0.91))
	_draw_text("Лес", Vector2(232.0, 176.0), 32, Color("73e891"))

	_draw_text("%d / %d" % [completed_words.size(), WORDS.size()], Vector2(165.0, 221.0), 19, Color("7af09a"))
	draw_rect(Rect2(165.0, 238.0, 260.0, 10.0), Color(0.008, 0.026, 0.060, 0.90), true)
	var ratio: float = float(completed_words.size()) / float(WORDS.size())
	draw_rect(Rect2(165.0, 238.0, 260.0 * ratio, 10.0), Color("55d979"), true)

	draw_line(Vector2(160.0, 278.0), Vector2(425.0, 278.0), Color(0.45, 0.34, 0.18, 0.58), 1.0)
	_draw_text("Слово", Vector2(165.0, 312.0), 18, Color(0.72, 0.80, 0.91))
	_draw_current_word(Vector2(160.0, 324.0))

	draw_texture_rect(ICON_CLUE, Rect2(165.0, 399.0, 24.0, 24.0), false)
	_draw_text(CLUES[word_index], Vector2(200.0, 420.0), 18, Color(0.88, 0.91, 0.97))

	var marker_y: float = 488.0
	_draw_text("Прогресс", Vector2(165.0, marker_y), 16, Color(0.62, 0.70, 0.82))
	var marker_step: float = 260.0 / float(WORDS.size())
	for i in range(WORDS.size()):
		var marker_rect: Rect2 = Rect2(165.0 + float(i) * marker_step, marker_y + 18.0, maxf(18.0, marker_step - 13.0), 8.0)
		var marker_color: Color = Color(0.08, 0.17, 0.29, 0.92)
		if i < completed_words.size():
			marker_color = Color("65df86")
		elif i == completed_words.size():
			marker_color = Color("4faeff")
		draw_rect(marker_rect, marker_color, true)

	if not completed_words.is_empty():
		var last_word: String = completed_words[completed_words.size() - 1]
		draw_texture_rect(ICON_CHECK, Rect2(165.0, 552.0, 24.0, 24.0), false)
		_draw_text(last_word, Vector2(200.0, 573.0), 18, Color("73e891"))


func _draw_right_panel() -> void:
	var panel: Rect2 = Rect2(990.0, 94.0, 315.0, 420.0)
	draw_texture_rect(UI_SIDEBAR_RIGHT, panel, false)

	_draw_text_centered("Дальше", Rect2(1008.0, 107.0, 279.0, 48.0), 21, Color(0.90, 0.94, 0.99))

	var preview_rect: Rect2 = Rect2(1031.0, 158.0, 232.0, 232.0)
	draw_texture_rect(UI_SIDEBAR_INNER, preview_rect, false)
	_draw_next_piece(preview_rect)

	var hint_visual: Rect2 = Rect2(1022.0, 407.0, 250.0, 94.0)
	draw_texture_rect(UI_HUD_BOX_LARGE, hint_visual, false)
	draw_texture_rect(ICON_HINT, Rect2(1041.0, 437.0, 34.0, 34.0), false)
	_draw_text("Подсказка", Vector2(1086.0, 462.0), 19, Color("ffe06a"))
	_draw_text("×%d" % hint_charges, Vector2(1230.0, 462.0), 18, Color.WHITE)


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
