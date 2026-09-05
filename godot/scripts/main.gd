extends Control

# Словопад — gameplay prototype.
# Все визуальные элементы сейчас рисуются кодом, чтобы проверить core loop
# до производства финальных ассетов.

const BASE_SIZE := Vector2(1600.0, 900.0)
const COLS := 10
const ROWS := 18
const CELL := 40.0

const ALPHABET := "АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯ"
const WORDS := ["ВОЛК", "СОСНА", "ГРИБ", "ЕЛЬ", "ЛИСА"]
const CLUES := [
	"Лесной хищник",
	"Хвойное дерево",
	"Растёт под деревьями",
	"Хвойное дерево",
	"Рыжая лесная охотница"
]

# Классические 7 фигур. Храним координаты как массивы чисел,
# чтобы prototype не зависел от внешних ресурсов.
const SHAPE_DATA := [
	[[0, 0], [1, 0], [0, 1], [1, 1]],
	[[0, 0], [1, 0], [2, 0], [3, 0]],
	[[0, 0], [1, 0], [2, 0], [1, 1]],
	[[0, 0], [0, 1], [0, 2], [1, 2]],
	[[1, 0], [1, 1], [1, 2], [0, 2]],
	[[1, 0], [2, 0], [0, 1], [1, 1]],
	[[0, 0], [1, 0], [1, 1], [2, 1]]
]

var rng := RandomNumberGenerator.new()
var board: Array = []
var current_piece: Dictionary = {}
var next_piece: Dictionary = {}

var word_index := 0
var word_progress: Array = []
var revealed_slots: Dictionary = {}
var completed_words: Array[String] = []

var score := 0
var combo := 0
var best_combo := 0
var total_lines := 0
var elapsed := 0.0
var drop_accumulator := 0.0
var pieces_without_goal := 0
var hint_charges := 3

var paused := false
var game_over := false
var chapter_complete := false

var stars: Array[Vector2] = []


func _ready() -> void:
	rng.randomize()
	_build_stars()
	_reset_game()
	queue_redraw()


func _process(delta: float) -> void:
	if paused or game_over or chapter_complete:
		queue_redraw()
		return

	elapsed += delta
	drop_accumulator += delta

	if drop_accumulator >= _drop_interval():
		drop_accumulator = 0.0
		if not _try_move(Vector2i(0, 1)):
			_lock_piece()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if not event.pressed:
		return

	if game_over or chapter_complete:
		if event.keycode == KEY_R:
			_reset_game()
		return

	if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
		paused = not paused
		queue_redraw()
		return

	if paused:
		return

	match event.keycode:
		KEY_LEFT, KEY_A:
			_try_move(Vector2i(-1, 0))
		KEY_RIGHT, KEY_D:
			_try_move(Vector2i(1, 0))
		KEY_DOWN, KEY_S:
			if _try_move(Vector2i(0, 1)):
				score += 1
			else:
				_lock_piece()
		KEY_UP, KEY_W:
			_try_rotate()
		KEY_SPACE:
			_hard_drop()
		KEY_H:
			_use_hint()

	queue_redraw()


func _reset_game() -> void:
	board.clear()
	for _y in range(ROWS):
		board.append(_empty_row())

	word_index = 0
	completed_words.clear()
	score = 0
	combo = 0
	best_combo = 0
	total_lines = 0
	elapsed = 0.0
	drop_accumulator = 0.0
	pieces_without_goal = 0
	hint_charges = 3
	paused = false
	game_over = false
	chapter_complete = false

	_reset_word_state()
	current_piece = _make_piece()
	next_piece = _make_piece()

	if not _can_place(current_piece["cells"], current_piece["pos"]):
		game_over = true

	queue_redraw()


func _reset_word_state() -> void:
	word_progress.clear()
	revealed_slots.clear()

	var word := _current_word()
	for _i in range(word.length()):
		word_progress.append(false)

	# На лёгкой первой главе показываем часть слова заранее.
	# Подсказка H раскрывает дополнительные символы, но не засчитывает их.
	if word.length() > 0:
		revealed_slots[0] = true
	if word.length() >= 4:
		revealed_slots[word.length() - 1] = true


