extends "res://scripts/game.gd"

# Presentation-only overrides. Core gameplay remains in game.gd.
# The application shell owns pause/settings/result windows.

const UI_HUD_BOX_LARGE: Texture2D = preload("res://assets/ui/panels/hud_box_large.png")
const UI_HUD_BOX_SMALL: Texture2D = preload("res://assets/ui/panels/hud_box_small.png")
const UI_SIDEBAR_LEFT: Texture2D = preload("res://assets/ui/panels/sidebar_panel_left.webp")
const UI_SIDEBAR_RIGHT: Texture2D = preload("res://assets/ui/panels/sidebar_panel_right.webp")
const UI_SIDEBAR_INNER: Texture2D = preload("res://assets/ui/panels/sidebar_inner_box.webp")

const TILE_BONUS: Texture2D = preload("res://assets/tiles/tile_bonus_green.png")
const TILE_DANGER: Texture2D = preload("res://assets/tiles/tile_danger_red.png")
const TILE_SPECIAL: Texture2D = preload("res://assets/tiles/tile_special_purple.png")

const PRESENT_X_SHIFT: float = 85.0
const PRESENT_BOARD_ORIGIN: Vector2 = Vector2(590.0, 94.0)
const PRESENT_WORD_ORIGIN: Vector2 = Vector2(245.0, 324.0)
const PRESENT_BOARD_RECT: Rect2 = Rect2(PRESENT_BOARD_ORIGIN, Vector2(COLS * CELL, ROWS * CELL))
const PRESENT_HINT_RECT: Rect2 = Rect2(1092.0, 410.0, 280.0, 100.0)

var presentation_font: SystemFont = SystemFont.new()


func _init() -> void:
	presentation_font.font_names = PackedStringArray(["Rubik", "Nunito", "Trebuchet MS", "Verdana", "Arial"])


func _process(delta: float) -> void:
	if _is_paused() or game_over or chapter_complete:
		board_shake_timer = 0.0
	super._process(delta)


func _handle_left_click(base_pos: Vector2) -> void:
	if settings_open:
		_handle_settings_click(base_pos)
		return
	if SETTINGS_RECT.has_point(base_pos):
		_open_settings()
		return
	if PAUSE_RECT.has_point(base_pos) and not game_over and not chapter_complete:
		manual_paused = not manual_paused
		_play_sfx("ui_click")
		_sync_audio_pause()
		queue_redraw()
		return
	if manual_paused:
		return
	if PRESENT_HINT_RECT.has_point(base_pos) and not game_over and not chapter_complete:
		_use_hint()
		queue_redraw()
		return
	if PRESENT_BOARD_RECT.has_point(base_pos) and not game_over and not chapter_complete:
		_hard_drop()
		queue_redraw()


func _handle_right_click(base_pos: Vector2) -> void:
	if _is_paused() or game_over or chapter_complete:
		return
	if PRESENT_BOARD_RECT.has_point(base_pos):
		_try_rotate()
		queue_redraw()


func _handle_mouse_motion(base_pos: Vector2) -> void:
	if current_piece == null or not PRESENT_BOARD_RECT.has_point(base_pos):
		return
	var column: int = floori((base_pos.x - PRESENT_BOARD_ORIGIN.x) / CELL)
	var min_x: int = 99
	var max_x: int = -99
	for cell in current_piece.cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
	var shape_center: int = floori(float(min_x + max_x) * 0.5)
	_move_piece_to_x(column - shape_center)


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
	_draw_hud_stat(Rect2(976.0, 18.0, 178.0, 64.0), ICON_SCORE, "Очки", str(score), Color("ffd253"), true)
	_draw_hud_stat(Rect2(1166.0, 18.0, 145.0, 64.0), ICON_COMBO, "Комбо", "x%d" % maxi(combo, 1), Color("ffc33b"), false)
	_draw_hud_stat(Rect2(1323.0, 18.0, 145.0, 64.0), ICON_TIME, "Время", _format_time(), Color.WHITE, false)


func _draw_hud_stat(rect: Rect2, icon: Texture2D, title: String, value: String, value_color: Color, large: bool) -> void:
	draw_texture_rect(UI_HUD_BOX_LARGE if large else UI_HUD_BOX_SMALL, rect, false)
	var icon_size: float = 28.0
	var icon_x: float = rect.position.x + 15.0
	var icon_y: float = rect.position.y + (rect.size.y - icon_size) * 0.5
	draw_texture_rect(icon, Rect2(icon_x, icon_y, icon_size, icon_size), false)
	var text_x: float = rect.position.x + 49.0
	var text_width: float = rect.size.x - 61.0
	_draw_text_centered(title, Rect2(text_x, rect.position.y + 5.0, text_width, 21.0), 12, Color("c8d5e8"))
	_draw_text_centered_bold(value, Rect2(text_x, rect.position.y + 23.0, text_width, 32.0), 22, value_color)


