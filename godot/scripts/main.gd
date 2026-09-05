extends Control

# Словопад — desktop-first gameplay prototype.
# Visuals are intentionally procedural until the core loop is approved.

const BASE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const COLS: int = 10
const ROWS: int = 16
const CELL: float = 44.0

const ALPHABET: String = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
const WORDS: Array[String] = ["ВОЛК", "СОСНА", "ГРИБ", "ЕЛЬ", "ЛИСА"]
const CLUES: Array[String] = [
	"Лесной хищник",
	"Хвойное дерево",
	"Растёт под деревьями",
	"Хвойное дерево",
	"Рыжая лесная охотница"
]

# In chapter 1 each word has only one missing letter. Later chapters can use 2–3.
const WORD_GAPS: Array = [
	[1], # В _ Л К
	[2], # С О _ Н А
	[1], # Г _ И Б
	[1], # Е _ Ь
	[2]  # Л И _ А
]

const SHAPES: Array = [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
]

const TILE_PALETTE: Array[Color] = [
	Color("1687f8"),
	Color("2dc46d"),
	Color("ef5057"),
	Color("f4aa2f"),
	Color("7656e8")
]

const SETTINGS_RECT: Rect2 = Rect2(32.0, 22.0, 56.0, 58.0)
const PAUSE_RECT: Rect2 = Rect2(1518.0, 22.0, 56.0, 58.0)
const HINT_RECT: Rect2 = Rect2(1008.0, 430.0, 286.0, 120.0)


class Piece:
	var cells: Array[Vector2i] = []
	var letters: Array[String] = []
	var pos: Vector2i = Vector2i(3, 0)


var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var board: Array[String] = []
var current_piece: Piece = null
var next_piece: Piece = null

var word_index: int = 0
var word_progress: Array[bool] = []
var hint_revealed_slots: Dictionary = {}
var completed_words: Array[String] = []

var score: int = 0
var combo: int = 0
var best_combo: int = 0
var total_lines: int = 0
var elapsed: float = 0.0
var drop_accumulator: float = 0.0
var pieces_without_goal: int = 0
var hint_charges: int = 3

var paused: bool = false
var game_over: bool = false
var chapter_complete: bool = false
var tutorial_complete: bool = false

var last_completed_word: String = ""
var word_flash_timer: float = 0.0
var stars: Array[Vector2] = []


func _ready() -> void:
	rng.randomize()
	_build_stars()
	_reset_game()
	queue_redraw()


func _process(delta: float) -> void:
	if word_flash_timer > 0.0:
		word_flash_timer = maxf(0.0, word_flash_timer - delta)

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
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		_handle_key(key_event.keycode)
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_click(_screen_to_base(mouse_event.position))


func _handle_key(keycode: int) -> void:
	if game_over or chapter_complete:
		if keycode == KEY_R:
			_reset_game()
		return

	if keycode == KEY_P or keycode == KEY_ESCAPE:
		paused = not paused
		queue_redraw()
		return

	if paused:
		return

	match keycode:
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


func _handle_click(base_pos: Vector2) -> void:
	if PAUSE_RECT.has_point(base_pos):
		if not game_over and not chapter_complete:
			paused = not paused
			queue_redraw()
		return

	if HINT_RECT.has_point(base_pos) and not paused and not game_over and not chapter_complete:
		_use_hint()
		queue_redraw()
		return