func _empty_row() -> Array:
	var row: Array = []
	for _x in range(COLS):
		row.append(null)
	return row


func _make_piece() -> Dictionary:
	var template: Array = SHAPE_DATA[rng.randi_range(0, SHAPE_DATA.size() - 1)]
	var cells: Array[Vector2i] = []
	for pair in template:
		cells.append(Vector2i(int(pair[0]), int(pair[1])))

	var letters: Array[String] = []
	var missing := _missing_letters()
	var goal_slot := -1

	if not missing.is_empty():
		var force_goal := pieces_without_goal >= 2
		if force_goal or rng.randf() < 0.35:
			goal_slot = rng.randi_range(0, cells.size() - 1)
			pieces_without_goal = 0
		else:
			pieces_without_goal += 1

	for i in range(cells.size()):
		if i == goal_slot and not missing.is_empty():
			letters.append(missing[rng.randi_range(0, missing.size() - 1)])
		else:
			var index := rng.randi_range(0, ALPHABET.length() - 1)
			letters.append(ALPHABET.substr(index, 1))

	return {
		"cells": cells,
		"letters": letters,
		"pos": Vector2i(3, 0)
	}


func _current_word() -> String:
	return WORDS[word_index]


func _missing_letters() -> Array[String]:
	var result: Array[String] = []
	var word := _current_word()

	for i in range(word.length()):
		if not word_progress[i]:
			result.append(word.substr(i, 1))

	return result


func _is_needed_letter(letter: String) -> bool:
	var word := _current_word()
	for i in range(word.length()):
		if not word_progress[i] and word.substr(i, 1) == letter:
			return true
	return false


func _collect_letter(letter: String) -> bool:
	var word := _current_word()
	for i in range(word.length()):
		if not word_progress[i] and word.substr(i, 1) == letter:
			word_progress[i] = true
			return true
	return false


func _is_word_complete() -> bool:
	for value in word_progress:
		if not value:
			return false
	return true


func _complete_word() -> void:
	var completed := _current_word()
	completed_words.append(completed)
	score += 500 + combo * 100

	if completed_words.size() >= WORDS.size():
		chapter_complete = true
		return

	word_index += 1
	_reset_word_state()


func _drop_interval() -> float:
	var progression := completed_words.size() * 0.07
	return max(0.18, 0.72 - progression)


func _can_place(cells: Array, pos: Vector2i) -> bool:
	for cell in cells:
		var gx := pos.x + cell.x
		var gy := pos.y + cell.y

		if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS:
			return false
		if board[gy][gx] != null:
			return false

	return true


func _try_move(delta: Vector2i) -> bool:
	var new_pos: Vector2i = current_piece["pos"] + delta
	if _can_place(current_piece["cells"], new_pos):
		current_piece["pos"] = new_pos
		return true
	return false


func _try_rotate() -> void:
	var rotated: Array[Vector2i] = []
	var min_x := 999
	var min_y := 999

	for cell in current_piece["cells"]:
		var rotated_cell := Vector2i(-cell.y, cell.x)
		rotated.append(rotated_cell)
		min_x = min(min_x, rotated_cell.x)
		min_y = min(min_y, rotated_cell.y)

	var normalize := Vector2i(min_x, min_y)
	for i in range(rotated.size()):
		rotated[i] -= normalize

	var kicks := [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(2, 0)]
	for kick in kicks:
		var test_pos: Vector2i = current_piece["pos"] + kick
		if _can_place(rotated, test_pos):
			current_piece["cells"] = rotated
			current_piece["pos"] = test_pos
			return


func _hard_drop() -> void:
	var distance := 0
	while _try_move(Vector2i(0, 1)):
		distance += 1
	score += distance * 2
	_lock_piece()