func _draw_left_panel() -> void:
	var x: float = PRESENT_X_SHIFT
	var panel: Rect2 = Rect2(125.0 + x, 94.0, 330.0, 720.0)
	draw_texture_rect(UI_SIDEBAR_LEFT, panel, false)

	draw_texture_rect(ICON_CHAPTER, Rect2(165.0 + x, 120.0, 52.0, 52.0), false)
	_draw_text("Глава 1", Vector2(232.0 + x, 140.0), 18, Color(0.72, 0.80, 0.91))
	_draw_text("Лес", Vector2(232.0 + x, 176.0), 32, Color("73e891"))

	_draw_text("%d / %d" % [completed_words.size(), WORDS.size()], Vector2(165.0 + x, 221.0), 19, Color("7af09a"))
	draw_rect(Rect2(165.0 + x, 238.0, 260.0, 10.0), Color(0.008, 0.026, 0.060, 0.90), true)
	var ratio: float = float(completed_words.size()) / float(WORDS.size())
	draw_rect(Rect2(165.0 + x, 238.0, 260.0 * ratio, 10.0), Color("55d979"), true)

	draw_line(Vector2(160.0 + x, 278.0), Vector2(425.0 + x, 278.0), Color(0.45, 0.34, 0.18, 0.58), 1.0)
	_draw_text("Слово", Vector2(165.0 + x, 312.0), 18, Color(0.72, 0.80, 0.91))
	_draw_current_word(PRESENT_WORD_ORIGIN)

	draw_texture_rect(ICON_CLUE, Rect2(165.0 + x, 399.0, 24.0, 24.0), false)
	_draw_text(CLUES[word_index], Vector2(200.0 + x, 420.0), 18, Color(0.88, 0.91, 0.97))

	var marker_y: float = 488.0
	_draw_text("Прогресс", Vector2(165.0 + x, marker_y), 16, Color(0.62, 0.70, 0.82))
	var marker_step: float = 260.0 / float(WORDS.size())
	for i in range(WORDS.size()):
		var marker_rect: Rect2 = Rect2(165.0 + x + float(i) * marker_step, marker_y + 18.0, maxf(18.0, marker_step - 13.0), 8.0)
		var marker_color: Color = Color(0.08, 0.17, 0.29, 0.92)
		if i < completed_words.size():
			marker_color = Color("65df86")
		elif i == completed_words.size():
			marker_color = Color("4faeff")
		draw_rect(marker_rect, marker_color, true)

	if not completed_words.is_empty():
		var last_word: String = completed_words[completed_words.size() - 1]
		draw_texture_rect(ICON_CHECK, Rect2(165.0 + x, 552.0, 24.0, 24.0), false)
		_draw_text(last_word, Vector2(200.0 + x, 573.0), 18, Color("73e891"))


func _draw_board() -> void:
	var shake: Vector2 = _board_shake_offset()
	var origin: Vector2 = PRESENT_BOARD_ORIGIN + shake
	var board_rect: Rect2 = Rect2(origin.x - 8.0, origin.y - 8.0, float(COLS) * CELL + 16.0, float(ROWS) * CELL + 16.0)
	_draw_panel(board_rect, Color(0.006, 0.025, 0.065, 0.94), Color(0.05, 0.37, 0.72, 0.88))
	for x in range(COLS + 1):
		var px: float = origin.x + float(x) * CELL
		draw_line(Vector2(px, origin.y), Vector2(px, origin.y + float(ROWS) * CELL), Color(0.04, 0.20, 0.38, 0.58), 1.0)
	for y in range(ROWS + 1):
		var py: float = origin.y + float(y) * CELL
		draw_line(Vector2(origin.x, py), Vector2(origin.x + float(COLS) * CELL, py), Color(0.04, 0.20, 0.38, 0.58), 1.0)
	for y in range(ROWS):
		for x in range(COLS):
			var letter: String = _get_board_letter(x, y)
			if not letter.is_empty():
				_draw_tile(Vector2(float(x), float(y)), letter, origin, 1.0)
	if line_flash_timer > 0.0:
		var flash_alpha: float = clampf(line_flash_timer / 0.28, 0.0, 1.0) * 0.30
		for row_y in line_flash_rows:
			draw_rect(Rect2(origin.x, origin.y + float(row_y) * CELL, float(COLS) * CELL, CELL), Color(1.0, 0.86, 0.35, flash_alpha), true)
	if current_piece == null:
		return
	var ghost: Vector2i = _ghost_position()
	for cell in current_piece.cells:
		var ghost_pos: Vector2i = ghost + cell
		var ghost_rect: Rect2 = Rect2(origin + Vector2(float(ghost_pos.x), float(ghost_pos.y)) * CELL + Vector2(6.0, 6.0), Vector2(CELL - 12.0, CELL - 12.0))
		draw_rect(ghost_rect, Color(0.35, 0.79, 1.0, 0.07), true)
		draw_dashed_line(ghost_rect.position, ghost_rect.position + Vector2(ghost_rect.size.x, 0.0), Color(0.50, 0.86, 1.0, 0.72), 2.0, 6.0)
		draw_dashed_line(ghost_rect.position + Vector2(0.0, ghost_rect.size.y), ghost_rect.end, Color(0.50, 0.86, 1.0, 0.72), 2.0, 6.0)
	for i in range(current_piece.cells.size()):
		var cell: Vector2i = current_piece.cells[i]
		var draw_pos: Vector2 = visual_piece_pos + Vector2(cell)
		_draw_tile(draw_pos, current_piece.letters[i], origin, 1.0)


