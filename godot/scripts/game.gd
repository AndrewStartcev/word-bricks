extends Control

# Словопад — integrated gameplay prototype.
# Production assets are drawn by code; letters/UI values remain dynamic.

const AUDIO_SERVICE_SCRIPT: Script = preload("res://scripts/audio_service.gd")

const BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_forest.png")
const TILE_NORMAL: Texture2D = preload("res://assets/tiles/tile_normal_blue.png")
const TILE_GOAL: Texture2D = preload("res://assets/tiles/tile_goal_gold.png")

const OWL_IDLE: Texture2D = preload("res://assets/characters/owl/owl_idle.png")
const OWL_HINT: Texture2D = preload("res://assets/characters/owl/owl_hint.png")
const OWL_HAPPY: Texture2D = preload("res://assets/characters/owl/owl_happy.png")
const OWL_WORRIED: Texture2D = preload("res://assets/characters/owl/owl_worried.png")
const OWL_DEFEAT: Texture2D = preload("res://assets/characters/owl/owl_defeat.png")

const ICON_SETTINGS: Texture2D = preload("res://assets/ui/icons/icon_settings.svg")
const ICON_PAUSE: Texture2D = preload("res://assets/ui/icons/icon_pause.svg")
const ICON_SCORE: Texture2D = preload("res://assets/ui/icons/icon_score.svg")
const ICON_COMBO: Texture2D = preload("res://assets/ui/icons/icon_combo.svg")
const ICON_TIME: Texture2D = preload("res://assets/ui/icons/icon_time.svg")
const ICON_HINT: Texture2D = preload("res://assets/ui/icons/icon_hint.svg")
const ICON_CHECK: Texture2D = preload("res://assets/ui/icons/icon_check.svg")
const ICON_LOCK: Texture2D = preload("res://assets/ui/icons/icon_lock.svg")
const ICON_CHAPTER: Texture2D = preload("res://assets/ui/icons/icon_chapter_forest.svg")
const ICON_CLUE: Texture2D = preload("res://assets/ui/icons/icon_clue_paw.svg")
const ICON_MUSIC_ON: Texture2D = preload("res://assets/ui/icons/icon_music_on.svg")
const ICON_MUSIC_OFF: Texture2D = preload("res://assets/ui/icons/icon_music_off.svg")
const ICON_SOUND_ON: Texture2D = preload("res://assets/ui/icons/icon_sound_on.svg")
const ICON_SOUND_OFF: Texture2D = preload("res://assets/ui/icons/icon_sound_off.svg")

const PARTICLE_SPARK: Texture2D = preload("res://assets/fx/particle_spark.png")
const PARTICLE_SHARD: Texture2D = preload("res://assets/fx/particle_shard.png")
const PARTICLE_LEAF: Texture2D = preload("res://assets/fx/particle_leaf.png")

const BASE_SIZE: Vector2 = Vector2(1600.0, 900.0)
const COLS: int = 10
const ROWS: int = 16
const CELL: float = 44.0
const BOARD_ORIGIN: Vector2 = Vector2(505.0, 94.0)
const WORD_ORIGIN: Vector2 = Vector2(145.0, 324.0)

const ALPHABET: String = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
const WORDS: Array[String] = ["ВОЛК", "СОСНА", "ГРИБ", "ЕЛЬ", "ЛИСА"]
const CLUES: Array[String] = [
	"Лесной хищник",
	"Хвойное дерево",
	"Растёт под деревьями",
	"Хвойное дерево",
	"Рыжая лесная охотница"
]