func _lock_piece() -> void:
	var cells: Array = current_piece["cells"]
	var letters: Array = current_piece["letters"]
	var pos: Vector2i = current_piece["pos"]

	for i in range(cells.size()):
		var gx := pos.x + cells[i].x
		var gy := pos.y + cells[i].y
		if gy < 0 or gy >= ROWS or gx < 0 or gx >= COLS:
			game_over = true
			return
		board[gy][gx] = {"letter": letters[i]}

	_clear_full_lines()

	if chapter_complete:
		return

	current_piece = next_piece.duplicate(true)
	current_piece["pos"] = Vector2i(3, 0)
	next_piece = _make_piece()
	drop_accumulator = 0.0

	if not _can_place(current_piece["cells"], current_piece["pos"]):
		game_over = true


func _clear_full_lines() -> void:
	var full_rows: Array[int] = []

	for y in range(ROWS):
		var full := true
		for x in range(COLS):
			if board[y][x] == null:
				full = false
				break
		if full:
			full_rows.append(y)

	if full_rows.is_empty():
		return

	var useful_letters := 0
	for y in full_rows:
		for x in range(COLS):
			var cell: Dictionary = board[y][x]
			if _collect_letter(String(cell["letter"])):
				useful_letters += 1

	for i in range(full_rows.size() - 1, -1, -1):
		board.remove_at(full_rows[i])
		board.push_front(_empty_row())

	total_lines += full_rows.size()
	score += full_rows.size() * 100 + useful_letters * 50

	if useful_letters > 0:
		combo += 1
		best_combo = max(best_combo, combo)
	else:
		combo = 0

	if _is_word_complete():
		_complete_word()


func _use_hint() -> void:
	if hint_charges <= 0:
		return

	var candidates: Array[int] = []
	for i in range(_current_word().length()):
		if not word_progress[i] and not revealed_slots.has(i):
			candidates.append(i)

	if candidates.is_empty():
		return

	var chosen := candidates[rng.randi_range(0, candidates.size() - 1)]
	revealed_slots[chosen] = true
	hint_charges -= 1


func _ghost_position() -> Vector2i:
	var ghost: Vector2i = current_piece["pos"]
	while _can_place(current_piece["cells"], ghost + Vector2i(0, 1)):
		ghost += Vector2i(0, 1)
	return ghost


func _build_stars() -> void:
	var star_rng := RandomNumberGenerator.new()
	star_rng.seed = 90210
	stars.clear()
	for _i in range(80):
		stars.append(Vector2(star_rng.randf_range(0.0, BASE_SIZE.x), star_rng.randf_range(0.0, BASE_SIZE.y * 0.72)))


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor := min(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	var draw_size := BASE_SIZE * scale_factor
	var offset := (viewport_size - draw_size) * 0.5

	draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))

	_draw_background()
	_draw_top_hud()
	_draw_left_panel()
	_draw_board()
	_draw_right_panel()
	_draw_controls()

	if paused:
		_draw_overlay("Пауза", "P / Esc — продолжить")
	elif game_over:
		_draw_overlay("Поражение", "R — начать заново")
	elif chapter_complete:
		_draw_overlay("Глава завершена!", "Собрано 5 / 5 слов   •   R — сыграть ещё раз")


func _draw_background() -> void:
	var top := Color("07152f")
	var bottom := Color("0b3156")
	var bands := 18
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var rect := Rect2(0.0, BASE_SIZE.y * t, BASE_SIZE.x, BASE_SIZE.y / bands + 2.0)
		draw_rect(rect, top.lerp(bottom, t), true)

	for star in stars:
		draw_circle(star, 1.4, Color(0.72, 0.88, 1.0, 0.7))

	# Условные силуэты леса — временная procedural-заглушка до background_forest.webp.
	for i in range(20):
		var x := float(i) * 84.0 - 40.0
		var h := 90.0 + float((i * 37) % 80)
		var base_y := 900.0
		var points := PackedVector2Array([
			Vector2(x, base_y),
			Vector2(x + 42.0, base_y - h),
			Vector2(x + 84.0, base_y)
		])
		draw_colored_polygon(points, Color(0.015, 0.075, 0.12, 0.82))

	# Лёгкое затемнение центральной рабочей зоны.
	draw_rect(Rect2(95, 75, 1390, 750), Color(0.0, 0.03, 0.09, 0.22), true)