func _draw_tile(grid_pos: Vector2, letter: String, origin: Vector2, alpha: float) -> void:
	var rect: Rect2 = Rect2(origin + grid_pos * CELL + Vector2(2.0, 2.0), Vector2(CELL - 4.0, CELL - 4.0))
	var texture: Texture2D = _tile_texture_for_letter(letter)
	if texture == TILE_GOAL:
		var pulse: float = 0.18 + (sin(elapsed * 4.5) + 1.0) * 0.06
		draw_rect(rect.grow(4.0), Color(1.0, 0.72, 0.16, pulse * alpha), true)
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
	_draw_tile_letter(letter, rect, alpha)


func _tile_texture_for_letter(letter: String) -> Texture2D:
	if _is_needed_letter(letter):
		return TILE_GOAL
	if letter.is_empty():
		return TILE_NORMAL
	var code: int = letter.unicode_at(0)
	if code % 11 == 0:
		return TILE_DANGER
	match code % 4:
		1:
			return TILE_BONUS
		2:
			return TILE_SPECIAL
		_:
			return TILE_NORMAL


func _draw_right_panel() -> void:
	var x: float = PRESENT_X_SHIFT
	var panel: Rect2 = Rect2(990.0 + x, 94.0, 315.0, 452.0)
	draw_texture_rect(UI_SIDEBAR_RIGHT, panel, false)

	_draw_text_centered("Дальше", Rect2(1008.0 + x, 107.0, 279.0, 48.0), 21, Color(0.90, 0.94, 0.99))

	var preview_rect: Rect2 = Rect2(1031.0 + x, 158.0, 232.0, 232.0)
	draw_texture_rect(UI_SIDEBAR_INNER, preview_rect, false)
	_draw_next_piece(preview_rect)

	var hint_visual: Rect2 = Rect2(1022.0 + x, 410.0, 250.0, 86.0)
	draw_texture_rect(UI_HUD_BOX_LARGE, hint_visual, false)
	draw_texture_rect(ICON_HINT, Rect2(1042.0 + x, 436.0, 30.0, 30.0), false)
	_draw_text("Подсказка", Vector2(1083.0 + x, 460.0), 18, Color("ffe06a"))
	_draw_text("×%d" % hint_charges, Vector2(1230.0 + x, 460.0), 17, Color.WHITE)


func _draw_next_piece(rect: Rect2) -> void:
	if next_piece == null:
		return
	var preview_cell: float = 46.0
	var min_x: int = 99
	var max_x: int = -99
	var min_y: int = 99
	var max_y: int = -99
	for cell in next_piece.cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
	var width: float = float(max_x - min_x + 1) * preview_cell
	var height: float = float(max_y - min_y + 1) * preview_cell
	var start: Vector2 = rect.position + (rect.size - Vector2(width, height)) * 0.5
	for i in range(next_piece.cells.size()):
		var cell: Vector2i = next_piece.cells[i]
		var local_pos: Vector2 = Vector2(float(cell.x - min_x), float(cell.y - min_y))
		var tile_rect: Rect2 = Rect2(start + local_pos * preview_cell + Vector2(2.0, 2.0), Vector2(preview_cell - 4.0, preview_cell - 4.0))
		var letter: String = next_piece.letters[i]
		var texture: Texture2D = _tile_texture_for_letter(letter)
		draw_texture_rect(texture, tile_rect, false)
		_draw_tile_letter(letter, tile_rect, 1.0)