# Первый уровень должен занимать примерно 1–2 минуты: 2–3 добываемые буквы на слово.
const WORD_GAPS: Array = [
	[1, 2],
	[1, 2, 4],
	[0, 3],
	[0, 1],
	[1, 2]
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

const SETTINGS_RECT: Rect2 = Rect2(30.0, 20.0, 58.0, 60.0)
const PAUSE_RECT: Rect2 = Rect2(1510.0, 20.0, 58.0, 60.0)
const HINT_RECT: Rect2 = Rect2(1000.0, 420.0, 290.0, 112.0)
const BOARD_CLICK_RECT: Rect2 = Rect2(BOARD_ORIGIN, Vector2(COLS * CELL, ROWS * CELL))

const SETTINGS_PANEL: Rect2 = Rect2(535.0, 250.0, 530.0, 400.0)
const SETTINGS_CLOSE_RECT: Rect2 = Rect2(995.0, 270.0, 48.0, 48.0)
const MUSIC_TOGGLE_RECT: Rect2 = Rect2(820.0, 350.0, 150.0, 48.0)
const MUSIC_MINUS_RECT: Rect2 = Rect2(690.0, 414.0, 46.0, 42.0)
const MUSIC_PLUS_RECT: Rect2 = Rect2(924.0, 414.0, 46.0, 42.0)
const SFX_TOGGLE_RECT: Rect2 = Rect2(820.0, 505.0, 150.0, 48.0)
const SFX_MINUS_RECT: Rect2 = Rect2(690.0, 569.0, 46.0, 42.0)
const SFX_PLUS_RECT: Rect2 = Rect2(924.0, 569.0, 46.0, 42.0)


class Piece:
	var cells: Array[Vector2i] = []
	var letters: Array[String] = []
	var pos: Vector2i = Vector2i(3, 0)


class FxParticle:
	var texture: Texture2D
	var pos: Vector2
	var velocity: Vector2
	var life: float
	var age: float = 0.0
	var size: float
	var color: Color
	var rotation: float = 0.0
	var angular_velocity: float = 0.0


class FlyingLetter:
	var letter: String = ""
	var start: Vector2
	var target: Vector2
	var age: float = 0.0
	var life: float = 0.44


var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var board: Array[String] = []
var current_piece: Piece = null
var next_piece: Piece = null
var visual_piece_pos: Vector2 = Vector2.ZERO

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

var manual_paused: bool = false
var focus_paused: bool = false
var settings_open: bool = false
var game_over: bool = false
var chapter_complete: bool = false
var tutorial_complete: bool = false

var last_completed_word: String = ""
var word_flash_timer: float = 0.0
var line_flash_timer: float = 0.0
var line_flash_rows: Array[int] = []
var board_shake_timer: float = 0.0
var owl_hint_timer: float = 0.0
var owl_happy_timer: float = 0.0

var fx_particles: Array[FxParticle] = []
var flying_letters: Array[FlyingLetter] = []

var game_font: SystemFont = SystemFont.new()
var audio_service: Variant = null


func _ready() -> void:
	rng.randomize()
	game_font.font_names = PackedStringArray(["Trebuchet MS", "Verdana", "Arial"])
	audio_service = AUDIO_SERVICE_SCRIPT.new()
	audio_service.name = "AudioService"
	add_child(audio_service)
	_reset_game()
	queue_redraw()


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not game_over and not chapter_complete:
			focus_paused = true
			manual_paused = true
			_sync_audio_pause()
			queue_redraw()
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_paused = false
		_sync_audio_pause()


func _process(delta: float) -> void:
	if _is_paused():
		queue_redraw()
		return
	_update_visual_piece(delta)
	_update_fx(delta)
	_update_timers(delta)
	if game_over or chapter_complete:
		queue_redraw()
		return
	elapsed += delta
	drop_accumulator += delta
	if drop_accumulator >= _drop_interval():
		drop_accumulator = 0.0
		if not _try_move(Vector2i(0, 1), false):
			_lock_piece()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if audio_service != null and (event is InputEventKey or event is InputEventMouseButton):
		audio_service.unlock_audio()
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		_handle_key(key_event.keycode)
		return
	if event is InputEventMouseMotion:
		if not _is_paused() and not game_over and not chapter_complete:
			var motion: InputEventMouseMotion = event as InputEventMouseMotion
			_handle_mouse_motion(_screen_to_base(motion.position))
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		var base_pos: Vector2 = _screen_to_base(mouse_event.position)
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(base_pos)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(base_pos)


func _handle_key(keycode: int) -> void:
	if settings_open:
		if keycode == KEY_ESCAPE:
			_close_settings()
		return
	if game_over or chapter_complete:
		if keycode == KEY_R:
			_reset_game()
		return
	if keycode == KEY_P or keycode == KEY_ESCAPE:
		manual_paused = not manual_paused
		_sync_audio_pause()
		queue_redraw()
		return
	if _is_paused():
		return
	match keycode:
		KEY_LEFT, KEY_A:
			_try_move(Vector2i(-1, 0), true)
		KEY_RIGHT, KEY_D:
			_try_move(Vector2i(1, 0), true)
		KEY_DOWN, KEY_S:
			if _try_move(Vector2i(0, 1), false):
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
	if HINT_RECT.has_point(base_pos) and not game_over and not chapter_complete:
		_use_hint()
		queue_redraw()
		return
	if BOARD_CLICK_RECT.has_point(base_pos) and not game_over and not chapter_complete:
		_hard_drop()
		queue_redraw()


func _handle_right_click(base_pos: Vector2) -> void:
	if _is_paused() or game_over or chapter_complete:
		return
	if BOARD_CLICK_RECT.has_point(base_pos):
		_try_rotate()
		queue_redraw()


func _handle_mouse_motion(base_pos: Vector2) -> void:
	if current_piece == null or not BOARD_CLICK_RECT.has_point(base_pos):
		return
	var column: int = floori((base_pos.x - BOARD_ORIGIN.x) / CELL)
	var min_x: int = 99
	var max_x: int = -99
	for cell in current_piece.cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
	var shape_center: int = floori(float(min_x + max_x) * 0.5)
	var desired_x: int = column - shape_center
	_move_piece_to_x(desired_x)


func _move_piece_to_x(desired_x: int) -> void:
	if current_piece == null:
		return
	var old_x: int = current_piece.pos.x
	for offset in [0, -1, 1, -2, 2]:
		var test_x: int = desired_x + int(offset)
		var test_pos: Vector2i = Vector2i(test_x, current_piece.pos.y)
		if _can_place(current_piece.cells, test_pos):
			current_piece.pos = Vector2i(test_x, current_piece.pos.y)
			if old_x != test_x:
				_play_sfx("piece_move")
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
	manual_paused = false
	focus_paused = false
	settings_open = false
	game_over = false
	chapter_complete = false
	tutorial_complete = false
	last_completed_word = ""
	word_flash_timer = 0.0
	line_flash_timer = 0.0
	line_flash_rows.clear()
	board_shake_timer = 0.0
	owl_hint_timer = 0.0
	owl_happy_timer = 0.0
	fx_particles.clear()
	flying_letters.clear()
	_reset_word_state()
	current_piece = _make_piece()
	next_piece = _make_piece()
	visual_piece_pos = Vector2(current_piece.pos)
	if audio_service != null:
		audio_service.reset_round_audio()
		audio_service.set_suspended("pause", false)
		audio_service.set_suspended("settings", false)
		audio_service.set_suspended("defeat", false)
		audio_service.start_music()
	if not _can_place(current_piece.cells, current_piece.pos):
		_set_game_over()
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
		var force_goal: bool = pieces_without_goal >= 1
		if force_goal or rng.randf() < 0.55:
			goal_slot = rng.randi_range(0, piece.cells.size() - 1)
			pieces_without_goal = 0
		else:
			pieces_without_goal += 1
	for i in range(piece.cells.size()):
		if i == goal_slot and not missing.is_empty():
			piece.letters.append(missing[rng.randi_range(0, missing.size() - 1)])
		else:
			var alphabet_index: int = rng.randi_range(0, ALPHABET.length() - 1)
			piece.letters.append(ALPHABET.substr(alphabet_index, 1))
	piece.pos = Vector2i(3, 0)
	return piece


func _drop_interval() -> float:
	var progression: float = float(completed_words.size()) * 0.055
	return maxf(0.30, 0.84 - progression)


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


func _try_move(delta: Vector2i, user_horizontal: bool) -> bool:
	if current_piece == null:
		return false
	var new_pos: Vector2i = current_piece.pos + delta
	if _can_place(current_piece.cells, new_pos):
		current_piece.pos = new_pos
		if user_horizontal and delta.x != 0:
			_play_sfx("piece_move")
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
	var kicks: Array[Vector2i] = [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(2, 0)]
	for kick in kicks:
		var test_pos: Vector2i = current_piece.pos + kick
		if _can_place(rotated, test_pos):
			current_piece.cells = rotated
			current_piece.pos = test_pos
			_play_sfx("piece_rotate")
			return
	_play_sfx("invalid")


func _hard_drop() -> void:
	if current_piece == null:
		return
	var start_pos: Vector2i = current_piece.pos
	var ghost: Vector2i = _ghost_position()
	var distance: int = ghost.y - start_pos.y
	if distance > 0:
		_spawn_drop_trail(current_piece, start_pos, ghost)
	current_piece.pos = ghost
	visual_piece_pos = Vector2(ghost)
	score += distance * 2
	board_shake_timer = 0.14
	_lock_piece()


func _lock_piece() -> void:
	if current_piece == null:
		return
	var locked_cells: Array[Vector2i] = []
	for i in range(current_piece.cells.size()):
		var cell: Vector2i = current_piece.cells[i]
		var gx: int = current_piece.pos.x + cell.x
		var gy: int = current_piece.pos.y + cell.y
		if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS:
			_set_game_over()
			return
		_set_board_letter(gx, gy, current_piece.letters[i])
		locked_cells.append(Vector2i(gx, gy))
	_play_sfx("piece_lock")
	_spawn_lock_fx(locked_cells)
	_clear_full_lines()
	if chapter_complete:
		return
	current_piece = next_piece
	next_piece = _make_piece()
	visual_piece_pos = Vector2(current_piece.pos)
	drop_accumulator = 0.0
	if current_piece == null or not _can_place(current_piece.cells, current_piece.pos):
		_set_game_over()


func _set_game_over() -> void:
	if game_over:
		return
	game_over = true
	_play_sfx("defeat")
	if audio_service != null:
		audio_service.set_suspended("defeat", true)


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
	line_flash_rows = full_rows.duplicate()
	line_flash_timer = 0.28
	_play_sfx("line_clear")
	for row_y in full_rows:
		_spawn_line_fx(row_y)
	var useful_letters: int = 0
	for y in full_rows:
		for x in range(COLS):
			var letter: String = _get_board_letter(x, y)
			var slot_index: int = _collect_letter(letter)
			if slot_index >= 0:
				useful_letters += 1
				var source: Vector2 = BOARD_ORIGIN + Vector2((float(x) + 0.5) * CELL, (float(y) + 0.5) * CELL)
				_spawn_flying_letter(letter, source, slot_index)
	_collapse_rows(full_rows)
	total_lines += full_rows.size()
	score += full_rows.size() * 100 + useful_letters * 90
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


func _collect_letter(letter: String) -> int:
	var word: String = _current_word()
	for i in range(word.length()):
		if not word_progress[i] and word.substr(i, 1) == letter:
			word_progress[i] = true
			return i
	return -1


func _is_word_complete() -> bool:
	for collected in word_progress:
		if not collected:
			return false
	return true


func _complete_word() -> void:
	last_completed_word = _current_word()
	completed_words.append(last_completed_word)
	score += 600 + combo * 120
	word_flash_timer = 1.0
	owl_happy_timer = 0.9
	_spawn_word_complete_fx()
	if completed_words.size() >= WORDS.size():
		chapter_complete = true
		_play_sfx("chapter_complete")
		_spawn_chapter_fx()
		return
	_play_sfx("word_complete")
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
		_play_sfx("invalid")
		return
	var candidates: Array[int] = []
	for i in range(_current_word().length()):
		if not word_progress[i] and not hint_revealed_slots.has(i):
			candidates.append(i)
	if candidates.is_empty():
		_play_sfx("invalid")
		return
	var chosen_slot: int = candidates[rng.randi_range(0, candidates.size() - 1)]
	hint_revealed_slots[chosen_slot] = true
	hint_charges -= 1
	owl_hint_timer = 1.2
	_play_sfx("hint")


func _ghost_position() -> Vector2i:
	if current_piece == null:
		return Vector2i.ZERO
	var ghost: Vector2i = current_piece.pos
	while _can_place(current_piece.cells, ghost + Vector2i(0, 1)):
		ghost += Vector2i(0, 1)
	return ghost


func _update_visual_piece(delta: float) -> void:
	if current_piece == null:
		return
	var target: Vector2 = Vector2(current_piece.pos)
	var weight: float = 1.0 - exp(-delta * 22.0)
	visual_piece_pos = visual_piece_pos.lerp(target, weight)


func _update_timers(delta: float) -> void:
	word_flash_timer = maxf(0.0, word_flash_timer - delta)
	line_flash_timer = maxf(0.0, line_flash_timer - delta)
	board_shake_timer = maxf(0.0, board_shake_timer - delta)
	owl_hint_timer = maxf(0.0, owl_hint_timer - delta)
	owl_happy_timer = maxf(0.0, owl_happy_timer - delta)
	if line_flash_timer <= 0.0:
		line_flash_rows.clear()


func _update_fx(delta: float) -> void:
	for i in range(fx_particles.size() - 1, -1, -1):
		var particle: FxParticle = fx_particles[i]
		particle.age += delta
		if particle.age >= particle.life:
			fx_particles.remove_at(i)
			continue
		particle.pos += particle.velocity * delta
		particle.rotation += particle.angular_velocity * delta
	for i in range(flying_letters.size() - 1, -1, -1):
		var flying: FlyingLetter = flying_letters[i]
		flying.age += delta
		if flying.age >= flying.life:
			flying_letters.remove_at(i)


func _spawn_lock_fx(cells: Array[Vector2i]) -> void:
	for grid_pos in cells:
		var center: Vector2 = BOARD_ORIGIN + Vector2((float(grid_pos.x) + 0.5) * CELL, (float(grid_pos.y) + 0.5) * CELL)
		for _i in range(2):
			_spawn_particle(PARTICLE_SHARD, center, Vector2(rng.randf_range(-35.0, 35.0), rng.randf_range(-52.0, -18.0)), 0.28, rng.randf_range(5.0, 8.0), Color(0.45, 0.83, 1.0, 1.0))


func _spawn_line_fx(row_y: int) -> void:
	for x in range(COLS):
		var center: Vector2 = BOARD_ORIGIN + Vector2((float(x) + 0.5) * CELL, (float(row_y) + 0.5) * CELL)
		_spawn_particle(PARTICLE_SPARK, center, Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-90.0, -35.0)), 0.44, rng.randf_range(7.0, 11.0), Color(1.0, 0.83, 0.30, 1.0))