func _screen_to_base(screen_pos: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	if scale_factor <= 0.0:
		return screen_pos
	var draw_size: Vector2 = BASE_SIZE * scale_factor
	var offset: Vector2 = (viewport_size - draw_size) * 0.5
	return (screen_pos - offset) / scale_factor


func _reset_game() -> void:
	_reset_board()
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
	tutorial_complete = false
	last_completed_word = ""
	word_flash_timer = 0.0

	_reset_word_state()
	current_piece = _make_piece()
	next_piece = _make_piece()

	if not _can_place(current_piece.cells, current_piece.pos):
		game_over = true

	queue_redraw()


func _reset_board() -> void:
	board.clear()
	board.resize(COLS * ROWS)
	board.fill("")


func _reset_word_state() -> void:
	word_progress.clear()
	hint_revealed_slots.clear()
	pieces_without_goal = 0

	var word: String = _current_word()
	for _i in range(word.length()):
		word_progress.append(true)

	var gap_indices: Array = WORD_GAPS[word_index]
	for raw_index in gap_indices:
		var gap_index: int = int(raw_index)
		if gap_index >= 0 and gap_index < word_progress.size():
			word_progress[gap_index] = false


func _current_word() -> String:
	return WORDS[word_index]


func _missing_letters() -> Array[String]:
	var result: Array[String] = []
	var word: String = _current_word()
	for i in range(word.length()):
		if not word_progress[i]:
			result.append(word.substr(i, 1))
	return result


func _make_piece() -> Piece:
	var piece: Piece = Piece.new()
	var shape_index: int = rng.randi_range(0, SHAPES.size() - 1)
	var template: Array = SHAPES[shape_index]

	for raw_cell in template:
		var cell: Vector2i = raw_cell
		piece.cells.append(cell)

	var missing: Array[String] = _missing_letters()
	var goal_slot: int = -1
	if not missing.is_empty():
		var force_goal: bool = pieces_without_goal >= 2
		if force_goal or rng.randf() < 0.42:
			goal_slot = rng.randi_range(0, piece.cells.size() - 1)
			pieces_without_goal = 0
		else:
			pieces_without_goal += 1

	for i in range(piece.cells.size()):
		if i == goal_slot and not missing.is_empty():
			var target_index: int = rng.randi_range(0, missing.size() - 1)
			piece.letters.append(missing[target_index])
		else:
			var alphabet_index: int = rng.randi_range(0, ALPHABET.length() - 1)
			piece.letters.append(ALPHABET.substr(alphabet_index, 1))

	piece.pos = Vector2i(3, 0)
	return piece


func _drop_interval() -> float:
	var progression: float = float(completed_words.size()) * 0.06
	return maxf(0.26, 0.78 - progression)


func _board_index(x: int, y: int) -> int:
	return y * COLS + x


func _get_board_letter(x: int, y: int) -> String:
	return board[_board_index(x, y)]


func _set_board_letter(x: int, y: int, letter: String) -> void:
	board[_board_index(x, y)] = letter


func _can_place(cells: Array[Vector2i], pos: Vector2i) -> bool:
	for cell in cells:
		var gx: int = pos.x + cell.x
		var gy: int = pos.y + cell.y
		if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS:
			return false
		if not _get_board_letter(gx, gy).is_empty():
			return false
	return true


func _try_move(delta: Vector2i) -> bool:
	if current_piece == null:
		return false
	var new_pos: Vector2i = current_piece.pos + delta
	if _can_place(current_piece.cells, new_pos):
		current_piece.pos = new_pos
		return true
	return false


func _try_rotate() -> void:
	if current_piece == null:
		return

	var rotated: Array[Vector2i] = []
	var min_x: int = 999
	var min_y: int = 999

	for cell in current_piece.cells:
		var rotated_cell: Vector2i = Vector2i(-cell.y, cell.x)
		rotated.append(rotated_cell)
		min_x = mini(min_x, rotated_cell.x)
		min_y = mini(min_y, rotated_cell.y)

	var normalize: Vector2i = Vector2i(min_x, min_y)
	for i in range(rotated.size()):
		rotated[i] -= normalize

	var kicks: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-2, 0),
		Vector2i(2, 0)
	]
	for kick in kicks:
		var test_pos: Vector2i = current_piece.pos + kick
		if _can_place(rotated, test_pos):
			current_piece.cells = rotated
			current_piece.pos = test_pos
			return


func _hard_drop() -> void:
	if current_piece == null:
		return
	var distance: int = 0
	while _try_move(Vector2i(0, 1)):
		distance += 1
	score += distance * 2
	_lock_piece()


func _lock_piece() -> void:
	if current_piece == null:
		return

	for i in range(current_piece.cells.size()):
		var cell: Vector2i = current_piece.cells[i]
		var gx: int = current_piece.pos.x + cell.x
		var gy: int = current_piece.pos.y + cell.y
		if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS:
			game_over = true
			return
		_set_board_letter(gx, gy, current_piece.letters[i])

	_clear_full_lines()
	if chapter_complete:
		return

	current_piece = next_piece
	next_piece = _make_piece()
	drop_accumulator = 0.0

	if current_piece == null or not _can_place(current_piece.cells, current_piece.pos):
		game_over = true