func _spawn_lock_fx(cells: Array[Vector2i]) -> void:
	for grid_pos in cells:
		var center: Vector2 = PRESENT_BOARD_ORIGIN + Vector2((float(grid_pos.x) + 0.5) * CELL, (float(grid_pos.y) + 0.5) * CELL)
		for _i in range(2):
			_spawn_particle(PARTICLE_SHARD, center, Vector2(rng.randf_range(-35.0, 35.0), rng.randf_range(-52.0, -18.0)), 0.28, rng.randf_range(5.0, 8.0), Color(0.45, 0.83, 1.0, 1.0))


func _spawn_line_fx(row_y: int) -> void:
	for x in range(COLS):
		var center: Vector2 = PRESENT_BOARD_ORIGIN + Vector2((float(x) + 0.5) * CELL, (float(row_y) + 0.5) * CELL)
		_spawn_particle(PARTICLE_SPARK, center, Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-90.0, -35.0)), 0.44, rng.randf_range(7.0, 11.0), Color(1.0, 0.83, 0.30, 1.0))


func _spawn_drop_trail(piece: Piece, from_pos: Vector2i, to_pos: Vector2i) -> void:
	var distance: int = to_pos.y - from_pos.y
	var steps: int = mini(6, maxi(2, floori(float(distance) / 2.0)))
	for step in range(steps):
		var t: float = float(step + 1) / float(steps + 1)
		for cell in piece.cells:
			var gx: float = float(from_pos.x + cell.x) + 0.5
			var gy: float = lerpf(float(from_pos.y + cell.y), float(to_pos.y + cell.y), t) + 0.5
			var pos: Vector2 = PRESENT_BOARD_ORIGIN + Vector2(gx * CELL, gy * CELL)
			_spawn_particle(PARTICLE_SPARK, pos, Vector2(0.0, -20.0), 0.20, 5.0, Color(0.45, 0.82, 1.0, 0.65))


func _spawn_flying_letter(letter: String, start: Vector2, slot_index: int) -> void:
	var flying: FlyingLetter = FlyingLetter.new()
	flying.letter = letter
	flying.start = start + Vector2(PRESENT_X_SHIFT, 0.0)
	flying.target = _word_slot_center(slot_index)
	flying_letters.append(flying)


func _word_slot_center(slot_index: int) -> Vector2:
	var slot_size: float = 54.0
	var gap: float = 7.0
	return PRESENT_WORD_ORIGIN + Vector2(float(slot_index) * (slot_size + gap) + slot_size * 0.5, slot_size * 0.5)


func _spawn_word_complete_fx() -> void:
	var center: Vector2 = Vector2(290.0 + PRESENT_X_SHIFT, 355.0)
	for _i in range(16):
		var angle: float = rng.randf_range(-PI, PI)
		var speed: float = rng.randf_range(55.0, 120.0)
		_spawn_particle(PARTICLE_SPARK, center, Vector2(cos(angle), sin(angle)) * speed, 0.62, rng.randf_range(6.0, 11.0), Color(1.0, 0.83, 0.28, 1.0))


func _draw_word_celebration() -> void:
	var alpha: float = clampf(word_flash_timer, 0.0, 1.0)
	var scale_bump: float = 1.0 + sin((1.0 - alpha) * PI) * 0.05
	var base_rect: Rect2 = Rect2(585.0 + PRESENT_X_SHIFT, 128.0, 300.0, 72.0)
	var size: Vector2 = base_rect.size * scale_bump
	var rect: Rect2 = Rect2(base_rect.get_center() - size * 0.5, size)
	_draw_panel(rect, Color(0.025, 0.18, 0.14, 0.92 * alpha), Color(0.35, 0.93, 0.57, 0.85 * alpha))
	_draw_text_centered("✓  %s   +600" % last_completed_word, rect, 23, Color(1.0, 1.0, 1.0, alpha))


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


func _draw_text_centered_bold(text: String, rect: Rect2, size: int, color: Color) -> void:
	var baseline_y: float = rect.position.y + rect.size.y * 0.5 + float(size) * 0.36
	var baseline: Vector2 = Vector2(rect.position.x, baseline_y)
	draw_string(presentation_font, baseline + Vector2(-0.45, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)
	draw_string(presentation_font, baseline + Vector2(0.45, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)