func _spawn_drop_trail(piece: Piece, from_pos: Vector2i, to_pos: Vector2i) -> void:
	var distance: int = to_pos.y - from_pos.y
	var steps: int = mini(6, maxi(2, distance / 2))
	for step in range(steps):
		var t: float = float(step + 1) / float(steps + 1)
		for cell in piece.cells:
			var gx: float = float(from_pos.x + cell.x) + 0.5
			var gy: float = lerpf(float(from_pos.y + cell.y), float(to_pos.y + cell.y), t) + 0.5
			var pos: Vector2 = BOARD_ORIGIN + Vector2(gx * CELL, gy * CELL)
			_spawn_particle(PARTICLE_SPARK, pos, Vector2(0.0, -20.0), 0.20, 5.0, Color(0.45, 0.82, 1.0, 0.65))


func _spawn_flying_letter(letter: String, start: Vector2, slot_index: int) -> void:
	var flying: FlyingLetter = FlyingLetter.new()
	flying.letter = letter
	flying.start = start
	flying.target = _word_slot_center(slot_index)
	flying_letters.append(flying)


func _spawn_word_complete_fx() -> void:
	var center: Vector2 = Vector2(290.0, 355.0)
	for _i in range(16):
		var angle: float = rng.randf_range(-PI, PI)
		var speed: float = rng.randf_range(55.0, 120.0)
		_spawn_particle(PARTICLE_SPARK, center, Vector2(cos(angle), sin(angle)) * speed, 0.62, rng.randf_range(6.0, 11.0), Color(1.0, 0.83, 0.28, 1.0))


