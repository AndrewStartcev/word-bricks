extends "res://scripts/app_runtime_chapters.gd"

# Progression model:
# Main menu -> world map (locations) -> location map (10 levels) -> gameplay.
# Each level is a five-word round. Story transitions happen only after level 10.

const LEVEL_CATALOG = preload("res://scripts/level_catalog.gd")
const LEVEL_PROGRESS_VERSION: int = 1

# Stage 3: production world-map and level-map skins.
const WORLD_NODE_COMPLETE: Texture2D = preload("res://assets/ui/world_map/location_node_complete.png")
const WORLD_NODE_CURRENT: Texture2D = preload("res://assets/ui/world_map/location_node_current.png")
const WORLD_NODE_LOCKED: Texture2D = preload("res://assets/ui/world_map/location_node_locked.png")
const WORLD_NODE_OPEN: Texture2D = preload("res://assets/ui/world_map/location_node_open.png")
const WORLD_LABEL_PLATE: Texture2D = preload("res://assets/ui/world_map/location_label_plate.png")
const WORLD_PROGRESS_PLATE: Texture2D = preload("res://assets/ui/world_map/location_progress_plate.png")
const WORLD_PATH_DOT: Texture2D = preload("res://assets/ui/world_map/path_dot.png")
const WORLD_PATH_GLOW: Texture2D = preload("res://assets/ui/world_map/path_glow.png")
const WORLD_PATH_SEGMENT: Texture2D = preload("res://assets/ui/world_map/path_segment.png")

const LEVEL_NODE_COMPLETE: Texture2D = preload("res://assets/ui/level_map/level_node_complete.png")
const LEVEL_NODE_CURRENT: Texture2D = preload("res://assets/ui/level_map/level_node_current.png")
const LEVEL_NODE_LOCKED: Texture2D = preload("res://assets/ui/level_map/level_node_locked.png")
const LEVEL_NODE_OPEN: Texture2D = preload("res://assets/ui/level_map/level_node_open.png")
const LEVEL_PATH_DOT: Texture2D = preload("res://assets/ui/level_map/level_path_dot.png")
const LEVEL_PATH_SEGMENT: Texture2D = preload("res://assets/ui/level_map/level_path_segment.png")

var current_stage_number: int = 1
var forest_completed_levels: int = 0
var village_completed_levels: int = 0


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if current_screen == "locations":
				_show_main_menu()
				get_viewport().set_input_as_handled()
				return
			if current_screen == "location_levels":
				_show_level_select()
				get_viewport().set_input_as_handled()
				return
	super._input(event)


func _show_main_menu() -> void:
	super._show_main_menu()
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if forest_completed_levels < LEVEL_CATALOG.LEVELS_PER_LOCATION:
		_replace_label_text(screen_layer, "Лес · 5 слов", "Лес · %d / 10 уровней" % forest_completed_levels)
		var status: String = "Начать путешествие" if forest_completed_levels == 0 else "Продолжить · Уровень %d" % mini(10, forest_completed_levels + 1)
		_replace_label_text(screen_layer, "Первый уровень открыт", status)
	else:
		_replace_label_text(screen_layer, "Деревня · 5 слов", "Деревня · %d / 10 уровней" % village_completed_levels)
		if village_completed_levels >= 10:
			_replace_label_text(screen_layer, "Деревня пройдена", "Деревня восстановлена")
		else:
			var status: String = "Открыта новая локация" if village_completed_levels == 0 else "Продолжить · Уровень %d" % mini(10, village_completed_levels + 1)
			_replace_label_text(screen_layer, "Деревня открыта", status)