func _is_row_full(y: int) -> bool:
	for x in range(COLS):
		if _get_board_letter(x, y).is_empty():
			return false
	return true


func _clear_full_lines() -> void:
	var full_rows: Array[int] = []
	for y in range(ROWS):
		if _is_row_full(y):
			full_rows.append(y)

	if full_rows.is_empty():
		return

	var useful_letters: int = 0
	for y in full_rows:
		for x in range(COLS):
			var letter: String = _get_board_letter(x, y)
			if _collect_letter(letter):
				useful_letters += 1

	_collapse_rows(full_rows)
	total_lines += full_rows.size()
	score += full_rows.size() * 100 + useful_letters * 75

	if useful_letters > 0:
		combo += 1
		best_combo = maxi(best_combo, combo)
		tutorial_complete = true
	else:
		combo = 0

	if _is_word_complete():
		_complete_word()


func _collapse_rows(full_rows: Array[int]) -> void:
	var new_board: Array[String] = []
	new_board.resize(COLS * ROWS)
	new_board.fill("")

	var write_y: int = ROWS - 1
	for read_y in range(ROWS - 1, -1, -1):
		if full_rows.has(read_y):
			continue
		for x in range(COLS):
			new_board[write_y * COLS + x] = _get_board_letter(x, read_y)
		write_y -= 1

	board = new_board


func _collect_letter(letter: String) -> bool:
	var word: String = _current_word()
	for i in range(word.length()):
		if not word_progress[i] and word.substr(i, 1) == letter:
			word_progress[i] = true
			return true
	return false


func _is_word_complete() -> bool:
	for collected in word_progress:
		if not collected:
			return false
	return true


func _complete_word() -> void:
	last_completed_word = _current_word()
	completed_words.append(last_completed_word)
	score += 500 + combo * 100
	word_flash_timer = 1.0

	if completed_words.size() >= WORDS.size():
		chapter_complete = true
		return

	word_index += 1
	_reset_word_state()


func _is_needed_letter(letter: String) -> bool:
	var word: String = _current_word()
	for i in range(word.length()):
		if not word_progress[i] and word.substr(i, 1) == letter:
			return true
	return false


func _use_hint() -> void:
	if hint_charges <= 0:
		return

	var candidates: Array[int] = []
	for i in range(_current_word().length()):
		if not word_progress[i] and not hint_revealed_slots.has(i):
			candidates.append(i)

	if candidates.is_empty():
		return

	var chosen_index: int = rng.randi_range(0, candidates.size() - 1)
	var chosen_slot: int = candidates[chosen_index]
	hint_revealed_slots[chosen_slot] = true
	hint_charges -= 1


func _ghost_position() -> Vector2i:
	if current_piece == null:
		return Vector2i.ZERO
	var ghost: Vector2i = current_piece.pos
	while _can_place(current_piece.cells, ghost + Vector2i(0, 1)):
		ghost += Vector2i(0, 1)
	return ghost


func _build_stars() -> void:
	var star_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	star_rng.seed = 90210
	stars.clear()
	for _i in range(90):
		stars.append(Vector2(
			star_rng.randf_range(0.0, BASE_SIZE.x),
			star_rng.randf_range(0.0, BASE_SIZE.y * 0.58)
		))


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	var draw_size: Vector2 = BASE_SIZE * scale_factor
	var offset: Vector2 = (viewport_size - draw_size) * 0.5
	draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))

	_draw_background()
	_draw_top_hud()
	_draw_left_panel()
	_draw_board()
	_draw_right_panel()
	_draw_controls()

	if word_flash_timer > 0.0 and not last_completed_word.is_empty() and not chapter_complete:
		_draw_word_celebration()

	if paused:
		_draw_overlay("Пауза", "P / Esc — продолжить")
	elif game_over:
		_draw_overlay("Поражение", "R — начать заново")
	elif chapter_complete:
		_draw_overlay("Глава завершена!", "Собрано 5 / 5 слов   •   R — сыграть ещё раз")