func _spawn_chapter_fx() -> void:
	for _i in range(22):
		var start: Vector2 = Vector2(rng.randf_range(80.0, 1520.0), rng.randf_range(-40.0, 120.0))
		_spawn_particle(PARTICLE_LEAF, start, Vector2(rng.randf_range(-20.0, 30.0), rng.randf_range(75.0, 135.0)), rng.randf_range(1.0, 1.4), rng.randf_range(9.0, 14.0), Color(0.45, 0.90, 0.45, 1.0), rng.randf_range(-1.5, 1.5))


func _spawn_particle(texture: Texture2D, pos: Vector2, velocity: Vector2, life: float, size: float, color: Color, angular_velocity: float = 0.0) -> void:
	if fx_particles.size() >= 80:
		return
	var particle: FxParticle = FxParticle.new()
	particle.texture = texture
	particle.pos = pos
	particle.velocity = velocity
	particle.life = life
	particle.size = size
	particle.color = color
	particle.angular_velocity = angular_velocity
	fx_particles.append(particle)


func _word_slot_center(slot_index: int) -> Vector2:
	var slot_size: float = 54.0
	var gap: float = 7.0
	return WORD_ORIGIN + Vector2(float(slot_index) * (slot_size + gap) + slot_size * 0.5, slot_size * 0.5)