func _draw_top_hud() -> void:
	_draw_stat_box(Rect2(1015, 22, 170, 58), "♛", str(score), Color("ffd253"))
	_draw_stat_box(Rect2(1198, 22, 145, 58), "⚡", "x%d" % max(combo, 1), Color("ffc33b"))
	_draw_stat_box(Rect2(1356, 22, 155, 58), "◷", _format_time(), Color.WHITE)

	_draw_button_box(Rect2(1530, 22, 54, 58), "Ⅱ")
	_draw_button_box(Rect2(32, 22, 54, 58), "⚙")


func _draw_left_panel() -> void:
	var panel := Rect2(128, 100, 350, 710)
	_draw_panel(panel, Color(0.025, 0.095, 0.19, 0.94), Color(0.08, 0.45, 0.85, 0.65))

	_draw_text("Глава 1", Vector2(170, 145), 21, Color(0.77, 0.86, 1.0))
	_draw_text("Лес", Vector2(170, 184), 34, Color("74e58e"))
	_draw_text("%d / %d слов" % [completed_words.size(), WORDS.size()], Vector2(170, 220), 22, Color("7af09a"))

	# Progress bar.
	draw_rect(Rect2(170, 238, 265, 16), Color(0.02, 0.055, 0.12, 0.9), true)
	var ratio := float(completed_words.size()) / float(WORDS.size())
	draw_rect(Rect2(170, 238, 265.0 * ratio, 16), Color("55d979"), true)

	draw_line(Vector2(150, 278), Vector2(455, 278), Color(0.18, 0.45, 0.72, 0.45), 1.0)
	_draw_text("Текущее слово", Vector2(150, 313), 22, Color.WHITE)
	_draw_current_word(Vector2(150, 330))
	_draw_text(CLUES[word_index], Vector2(150, 430), 19, Color(0.78, 0.86, 0.98))

	draw_line(Vector2(150, 462), Vector2(455, 462), Color(0.18, 0.45, 0.72, 0.45), 1.0)
	_draw_text("Собрано", Vector2(150, 493), 18, Color(0.62, 0.74, 0.9))

	var y := 515.0
	if completed_words.is_empty():
		_draw_text("Пока нет завершённых слов", Vector2(150, y + 26), 17, Color(0.45, 0.58, 0.74))
	else:
		for word in completed_words.slice(max(0, completed_words.size() - 3), completed_words.size()):
			_draw_text("✓  " + word, Vector2(158, y + 28), 20, Color("70e68f"))
			y += 42.0

	# Contextual hint — без декоративной вывески и без фальшивых кнопок.
	var hint_rect := Rect2(148, 690, 310, 92)
	_draw_panel(hint_rect, Color(0.03, 0.12, 0.23, 0.96), Color(0.18, 0.42, 0.65, 0.6))
	_draw_text("Подсказка", Vector2(170, 720), 18, Color("ffd65b"))
	_draw_text("Проведи нужную букву", Vector2(170, 747), 17, Color.WHITE)
	_draw_text("в заполненную линию.", Vector2(170, 772), 17, Color.WHITE)


func _draw_current_word(origin: Vector2) -> void:
	var word := _current_word()
	var slot_size := 58.0
	var gap := 8.0

	for i in range(word.length()):
		var rect := Rect2(origin.x + i * (slot_size + gap), origin.y, slot_size, slot_size)
		var collected: bool = word_progress[i]
		var revealed: bool = revealed_slots.has(i)

		var fill := Color(0.025, 0.09, 0.19, 1.0)
		var border := Color(0.18, 0.46, 0.82, 0.8)
		if collected:
			fill = Color(0.04, 0.33, 0.52, 1.0)
			border = Color("65d9ff")

		_draw_panel(rect, fill, border)
		var value := "_"
		if collected or revealed:
			value = word.substr(i, 1)
		var color := Color.WHITE if collected else Color(0.82, 0.9, 1.0)
		_draw_text_centered(value, rect, 34, color)