func _draw_background() -> void:
	var top: Color = Color("06142e")
	var bottom: Color = Color("0a3856")
	var bands: int = 20
	for i in range(bands):
		var t: float = float(i) / float(bands - 1)
		var band_rect: Rect2 = Rect2(0.0, BASE_SIZE.y * t, BASE_SIZE.x, BASE_SIZE.y / float(bands) + 2.0)
		draw_rect(band_rect, top.lerp(bottom, t), true)

	for star in stars:
		draw_circle(star, 1.3, Color(0.72, 0.88, 1.0, 0.72))

	# Moon and distant mountains — procedural placeholders only.
	draw_circle(Vector2(1472.0, 168.0), 52.0, Color(1.0, 0.9, 0.58, 0.96))
	draw_colored_polygon(PackedVector2Array([
		Vector2(1180.0, 610.0), Vector2(1405.0, 260.0), Vector2(1600.0, 610.0)
	]), Color(0.035, 0.12, 0.24, 0.95))
	draw_colored_polygon(PackedVector2Array([
		Vector2(980.0, 610.0), Vector2(1240.0, 335.0), Vector2(1500.0, 610.0)
	]), Color(0.025, 0.09, 0.18, 0.95))

	# Lake.
	draw_rect(Rect2(0.0, 610.0, BASE_SIZE.x, 290.0), Color(0.025, 0.20, 0.31, 0.82), true)
	for i in range(14):
		var y: float = 630.0 + float(i) * 17.0
		var alpha: float = 0.08 + float(i % 3) * 0.025
		draw_line(Vector2(960.0, y), Vector2(1600.0, y + 3.0), Color(0.28, 0.64, 0.86, alpha), 2.0)

	# Forest silhouettes.
	for i in range(24):
		var x: float = float(i) * 72.0 - 45.0
		var tree_h: float = 92.0 + float((i * 41) % 95)
		_draw_tree_silhouette(Vector2(x, 900.0), tree_h)

	# Darken the UI working zone slightly.
	draw_rect(Rect2(92.0, 78.0, 1240.0, 755.0), Color(0.0, 0.025, 0.08, 0.16), true)


func _draw_tree_silhouette(base: Vector2, height: float) -> void:
	var half_width: float = height * 0.26
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(base.x, base.y),
		Vector2(base.x + half_width, base.y - height * 0.46),
		Vector2(base.x + half_width * 0.45, base.y - height * 0.46),
		Vector2(base.x + half_width * 1.25, base.y - height * 0.72),
		Vector2(base.x + half_width * 0.45, base.y - height * 0.70),
		Vector2(base.x + half_width * 0.95, base.y - height),
		Vector2(base.x, base.y - height * 0.77),
		Vector2(base.x - half_width * 0.95, base.y - height),
		Vector2(base.x - half_width * 0.45, base.y - height * 0.70),
		Vector2(base.x - half_width * 1.25, base.y - height * 0.72),
		Vector2(base.x - half_width * 0.45, base.y - height * 0.46),
		Vector2(base.x - half_width, base.y - height * 0.46)
	])
	draw_colored_polygon(points, Color(0.012, 0.065, 0.10, 0.92))


func _draw_top_hud() -> void:
	_draw_stat_box(Rect2(1015.0, 22.0, 170.0, 58.0), "Очки", str(score), Color("ffd253"))
	_draw_stat_box(Rect2(1198.0, 22.0, 145.0, 58.0), "Комбо", "x%d" % maxi(combo, 1), Color("ffc33b"))
	_draw_stat_box(Rect2(1356.0, 22.0, 145.0, 58.0), "Время", _format_time(), Color.WHITE)
	_draw_button_box(PAUSE_RECT, "Ⅱ")
	_draw_button_box(SETTINGS_RECT, "⚙")