func _is_danger_state() -> bool:
	for y in range(4):
		for x in range(COLS):
			if not _get_board_letter(x, y).is_empty():
				return true
	return false


func _is_paused() -> bool:
	return manual_paused or focus_paused or settings_open


func _sync_audio_pause() -> void:
	if audio_service == null:
		return
	audio_service.set_suspended("pause", manual_paused or focus_paused)
	audio_service.set_suspended("settings", settings_open)


func _play_sfx(event_id: String) -> void:
	if audio_service != null:
		audio_service.play_sfx(event_id)


func _open_settings() -> void:
	settings_open = true
	_play_sfx("ui_click")
	_sync_audio_pause()
	queue_redraw()


func _close_settings() -> void:
	settings_open = false
	_play_sfx("ui_back")
	_sync_audio_pause()
	queue_redraw()


func _handle_settings_click(base_pos: Vector2) -> void:
	if SETTINGS_CLOSE_RECT.has_point(base_pos):
		_close_settings()
		return
	if audio_service == null:
		return
	if MUSIC_TOGGLE_RECT.has_point(base_pos):
		audio_service.set_music_enabled(not audio_service.is_music_enabled())
		_play_sfx("ui_click")
	elif MUSIC_MINUS_RECT.has_point(base_pos):
		audio_service.set_music_volume(audio_service.get_music_volume() - 0.10)
		_play_sfx("ui_click")
	elif MUSIC_PLUS_RECT.has_point(base_pos):
		audio_service.set_music_volume(audio_service.get_music_volume() + 0.10)
		_play_sfx("ui_click")
	elif SFX_TOGGLE_RECT.has_point(base_pos):
		var new_value: bool = not audio_service.is_sfx_enabled()
		audio_service.set_sfx_enabled(new_value)
		if new_value:
			_play_sfx("ui_click")
	elif SFX_MINUS_RECT.has_point(base_pos):
		audio_service.set_sfx_volume(audio_service.get_sfx_volume() - 0.10)
		_play_sfx("ui_click")
	elif SFX_PLUS_RECT.has_point(base_pos):
		audio_service.set_sfx_volume(audio_service.get_sfx_volume() + 0.10)
		_play_sfx("ui_click")
	queue_redraw()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	var draw_size: Vector2 = BASE_SIZE * scale_factor
	var offset: Vector2 = (viewport_size - draw_size) * 0.5
	draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))
	_draw_background()
	_draw_owl()
	_draw_top_hud()
	_draw_left_panel()
	_draw_board()
	_draw_right_panel()
	_draw_controls()
	_draw_fx()
	if word_flash_timer > 0.0 and not last_completed_word.is_empty() and not chapter_complete:
		_draw_word_celebration()
	if settings_open:
		_draw_settings_overlay()
	elif manual_paused or focus_paused:
		_draw_overlay("Пауза", "P / Esc — продолжить")
	elif game_over:
		_draw_overlay("Поражение", "R — начать заново")
	elif chapter_complete:
		_draw_overlay("Глава завершена!", "Собрано 5 / 5 слов   •   R — сыграть ещё раз")