func _draw_board() -> void:
	var origin := Vector2(535, 92)
	var board_rect := Rect2(origin.x - 8, origin.y - 8, COLS * CELL + 16, ROWS * CELL + 16)
	_draw_panel(board_rect, Color(0.015, 0.06, 0.14, 0.97), Color(0.06, 0.44, 0.83, 0.85))

	for x in range(COLS + 1):
		var px := origin.x + x * CELL
		draw_line(Vector2(px, origin.y), Vector2(px, origin.y + ROWS * CELL), Color(0.05, 0.25, 0.46, 0.55), 1.0)
	for y in range(ROWS + 1):
		var py := origin.y + y * CELL
		draw_line(Vector2(origin.x, py), Vector2(origin.x + COLS * CELL, py), Color(0.05, 0.25, 0.46, 0.55), 1.0)

	for y in range(ROWS):
		for x in range(COLS):
			if board[y][x] != null:
				var cell: Dictionary = board[y][x]
				_draw_tile(Vector2i(x, y), String(cell["letter"]), origin, 1.0)

	if current_piece.is_empty():
		return

	var ghost := _ghost_position()
	for cell in current_piece["cells"]:
		var grid_pos: Vector2i = ghost + cell
		var rect := Rect2(origin + Vector2(grid_pos.x, grid_pos.y) * CELL + Vector2(4, 4), Vector2(CELL - 8, CELL - 8))
		draw_rect(rect, Color(0.24, 0.75, 1.0, 0.10), true)
		draw_rect(rect, Color(0.38, 0.82, 1.0, 0.7), false, 2.0)

	var cells: Array = current_piece["cells"]
	var letters: Array = current_piece["letters"]
	var pos: Vector2i = current_piece["pos"]
	for i in range(cells.size()):
		_draw_tile(pos + cells[i], String(letters[i]), origin, 1.0)


func _draw_tile(grid_pos: Vector2i, letter: String, origin: Vector2, alpha: float) -> void:
	var rect := Rect2(origin + Vector2(grid_pos.x, grid_pos.y) * CELL + Vector2(2.0, 2.0), Vector2(CELL - 4.0, CELL - 4.0))
	var goal := _is_needed_letter(letter)
	var fill := Color(0.035, 0.46, 0.91, alpha)
	var border := Color(0.18, 0.75, 1.0, alpha)

	if goal:
		fill = Color(0.96, 0.57, 0.06, alpha)
		border = Color(1.0, 0.88, 0.35, alpha)
		var glow_rect := rect.grow(4.0)
		draw_rect(glow_rect, Color(1.0, 0.68, 0.12, 0.12 * alpha), true)

	_draw_panel(rect, fill, border)
	_draw_text_centered(letter, rect, 25, Color(1, 1, 1, alpha))


func _draw_right_panel() -> void:
	var panel := Rect2(985, 100, 325, 500)
	_draw_panel(panel, Color(0.025, 0.095, 0.19, 0.95), Color(0.08, 0.45, 0.85, 0.65))

	_draw_text("Следующая фигура", Vector2(1015, 148), 23, Color.WHITE)
	var preview_rect := Rect2(1015, 170, 265, 210)
	_draw_panel(preview_rect, Color(0.012, 0.055, 0.125, 0.96), Color(0.12, 0.38, 0.67, 0.7))
	_draw_next_piece(preview_rect)

	draw_line(Vector2(1015, 405), Vector2(1280, 405), Color(0.18, 0.45, 0.72, 0.4), 1.0)

	_draw_text("Подсказка  [H]", Vector2(1015, 450), 21, Color("ffe06a"))
	_draw_text("Осталось: %d" % hint_charges, Vector2(1015, 482), 18, Color.WHITE)
	_draw_text("Раскрывает символ,", Vector2(1015, 522), 17, Color(0.7, 0.8, 0.94))
	_draw_text("но букву всё равно", Vector2(1015, 546), 17, Color(0.7, 0.8, 0.94))
	_draw_text("нужно добыть в линии.", Vector2(1015, 570), 17, Color(0.7, 0.8, 0.94))