func _draw_left_panel() -> void:
	var panel: Rect2 = Rect2(115.0, 96.0, 345.0, 716.0)
	_draw_panel(panel, Color(0.018, 0.075, 0.16, 0.95), Color(0.06, 0.36, 0.70, 0.72))

	_draw_text("Глава 1", Vector2(155.0, 142.0), 20, Color(0.72, 0.82, 0.96))
	_draw_text("Лес", Vector2(155.0, 182.0), 34, Color("74e58e"))
	_draw_text("%d / %d слов" % [completed_words.size(), WORDS.size()], Vector2(155.0, 216.0), 20, Color("7af09a"))

	draw_rect(Rect2(155.0, 234.0, 265.0, 14.0), Color(0.015, 0.045, 0.10, 0.95), true)
	var ratio: float = float(completed_words.size()) / float(WORDS.size())
	draw_rect(Rect2(155.0, 234.0, 265.0 * ratio, 14.0), Color("55d979"), true)

	draw_line(Vector2(135.0, 270.0), Vector2(440.0, 270.0), Color(0.14, 0.36, 0.60, 0.48), 1.0)
	_draw_text("Текущее слово", Vector2(145.0, 306.0), 21, Color.WHITE)
	_draw_current_word(Vector2(145.0, 324.0))
	_draw_text(CLUES[word_index], Vector2(145.0, 414.0), 18, Color(0.75, 0.84, 0.96))

	draw_line(Vector2(135.0, 448.0), Vector2(440.0, 448.0), Color(0.14, 0.36, 0.60, 0.48), 1.0)
	_draw_text("Собрано", Vector2(145.0, 481.0), 18, Color(0.60, 0.72, 0.88))

	var list_y: float = 505.0
	if completed_words.is_empty():
		_draw_text("Пока нет завершённых слов", Vector2(145.0, list_y + 28.0), 16, Color(0.43, 0.56, 0.72))
	else:
		var start_index: int = maxi(0, completed_words.size() - 2)
		for i in range(start_index, completed_words.size()):
			_draw_text("✓  " + completed_words[i], Vector2(152.0, list_y + 28.0), 20, Color("70e68f"))
			list_y += 42.0

	var remaining: int = WORDS.size() - completed_words.size() - 1
	if remaining > 0:
		_draw_text("▣  Ещё %d слов" % remaining, Vector2(152.0, list_y + 32.0), 18, Color(0.53, 0.65, 0.82))

	var tutorial_rect: Rect2 = Rect2(135.0, 686.0, 305.0, 96.0)
	_draw_panel(tutorial_rect, Color(0.025, 0.105, 0.20, 0.97), Color(0.16, 0.40, 0.63, 0.62))
	if tutorial_complete:
		_draw_text("Золотая буква — цель", Vector2(155.0, 721.0), 18, Color("ffd65b"))
		_draw_text("Помести её в полную линию.", Vector2(155.0, 751.0), 16, Color.WHITE)
	else:
		_draw_text("Проведи нужную букву", Vector2(155.0, 718.0), 17, Color("ffd65b"))
		_draw_text("в заполненную линию,", Vector2(155.0, 746.0), 16, Color.WHITE)
		_draw_text("чтобы собрать слово.", Vector2(155.0, 771.0), 16, Color.WHITE)


func _draw_current_word(origin: Vector2) -> void:
	var word: String = _current_word()
	var slot_size: float = 54.0
	var gap: float = 7.0

	for i in range(word.length()):
		var rect: Rect2 = Rect2(origin.x + float(i) * (slot_size + gap), origin.y, slot_size, slot_size)
		var collected: bool = word_progress[i]
		var hinted: bool = hint_revealed_slots.has(i)
		var fill: Color = Color(0.016, 0.06, 0.135, 1.0)
		var border: Color = Color(0.15, 0.40, 0.72, 0.86)
		var value: String = "_"

		if collected:
			fill = Color(0.035, 0.25, 0.50, 1.0)
			border = Color("4fb8ff")
			value = word.substr(i, 1)
		elif hinted:
			border = Color("f5b93f")
			value = word.substr(i, 1)

		_draw_panel(rect, fill, border)
		_draw_text_centered(value, rect, 31, Color.WHITE)