func _draw_background() -> void:
	draw_texture_rect(BACKGROUND, Rect2(Vector2.ZERO, BASE_SIZE), false)
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color(0.01, 0.025, 0.07, 0.18), true)


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
	draw_texture_rect(texture, Rect2(5.0, 615.0, 155.0, 155.0), false)


func _draw_top_hud() -> void:
	_draw_icon_button(SETTINGS_RECT, ICON_SETTINGS)
	_draw_stat_box(Rect2(980.0, 20.0, 185.0, 60.0), ICON_SCORE, "Очки", str(score), Color("ffd253"))
	_draw_stat_box(Rect2(1175.0, 20.0, 150.0, 60.0), ICON_COMBO, "Комбо", "x%d" % maxi(combo, 1), Color("ffc33b"))
	_draw_stat_box(Rect2(1335.0, 20.0, 165.0, 60.0), ICON_TIME, "Время", _format_time(), Color.WHITE)
	_draw_icon_button(PAUSE_RECT, ICON_PAUSE)


func _draw_left_panel() -> void:
	var panel: Rect2 = Rect2(105.0, 94.0, 350.0, 720.0)
	_draw_panel(panel, Color(0.014, 0.055, 0.125, 0.93), Color(0.08, 0.36, 0.64, 0.78))
	draw_texture_rect(ICON_CHAPTER, Rect2(135.0, 118.0, 62.0, 62.0), false)
	_draw_text("Глава 1", Vector2(215.0, 137.0), 19, Color(0.70, 0.80, 0.94))
	_draw_text("Лес", Vector2(215.0, 177.0), 33, Color("73e891"))
	_draw_text("%d / %d слов" % [completed_words.size(), WORDS.size()], Vector2(135.0, 216.0), 20, Color("7af09a"))
	draw_rect(Rect2(135.0, 234.0, 285.0, 13.0), Color(0.01, 0.035, 0.08, 0.95), true)
	var ratio: float = float(completed_words.size()) / float(WORDS.size())
	draw_rect(Rect2(135.0, 234.0, 285.0 * ratio, 13.0), Color("55d979"), true)
	draw_line(Vector2(125.0, 270.0), Vector2(435.0, 270.0), Color(0.14, 0.34, 0.58, 0.50), 1.0)
	_draw_text("Текущее слово", Vector2(135.0, 306.0), 21, Color.WHITE)
	_draw_current_word(WORD_ORIGIN)
	draw_texture_rect(ICON_CLUE, Rect2(135.0, 399.0, 25.0, 25.0), false)
	_draw_text(CLUES[word_index], Vector2(170.0, 419.0), 18, Color(0.76, 0.85, 0.96))
	draw_line(Vector2(125.0, 450.0), Vector2(435.0, 450.0), Color(0.14, 0.34, 0.58, 0.50), 1.0)
	_draw_text("Собрано", Vector2(135.0, 483.0), 18, Color(0.60, 0.72, 0.88))
	var list_y: float = 505.0
	var start_index: int = maxi(0, completed_words.size() - 3)
	for i in range(start_index, completed_words.size()):
		draw_texture_rect(ICON_CHECK, Rect2(138.0, list_y + 7.0, 22.0, 22.0), false)
		_draw_text(completed_words[i], Vector2(170.0, list_y + 27.0), 19, Color("70e68f"))
		list_y += 40.0
	var remaining: int = WORDS.size() - completed_words.size() - 1
	if remaining > 0:
		draw_texture_rect(ICON_LOCK, Rect2(138.0, list_y + 6.0, 22.0, 22.0), false)
		_draw_text("Ещё %d слов" % remaining, Vector2(170.0, list_y + 27.0), 18, Color(0.53, 0.65, 0.82))
	var tutorial_rect: Rect2 = Rect2(128.0, 690.0, 302.0, 94.0)
	_draw_panel(tutorial_rect, Color(0.022, 0.09, 0.18, 0.96), Color(0.15, 0.36, 0.58, 0.70))
	if tutorial_complete:
		_draw_text("Золотая буква — цель", Vector2(150.0, 723.0), 18, Color("ffd65b"))
		_draw_text("Проведи её в полную линию.", Vector2(150.0, 752.0), 16, Color.WHITE)
	else:
		_draw_text("Проведи золотую букву", Vector2(150.0, 721.0), 17, Color("ffd65b"))
		_draw_text("в заполненную линию.", Vector2(150.0, 751.0), 16, Color.WHITE)


func _draw_current_word(origin: Vector2) -> void:
	var word: String = _current_word()
	var slot_size: float = 54.0
	var gap: float = 7.0
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
		_draw_text_centered(value, rect, 31, Color.WHITE)


func _draw_board() -> void:
	var shake: Vector2 = _board_shake_offset()
	var origin: Vector2 = BOARD_ORIGIN + shake
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
	var texture: Texture2D = TILE_GOAL if _is_needed_letter(letter) else TILE_NORMAL
	if texture == TILE_GOAL:
		var pulse: float = 0.18 + (sin(elapsed * 4.5) + 1.0) * 0.06
		draw_rect(rect.grow(4.0), Color(1.0, 0.72, 0.16, pulse * alpha), true)
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
	_draw_tile_letter(letter, rect, alpha)