func _draw_next_piece(rect: Rect2) -> void:
	if next_piece.is_empty():
		return

	var cells: Array = next_piece["cells"]
	var letters: Array = next_piece["letters"]
	var preview_cell := 44.0
	var min_x := 99
	var max_x := -99
	var min_y := 99
	var max_y := -99

	for cell in cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)

	var width := float(max_x - min_x + 1) * preview_cell
	var height := float(max_y - min_y + 1) * preview_cell
	var start := rect.position + (rect.size - Vector2(width, height)) * 0.5

	for i in range(cells.size()):
		var local := Vector2(cells[i].x - min_x, cells[i].y - min_y)
		var tile_rect := Rect2(start + local * preview_cell + Vector2(2, 2), Vector2(preview_cell - 4, preview_cell - 4))
		var letter := String(letters[i])
		var fill := Color(0.08, 0.68, 0.35, 1.0)
		var border := Color(0.3, 0.95, 0.55, 0.9)
		if _is_needed_letter(letter):
			fill = Color(0.96, 0.57, 0.06, 1.0)
			border = Color(1.0, 0.88, 0.35, 1.0)
		_draw_panel(tile_rect, fill, border)
		_draw_text_centered(letter, tile_rect, 25, Color.WHITE)


func _draw_controls() -> void:
	_draw_text("← → / A D — движение    ↑ / W — поворот    ↓ / S — ускорить    Space — сбросить    P — пауза", Vector2(535, 848), 16, Color(0.57, 0.69, 0.84))


func _draw_overlay(title: String, subtitle: String) -> void:
	draw_rect(Rect2(0, 0, BASE_SIZE.x, BASE_SIZE.y), Color(0.0, 0.01, 0.04, 0.68), true)
	var rect := Rect2(505, 330, 590, 220)
	_draw_panel(rect, Color(0.025, 0.08, 0.17, 0.99), Color(0.12, 0.55, 0.92, 0.85))
	_draw_text_centered(title, Rect2(rect.position.x, rect.position.y + 42, rect.size.x, 64), 38, Color.WHITE)
	_draw_text_centered(subtitle, Rect2(rect.position.x, rect.position.y + 124, rect.size.x, 44), 20, Color(0.72, 0.82, 0.96))


func _draw_stat_box(rect: Rect2, icon: String, value: String, accent: Color) -> void:
	_draw_panel(rect, Color(0.025, 0.085, 0.17, 0.94), Color(0.08, 0.37, 0.68, 0.72))
	_draw_text(icon, Vector2(rect.position.x + 16, rect.position.y + 39), 25, accent)
	_draw_text(value, Vector2(rect.position.x + 54, rect.position.y + 39), 25, Color.WHITE)


func _draw_button_box(rect: Rect2, text: String) -> void:
	_draw_panel(rect, Color(0.025, 0.085, 0.17, 0.94), Color(0.08, 0.37, 0.68, 0.72))
	_draw_text_centered(text, rect, 27, Color.WHITE)


func _draw_panel(rect: Rect2, fill: Color, border: Color) -> void:
	# Prototype намеренно использует почти прямоугольные панели.
	# В production будет небольшой единый radius через Theme/StyleBoxFlat.
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0)


func _draw_text(text: String, baseline: Vector2, size: int, color: Color) -> void:
	draw_string(get_theme_default_font(), baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _draw_text_centered(text: String, rect: Rect2, size: int, color: Color) -> void:
	var baseline_y := rect.position.y + rect.size.y * 0.5 + float(size) * 0.36
	draw_string(get_theme_default_font(), Vector2(rect.position.x, baseline_y), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)


func _format_time() -> String:
	var total := int(elapsed)
	var minutes := floori(float(total) / 60.0)
	var seconds := total % 60
	return "%02d:%02d" % [minutes, seconds]