func _draw_board() -> void:
	var origin: Vector2 = Vector2(510.0, 94.0)
	var board_rect: Rect2 = Rect2(origin.x - 8.0, origin.y - 8.0, float(COLS) * CELL + 16.0, float(ROWS) * CELL + 16.0)
	_draw_panel(board_rect, Color(0.008, 0.035, 0.09, 0.98), Color(0.05, 0.39, 0.78, 0.84))

	for x in range(COLS + 1):
		var px: float = origin.x + float(x) * CELL
		draw_line(Vector2(px, origin.y), Vector2(px, origin.y + float(ROWS) * CELL), Color(0.04, 0.22, 0.42, 0.62), 1.0)
	for y in range(ROWS + 1):
		var py: float = origin.y + float(y) * CELL
		draw_line(Vector2(origin.x, py), Vector2(origin.x + float(COLS) * CELL, py), Color(0.04, 0.22, 0.42, 0.62), 1.0)

	for y in range(ROWS):
		for x in range(COLS):
			var letter: String = _get_board_letter(x, y)
			if not letter.is_empty():
				_draw_tile(Vector2i(x, y), letter, origin, 1.0)

	if current_piece == null:
		return

	var ghost: Vector2i = _ghost_position()
	for cell in current_piece.cells:
		var ghost_pos: Vector2i = ghost + cell
		var ghost_rect: Rect2 = Rect2(
			origin + Vector2(float(ghost_pos.x), float(ghost_pos.y)) * CELL + Vector2(5.0, 5.0),
			Vector2(CELL - 10.0, CELL - 10.0)
		)
		draw_rect(ghost_rect, Color(0.28, 0.76, 1.0, 0.09), true)
		draw_rect(ghost_rect, Color(0.42, 0.84, 1.0, 0.72), false, 2.0)

	for i in range(current_piece.cells.size()):
		var grid_pos: Vector2i = current_piece.pos + current_piece.cells[i]
		_draw_tile(grid_pos, current_piece.letters[i], origin, 1.0)


func _draw_tile(grid_pos: Vector2i, letter: String, origin: Vector2, alpha: float) -> void:
	var rect: Rect2 = Rect2(
		origin + Vector2(float(grid_pos.x), float(grid_pos.y)) * CELL + Vector2(2.0, 2.0),
		Vector2(CELL - 4.0, CELL - 4.0)
	)
	var fill: Color = _tile_color(letter)
	fill.a = alpha
	var border: Color = fill.lightened(0.25)
	border.a = alpha

	if _is_needed_letter(letter):
		fill = Color(0.96, 0.57, 0.06, alpha)
		border = Color(1.0, 0.88, 0.35, alpha)
		draw_rect(rect.grow(4.0), Color(1.0, 0.68, 0.12, 0.12 * alpha), true)

	_draw_panel(rect, fill, border)
	_draw_text_centered(letter, rect, 25, Color(1.0, 1.0, 1.0, alpha))


func _tile_color(letter: String) -> Color:
	var color_index: int = absi(letter.hash()) % TILE_PALETTE.size()
	return TILE_PALETTE[color_index]


func _draw_right_panel() -> void:
	var panel: Rect2 = Rect2(990.0, 96.0, 315.0, 500.0)
	_draw_panel(panel, Color(0.018, 0.075, 0.16, 0.95), Color(0.06, 0.36, 0.70, 0.72))

	_draw_text("Следующая фигура", Vector2(1020.0, 145.0), 22, Color.WHITE)
	var preview_rect: Rect2 = Rect2(1015.0, 166.0, 265.0, 210.0)
	_draw_panel(preview_rect, Color(0.008, 0.035, 0.09, 0.96), Color(0.10, 0.33, 0.60, 0.72))
	_draw_next_piece(preview_rect)

	draw_line(Vector2(1015.0, 402.0), Vector2(1280.0, 402.0), Color(0.14, 0.36, 0.60, 0.48), 1.0)
	_draw_panel(HINT_RECT, Color(0.028, 0.105, 0.20, 0.98), Color(0.18, 0.42, 0.66, 0.68))
	_draw_text("Подсказка  [H]", Vector2(1030.0, 469.0), 20, Color("ffe06a"))
	_draw_text("Осталось: %d" % hint_charges, Vector2(1030.0, 499.0), 17, Color.WHITE)
	_draw_text("Показывает одну букву,", Vector2(1030.0, 527.0), 15, Color(0.69, 0.80, 0.93))
	_draw_text("но её всё равно нужно добыть.", Vector2(1030.0, 549.0), 15, Color(0.69, 0.80, 0.93))


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
		var tile_rect: Rect2 = Rect2(
			start + local_pos * preview_cell + Vector2(2.0, 2.0),
			Vector2(preview_cell - 4.0, preview_cell - 4.0)
		)
		var letter: String = next_piece.letters[i]
		var fill: Color = _tile_color(letter)
		var border: Color = fill.lightened(0.25)
		if _is_needed_letter(letter):
			fill = Color(0.96, 0.57, 0.06, 1.0)
			border = Color(1.0, 0.88, 0.35, 1.0)
		_draw_panel(tile_rect, fill, border)
		_draw_text_centered(letter, tile_rect, 25, Color.WHITE)