func _draw_tile_letter(letter: String, rect: Rect2, alpha: float) -> void:
	var shadow_rect: Rect2 = Rect2(rect.position + Vector2(1.2, 1.6), rect.size)
	_draw_text_centered(letter, shadow_rect, 25, Color(0.02, 0.05, 0.10, 0.68 * alpha))
	_draw_text_centered(letter, rect, 25, Color(1.0, 1.0, 1.0, alpha))


func _draw_right_panel() -> void:
	var panel: Rect2 = Rect2(980.0, 94.0, 330.0, 510.0)
	_draw_panel(panel, Color(0.014, 0.055, 0.125, 0.93), Color(0.08, 0.36, 0.64, 0.78))
	_draw_text("Следующая фигура", Vector2(1010.0, 143.0), 22, Color.WHITE)
	var preview_rect: Rect2 = Rect2(1005.0, 164.0, 280.0, 215.0)
	_draw_panel(preview_rect, Color(0.006, 0.025, 0.065, 0.94), Color(0.10, 0.31, 0.55, 0.72))
	_draw_next_piece(preview_rect)
	draw_line(Vector2(1005.0, 402.0), Vector2(1285.0, 402.0), Color(0.14, 0.34, 0.58, 0.48), 1.0)
	_draw_panel(HINT_RECT, Color(0.022, 0.09, 0.18, 0.97), Color(0.17, 0.40, 0.63, 0.72))
	draw_texture_rect(ICON_HINT, Rect2(1020.0, 441.0, 36.0, 36.0), false)
	_draw_text("Подсказка  [H]", Vector2(1070.0, 466.0), 20, Color("ffe06a"))
	_draw_text("Осталось: %d" % hint_charges, Vector2(1020.0, 500.0), 17, Color.WHITE)
	_draw_text("Открывает одну нужную букву.", Vector2(1020.0, 524.0), 15, Color(0.69, 0.80, 0.93))


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
		var texture: Texture2D = TILE_GOAL if _is_needed_letter(letter) else TILE_NORMAL
		draw_texture_rect(texture, tile_rect, false)
		_draw_tile_letter(letter, tile_rect, 1.0)


func _draw_controls() -> void:
	_draw_text("Мышь — позиция   •   ЛКМ — поставить   •   ПКМ — повернуть   •   A/D или ←/→ — движение   •   Space — сбросить", Vector2(505.0, 850.0), 15, Color(0.62, 0.74, 0.88))


func _draw_fx() -> void:
	for particle in fx_particles:
		var life_ratio: float = clampf(1.0 - particle.age / particle.life, 0.0, 1.0)
		var size: float = particle.size * (0.7 + life_ratio * 0.3)
		var rect: Rect2 = Rect2(particle.pos - Vector2(size, size) * 0.5, Vector2(size, size))
		var color: Color = particle.color
		color.a *= life_ratio
		draw_texture_rect(particle.texture, rect, false, color)
	for flying in flying_letters:
		var t: float = clampf(flying.age / flying.life, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		var pos: Vector2 = flying.start.lerp(flying.target, eased)
		pos.y -= sin(t * PI) * 36.0
		var rect: Rect2 = Rect2(pos - Vector2(20.0, 20.0), Vector2(40.0, 40.0))
		draw_texture_rect(TILE_GOAL, rect, false, Color(1.0, 1.0, 1.0, 1.0 - t * 0.15))
		_draw_tile_letter(flying.letter, rect, 1.0)


func _draw_word_celebration() -> void:
	var alpha: float = clampf(word_flash_timer, 0.0, 1.0)
	var scale_bump: float = 1.0 + sin((1.0 - alpha) * PI) * 0.05
	var base_rect: Rect2 = Rect2(585.0, 128.0, 300.0, 72.0)
	var size: Vector2 = base_rect.size * scale_bump
	var rect: Rect2 = Rect2(base_rect.get_center() - size * 0.5, size)
	_draw_panel(rect, Color(0.025, 0.18, 0.14, 0.92 * alpha), Color(0.35, 0.93, 0.57, 0.85 * alpha))
	_draw_text_centered("✓  %s   +600" % last_completed_word, rect, 23, Color(1.0, 1.0, 1.0, alpha))


func _draw_settings_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color(0.0, 0.01, 0.035, 0.72), true)
	_draw_panel(SETTINGS_PANEL, Color(0.018, 0.065, 0.14, 0.99), Color(0.10, 0.45, 0.78, 0.88))
	_draw_text("Настройки", Vector2(575.0, 310.0), 32, Color.WHITE)
	_draw_button_box(SETTINGS_CLOSE_RECT, "×")
	if audio_service == null:
		return
	var music_on: bool = audio_service.is_music_enabled()
	var sfx_on: bool = audio_service.is_sfx_enabled()
	var music_icon: Texture2D = ICON_MUSIC_ON if music_on else ICON_MUSIC_OFF
	var sfx_icon: Texture2D = ICON_SOUND_ON if sfx_on else ICON_SOUND_OFF
	draw_texture_rect(music_icon, Rect2(590.0, 348.0, 48.0, 48.0), false)
	_draw_text("Музыка", Vector2(655.0, 382.0), 22, Color.WHITE)
	_draw_toggle(MUSIC_TOGGLE_RECT, music_on)
	_draw_button_box(MUSIC_MINUS_RECT, "−")
	_draw_text_centered("%d%%" % roundi(audio_service.get_music_volume() * 100.0), Rect2(745.0, 414.0, 170.0, 42.0), 20, Color.WHITE)
	_draw_button_box(MUSIC_PLUS_RECT, "+")
	draw_texture_rect(sfx_icon, Rect2(590.0, 503.0, 48.0, 48.0), false)
	_draw_text("Звуки", Vector2(655.0, 537.0), 22, Color.WHITE)
	_draw_toggle(SFX_TOGGLE_RECT, sfx_on)
	_draw_button_box(SFX_MINUS_RECT, "−")
	_draw_text_centered("%d%%" % roundi(audio_service.get_sfx_volume() * 100.0), Rect2(745.0, 569.0, 170.0, 42.0), 20, Color.WHITE)
	_draw_button_box(SFX_PLUS_RECT, "+")