# "Уровни" in the main menu now opens the world map first.
func _show_level_select() -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "locations"
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_background(screen_layer, 0.48)

	var top_panel: PanelContainer = _panel(Vector2(1420.0, 90.0), Color(0.012, 0.040, 0.085, 0.92))
	top_panel.position = Vector2(90.0, 45.0)
	screen_layer.add_child(top_panel)
	var top_margin: MarginContainer = _margin(20, 13, 24, 13)
	top_panel.add_child(top_margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	top_margin.add_child(row)

	var home: Button = _icon_button(ICON_HOME, "В меню")
	home.pressed.connect(_on_menu_pressed)
	row.add_child(home)
	var title: Label = _label("Карта мира", 34, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(_label("%d / 20 уровней" % [forest_completed_levels + village_completed_levels], 18, COL_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

	var hint: Label = _label("Возвращай слова — и дорога будет открываться дальше", 18, Color(0.72, 0.84, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(420.0, 148.0)
	hint.size = Vector2(760.0, 40.0)
	screen_layer.add_child(hint)

	var points: Array[Vector2] = [
		Vector2(250.0, 620.0), Vector2(505.0, 470.0), Vector2(775.0, 585.0),
		Vector2(1045.0, 420.0), Vector2(1310.0, 565.0), Vector2(1180.0, 245.0)
	]
	_add_route(points, Color(0.25, 0.55, 0.82, 0.42), 8.0)

	_add_location_node("forest", "Лес", 1, points[0], true, forest_completed_levels, ICON_CHAPTER)
	_add_location_node("village", "Деревня", 2, points[1], forest_completed_levels >= 10, village_completed_levels, VILLAGE_CHAPTER_ICON)

	var future: Array = [
		["sea", "Море", 3], ["city", "Город", 4], ["fairy", "Сказки", 5], ["tower", "Башня", 6]
	]
	for i in range(future.size()):
		var data: Array = future[i]
		_add_location_node(String(data[0]), String(data[1]), int(data[2]), points[i + 2], false, 0, ICON_LOCK)


func _add_location_node(location_id: String, title: String, number: int, center: Vector2, unlocked: bool, completed: int, icon: Texture2D) -> void:
	var state_texture: Texture2D = WORLD_NODE_LOCKED
	if completed >= LEVEL_CATALOG.LEVELS_PER_LOCATION:
		state_texture = WORLD_NODE_COMPLETE
	elif unlocked:
		state_texture = WORLD_NODE_CURRENT
	elif completed > 0:
		state_texture = WORLD_NODE_OPEN

	# Soft glow behind the currently playable location.
	if unlocked and completed < LEVEL_CATALOG.LEVELS_PER_LOCATION:
		_add_map_texture(WORLD_PATH_GLOW, Rect2(center - Vector2(76.0, 76.0), Vector2(152.0, 152.0)), 0.72)

	var button: Button = Button.new()
	button.position = center - Vector2(58.0, 58.0)
	button.size = Vector2(116.0, 116.0)
	button.custom_minimum_size = button.size
	button.text = ""
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 48)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.disabled = not unlocked
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _texture_style(state_texture))
	button.add_theme_stylebox_override("hover", _texture_style(WORLD_NODE_OPEN if unlocked else state_texture))
	button.add_theme_stylebox_override("pressed", _texture_style(WORLD_NODE_CURRENT))
	button.add_theme_stylebox_override("disabled", _texture_style(WORLD_NODE_LOCKED))
	if unlocked:
		button.pressed.connect(Callable(self, "_on_location_selected").bind(location_id))
	screen_layer.add_child(button)

	_add_map_texture(WORLD_LABEL_PLATE, Rect2(center.x - 100.0, center.y + 53.0, 200.0, 48.0), 1.0)
	var label_text: Label = _label("%02d · %s" % [number, title], 18, COL_TEXT if unlocked else COL_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	label_text.position = Vector2(center.x - 94.0, center.y + 61.0)
	label_text.size = Vector2(188.0, 30.0)
	label_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(label_text)

	_add_map_texture(WORLD_PROGRESS_PLATE, Rect2(center.x - 62.0, center.y + 96.0, 124.0, 34.0), 1.0)
	var progress: Label = _label("%d / 10" % completed, 14, COL_GREEN if completed >= 10 else COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	progress.position = Vector2(center.x - 58.0, center.y + 101.0)
	progress.size = Vector2(116.0, 24.0)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(progress)


func _on_location_selected(location_id: String) -> void:
	_ui_click()
	if not _is_location_unlocked(location_id):
		return
	current_level_id = location_id
	if location_id == "village" and not village_transition_seen:
		_show_village_transition()
		return
	_show_location_levels(location_id)


func _show_location_levels(location_id: String) -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "location_levels"
	current_level_id = location_id
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_location_background(screen_layer, location_id, 0.40)
	var completed: int = _completed_for_location(location_id)
	var location_title: String = LEVEL_CATALOG.location_title(location_id)

	var top_panel: PanelContainer = _panel(Vector2(1420.0, 90.0), Color(0.012, 0.040, 0.085, 0.93))
	top_panel.position = Vector2(90.0, 45.0)
	screen_layer.add_child(top_panel)
	var top_margin: MarginContainer = _margin(20, 13, 24, 13)
	top_panel.add_child(top_margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	top_margin.add_child(row)
	var back: Button = _icon_button(ICON_CHAPTER, "К карте мира")
	back.pressed.connect(_show_level_select)
	row.add_child(back)
	var heading: Label = _label("%s · карта уровней" % location_title, 32, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	row.add_child(_label("%d / 10" % completed, 20, COL_GREEN if completed >= 10 else COL_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

	var route_points: Array[Vector2] = [
		Vector2(245.0, 710.0), Vector2(445.0, 595.0), Vector2(665.0, 690.0),
		Vector2(885.0, 570.0), Vector2(1125.0, 665.0), Vector2(1320.0, 515.0),
		Vector2(1120.0, 380.0), Vector2(865.0, 455.0), Vector2(610.0, 330.0), Vector2(840.0, 215.0)
	]
	_add_route(route_points, Color(0.36, 0.67, 0.92, 0.56), 10.0)

	for i in range(10):
		var level_number: int = i + 1
		var unlocked: bool = level_number <= mini(10, completed + 1) or completed >= 10
		var done: bool = level_number <= completed
		_add_level_node(location_id, level_number, route_points[i], unlocked, done)


func _add_level_node(location_id: String, level_number: int, center: Vector2, unlocked: bool, done: bool) -> void:
	var state_texture: Texture2D = LEVEL_NODE_LOCKED
	if done:
		state_texture = LEVEL_NODE_COMPLETE
	elif unlocked:
		state_texture = LEVEL_NODE_CURRENT
	else:
		state_texture = LEVEL_NODE_LOCKED

	var button: Button = Button.new()
	button.position = center - Vector2(45.0, 45.0)
	button.size = Vector2(90.0, 90.0)
	button.custom_minimum_size = button.size
	button.text = str(level_number)
	button.disabled = not unlocked
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_control_font(button, 24, COL_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.64, 0.72, 0.92))
	button.add_theme_stylebox_override("normal", _texture_style(state_texture))
	button.add_theme_stylebox_override("hover", _texture_style(LEVEL_NODE_OPEN if unlocked else state_texture))
	button.add_theme_stylebox_override("pressed", _texture_style(LEVEL_NODE_CURRENT))
	button.add_theme_stylebox_override("disabled", _texture_style(LEVEL_NODE_LOCKED))
	if unlocked:
		button.pressed.connect(Callable(self, "_on_level_node_pressed").bind(location_id, level_number))
	screen_layer.add_child(button)

	var title: Label = _label(LEVEL_CATALOG.level_title(location_id, level_number), 13, COL_TEXT if unlocked else COL_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(center.x - 88.0, center.y + 49.0)
	title.size = Vector2(176.0, 32.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(title)


func _on_level_node_pressed(location_id: String, level_number: int) -> void:
	if level_number > _completed_for_location(location_id) + 1 and _completed_for_location(location_id) < 10:
		return
	_ui_click()
	current_level_id = location_id
	current_stage_number = level_number
	_start_game()


func _add_route(points: Array[Vector2], _color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var segment_texture: Texture2D = WORLD_PATH_SEGMENT if current_screen == "locations" else LEVEL_PATH_SEGMENT
	var dot_texture: Texture2D = WORLD_PATH_DOT if current_screen == "locations" else LEVEL_PATH_DOT
	var segment_height: float = maxf(12.0, width * 1.6)

	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[i + 1]
		var delta: Vector2 = finish - start
		var length: float = delta.length()
		if length <= 1.0:
			continue
		var segment: TextureRect = TextureRect.new()
		segment.texture = segment_texture
		segment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		segment.stretch_mode = TextureRect.STRETCH_SCALE
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.size = Vector2(length, segment_height)
		segment.position = start - Vector2(0.0, segment_height * 0.5)
		segment.pivot_offset = Vector2(0.0, segment_height * 0.5)
		segment.rotation = delta.angle()
		screen_layer.add_child(segment)

	var dot_size: float = 18.0 if current_screen == "locations" else 14.0
	for point in points:
		_add_map_texture(dot_texture, Rect2(point - Vector2(dot_size * 0.5, dot_size * 0.5), Vector2(dot_size, dot_size)), 1.0)


func _add_map_texture(texture: Texture2D, rect: Rect2, opacity: float) -> void:
	var art: TextureRect = TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.position = rect.position
	art.size = rect.size
	art.modulate = Color(1.0, 1.0, 1.0, opacity)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(art)


func _texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = texture
	return style


func _add_location_background(parent: Control, location_id: String, darkness: float) -> void:
	var texture: TextureRect = TextureRect.new()
	texture.texture = VILLAGE_MENU_BACKGROUND if location_id == "village" else FOREST_MENU_BACKGROUND
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(texture)
	parent.add_child(texture)
	var tint: ColorRect = ColorRect.new()
	tint.color = Color(0.0, 0.015, 0.045, darkness)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(tint)
	parent.add_child(tint)


func _on_play_pressed() -> void:
	_ui_click()
	intro_replay_only = false
	if not intro_seen:
		current_level_id = "forest"
		current_stage_number = 1
		_show_intro(0)
		return
	if forest_completed_levels < 10:
		current_level_id = "forest"
		current_stage_number = mini(10, forest_completed_levels + 1)
		_start_game()
		return
	if not village_transition_seen:
		current_level_id = "village"
		_show_village_transition()
		return
	if village_completed_levels < 10:
		current_level_id = "village"
		current_stage_number = mini(10, village_completed_levels + 1)
		_start_game()
		return
	_show_level_select()


func _finish_intro() -> void:
	intro_seen = true
	_save_local_state()
	if intro_replay_only:
		intro_replay_only = false
		_show_main_menu()
		return
	current_level_id = "forest"
	current_stage_number = 1
	_start_game()


func _finish_village_transition() -> void:
	village_transition_seen = true
	current_level_id = "village"
	current_stage_number = mini(10, village_completed_levels + 1)
	_save_local_state()
	_show_location_levels("village")


func _start_game() -> void:
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "game"
	result_seen = false

	if app_audio != null:
		app_audio.set_suspended("gameplay", true)

	game = GAMEPLAY_SCENE.instantiate() as Control
	if game == null:
		return
	if game.has_method("configure_level"):
		game.call("configure_level", current_level_id, current_stage_number)
	elif game.has_method("configure_chapter"):
		game.call("configure_chapter", current_level_id)
	_full_rect(game)
	screen_layer.add_child(game)

	var settings_button: Button = _floating_icon_button(ICON_SETTINGS)
	settings_button.position = Vector2(28.0, 22.0)
	settings_button.pressed.connect(_on_game_settings_pressed)
	gameplay_ui_layer.add_child(settings_button)
	var pause_button: Button = _floating_icon_button(ICON_PAUSE)
	pause_button.position = Vector2(1510.0, 22.0)
	pause_button.pressed.connect(_on_pause_pressed)
	gameplay_ui_layer.add_child(pause_button)
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	call_deferred("_sync_game_audio")


func _show_pause_modal() -> void:
	super._show_pause_modal()
	_replace_label_text(modal_layer, "Глава 1 · Лес", "Лес · Уровень %d / 10" % current_stage_number)
	_replace_label_text(modal_layer, "Глава 2 · Деревня", "Деревня · Уровень %d / 10" % current_stage_number)


func _show_result_modal(victory: bool) -> void:
	super._show_result_modal(victory)
	if not victory:
		return
	if current_stage_number < 10:
		_replace_label_text(modal_layer, "Глава пройдена!", "Уровень %d пройден!" % current_stage_number)
		_replace_button_text(modal_layer, "Дальше", "Следующий уровень")
		_replace_button_text(modal_layer, "К уровням", "Следующий уровень")
	else:
		var complete_title: String = "%s восстановлен!" % ("Лес" if current_level_id == "forest" else "Деревня")
		_replace_label_text(modal_layer, "Глава пройдена!", complete_title)
		if current_level_id == "forest":
			_replace_button_text(modal_layer, "Дальше", "Завершить локацию")
			_replace_button_text(modal_layer, "К уровням", "Завершить локацию")
		else:
			_replace_button_text(modal_layer, "К уровням", "К карте мира")


func _on_levels_pressed() -> void:
	_ui_click()
	if current_screen == "game" and game != null and is_instance_valid(game) and bool(game.get("chapter_complete")):
		if current_stage_number < 10:
			current_stage_number += 1
			_start_game()
			return
		if current_level_id == "forest" and not village_transition_seen:
			_show_village_transition()
			return
		_show_level_select()
		return
	if current_screen == "game":
		_show_location_levels(current_level_id)
		return
	_show_level_select()


func _store_victory_stats() -> void:
	if game == null or not is_instance_valid(game):
		return
	if current_level_id == "forest":
		forest_completed_levels = maxi(forest_completed_levels, current_stage_number)
	elif current_level_id == "village":
		village_completed_levels = maxi(village_completed_levels, current_stage_number)

	level_one_complete = forest_completed_levels >= 10
	village_complete = village_completed_levels >= 10

	var score_value: int = int(game.get("score"))
	var time_value: float = float(game.get("elapsed"))
	best_score = maxi(best_score, score_value)
	if best_time <= 0.0 or time_value < best_time:
		best_time = time_value
	_save_local_state()


func _completed_for_location(location_id: String) -> int:
	return village_completed_levels if location_id == "village" else forest_completed_levels


func _is_location_unlocked(location_id: String) -> bool:
	if location_id == "forest":
		return true
	if location_id == "village":
		return forest_completed_levels >= 10
	return false


func _reset_progress_data() -> void:
	forest_completed_levels = 0
	village_completed_levels = 0
	current_stage_number = 1
	super._reset_progress_data()


func _load_local_state() -> void:
	# Capture legacy state before parent migrations can rewrite it.
	var raw: ConfigFile = ConfigFile.new()
	var has_raw: bool = raw.load(SETTINGS_PATH) == OK
	var old_forest_complete: bool = bool(raw.get_value("progress", "level_one_complete", false)) if has_raw else false
	var old_village_complete: bool = bool(raw.get_value("progress", "village_complete", false)) if has_raw else false
	var progress_version: int = int(raw.get_value("meta", "level_progress_version", 0)) if has_raw else 0

	super._load_local_state()

	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK and progress_version >= LEVEL_PROGRESS_VERSION:
		forest_completed_levels = clampi(int(config.get_value("levels", "forest_completed", 0)), 0, 10)
		village_completed_levels = clampi(int(config.get_value("levels", "village_completed", 0)), 0, 10)
		current_level_id = String(config.get_value("levels", "last_location", "forest"))
		current_stage_number = clampi(int(config.get_value("levels", "last_level", 1)), 1, 10)
	else:
		# The previous build had one round per location. Treat that old Forest round
		# as level 1, not as all ten levels, so old test saves do not skip the game.
		forest_completed_levels = 1 if old_forest_complete or old_village_complete else 0
		village_completed_levels = 0
		village_transition_seen = false
		current_level_id = "forest"
		current_stage_number = mini(10, forest_completed_levels + 1)

	level_one_complete = forest_completed_levels >= 10
	village_complete = village_completed_levels >= 10
	if not level_one_complete:
		village_transition_seen = false
	if progress_version < LEVEL_PROGRESS_VERSION:
		_save_local_state()


func _save_local_state() -> void:
	level_one_complete = forest_completed_levels >= 10
	village_complete = village_completed_levels >= 10
	super._save_local_state()
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("meta", "level_progress_version", LEVEL_PROGRESS_VERSION)
	config.set_value("levels", "forest_completed", forest_completed_levels)
	config.set_value("levels", "village_completed", village_completed_levels)
	config.set_value("levels", "last_location", current_level_id)
	config.set_value("levels", "last_level", current_stage_number)
	config.save(SETTINGS_PATH)