func _draw_controls() -> void:
	_draw_text(
		"← → / A D — движение     ↑ / W — поворот     ↓ / S — ускорить     Space — сбросить     P — пауза",
		Vector2(510.0, 848.0),
		15,
		Color(0.55, 0.68, 0.83)
	)


func _draw_word_celebration() -> void:
	var alpha: float = clampf(word_flash_timer, 0.0, 1.0)
	var rect: Rect2 = Rect2(585.0, 128.0, 290.0, 70.0)
	_draw_panel(rect, Color(0.03, 0.20, 0.16, 0.92 * alpha), Color(0.35, 0.93, 0.57, 0.85 * alpha))
	_draw_text_centered("✓  %s   +500" % last_completed_word, rect, 23, Color(1.0, 1.0, 1.0, alpha))


func _draw_overlay(title: String, subtitle: String) -> void:
	draw_rect(Rect2(0.0, 0.0, BASE_SIZE.x, BASE_SIZE.y), Color(0.0, 0.01, 0.04, 0.70), true)
	var rect: Rect2 = Rect2(505.0, 330.0, 590.0, 220.0)
	_draw_panel(rect, Color(0.02, 0.07, 0.15, 0.99), Color(0.10, 0.50, 0.88, 0.86))
	_draw_text_centered(title, Rect2(rect.position.x, rect.position.y + 38.0, rect.size.x, 66.0), 36, Color.WHITE)
	_draw_text_centered(subtitle, Rect2(rect.position.x, rect.position.y + 122.0, rect.size.x, 44.0), 19, Color(0.72, 0.82, 0.96))


func _draw_stat_box(rect: Rect2, label: String, value: String, accent: Color) -> void:
	_draw_panel(rect, Color(0.02, 0.07, 0.15, 0.95), Color(0.06, 0.33, 0.62, 0.74))
	_draw_text(label, Vector2(rect.position.x + 15.0, rect.position.y + 22.0), 14, Color(0.62, 0.74, 0.90))
	_draw_text(value, Vector2(rect.position.x + 15.0, rect.position.y + 49.0), 24, accent)


func _draw_button_box(rect: Rect2, text: String) -> void:
	_draw_panel(rect, Color(0.02, 0.07, 0.15, 0.95), Color(0.06, 0.33, 0.62, 0.74))
	_draw_text_centered(text, rect, 26, Color.WHITE)


func _draw_panel(rect: Rect2, fill: Color, border: Color) -> void:
	# Deliberately almost-square panels: final UI should not look like a mobile app.
	draw_rect(rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.12), true)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0)


func _draw_text(text: String, baseline: Vector2, size: int, color: Color) -> void:
	draw_string(get_theme_default_font(), baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _draw_text_centered(text: String, rect: Rect2, size: int, color: Color) -> void:
	var baseline_y: float = rect.position.y + rect.size.y * 0.5 + float(size) * 0.36
	draw_string(
		get_theme_default_font(),
		Vector2(rect.position.x, baseline_y),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		size,
		color
	)


func _format_time() -> String:
	var total: int = int(elapsed)
	var minutes: int = floori(float(total) / 60.0)
	var seconds: int = total % 60
	return "%02d:%02d" % [minutes, seconds]