func _draw_toggle(rect: Rect2, enabled: bool) -> void:
	var fill: Color = Color(0.06, 0.35, 0.19, 0.98) if enabled else Color(0.20, 0.08, 0.10, 0.98)
	var border: Color = Color(0.30, 0.88, 0.48, 0.85) if enabled else Color(0.78, 0.28, 0.30, 0.85)
	_draw_panel(rect, fill, border)
	_draw_text_centered("ВКЛ" if enabled else "ВЫКЛ", rect, 18, Color.WHITE)


func _draw_overlay(title: String, subtitle: String) -> void:
	draw_rect(Rect2(Vector2.ZERO, BASE_SIZE), Color(0.0, 0.01, 0.04, 0.70), true)
	var rect: Rect2 = Rect2(505.0, 330.0, 590.0, 220.0)
	_draw_panel(rect, Color(0.02, 0.07, 0.15, 0.99), Color(0.10, 0.50, 0.88, 0.86))
	_draw_text_centered(title, Rect2(rect.position.x, rect.position.y + 38.0, rect.size.x, 66.0), 36, Color.WHITE)
	_draw_text_centered(subtitle, Rect2(rect.position.x, rect.position.y + 122.0, rect.size.x, 44.0), 19, Color(0.72, 0.82, 0.96))


func _draw_stat_box(rect: Rect2, icon: Texture2D, label: String, value: String, accent: Color) -> void:
	_draw_panel(rect, Color(0.018, 0.065, 0.14, 0.95), Color(0.07, 0.34, 0.62, 0.78))
	draw_texture_rect(icon, Rect2(rect.position + Vector2(12.0, 10.0), Vector2(38.0, 38.0)), false)
	_draw_text(label, Vector2(rect.position.x + 60.0, rect.position.y + 22.0), 13, Color(0.64, 0.75, 0.90))
	_draw_text(value, Vector2(rect.position.x + 60.0, rect.position.y + 49.0), 23, accent)


func _draw_icon_button(rect: Rect2, icon: Texture2D) -> void:
	_draw_panel(rect, Color(0.018, 0.065, 0.14, 0.95), Color(0.07, 0.34, 0.62, 0.78))
	draw_texture_rect(icon, Rect2(rect.position + Vector2(10.0, 10.0), rect.size - Vector2(20.0, 20.0)), false)


func _draw_button_box(rect: Rect2, text: String) -> void:
	_draw_panel(rect, Color(0.025, 0.085, 0.17, 0.96), Color(0.10, 0.39, 0.67, 0.78))
	_draw_text_centered(text, rect, 25, Color.WHITE)


func _draw_panel(rect: Rect2, fill: Color, border: Color) -> void:
	draw_rect(rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.14), true)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0)


func _draw_text(text: String, baseline: Vector2, size: int, color: Color) -> void:
	draw_string(game_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _draw_text_centered(text: String, rect: Rect2, size: int, color: Color) -> void:
	var baseline_y: float = rect.position.y + rect.size.y * 0.5 + float(size) * 0.36
	draw_string(game_font, Vector2(rect.position.x, baseline_y), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)


func _board_shake_offset() -> Vector2:
	if board_shake_timer <= 0.0:
		return Vector2.ZERO
	var strength: float = 3.0 * clampf(board_shake_timer / 0.14, 0.0, 1.0)
	var ticks: float = float(Time.get_ticks_msec()) * 0.04
	return Vector2(sin(ticks) * strength, cos(ticks * 1.27) * strength * 0.6)


func _format_time() -> String:
	var total: int = int(elapsed)
	var minutes: int = floori(float(total) / 60.0)
	var seconds: int = total % 60
	return "%02d:%02d" % [minutes, seconds]
