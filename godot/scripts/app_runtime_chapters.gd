extends "res://scripts/app_runtime_story.gd"

# Multi-chapter progression layer.
# Chapter 1: Forest. Chapter 2: Village.

const FOREST_MENU_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_forest.webp")
const VILLAGE_MENU_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_village.webp")
const VILLAGE_CHAPTER_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_village.svg")

const VILLAGE_TRANSITION_FRAMES: Array[Texture2D] = [
	preload("res://assets/comics/village_unlock/village_unlock_01.webp"),
	preload("res://assets/comics/village_unlock/village_unlock_02.webp"),
	preload("res://assets/comics/village_unlock/village_unlock_03.webp")
]

var current_level_id: String = "forest"
var village_complete: bool = false
var village_transition_seen: bool = false
var intro_replay_only: bool = false


func _input(event: InputEvent) -> void:
	if current_screen == "village_transition" and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_RIGHT:
				_unlock_app_audio()
				_finish_village_transition()
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode == KEY_ESCAPE:
				_unlock_app_audio()
				_show_level_select()
				get_viewport().set_input_as_handled()
				return

	super._input(event)


func _show_main_menu() -> void:
	super._show_main_menu()
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if level_one_complete:
		_replace_label_text(screen_layer, "Лес · 5 слов", "Деревня · 5 слов")
		if village_complete:
			_replace_label_text(screen_layer, "Лес пройден", "Деревня пройдена")
		else:
			_replace_label_text(screen_layer, "Лес пройден", "Деревня открыта")


func _add_background(parent: Control, darkness: float) -> void:
	var texture: TextureRect = TextureRect.new()
	texture.texture = VILLAGE_MENU_BACKGROUND if level_one_complete else FOREST_MENU_BACKGROUND
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


func _show_level_select() -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "levels"
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_background(screen_layer, 0.42)

	var top_panel: PanelContainer = _panel(Vector2(1420.0, 86.0), Color(0.015, 0.045, 0.095, 0.90))
	top_panel.position = Vector2(90.0, 54.0)
	screen_layer.add_child(top_panel)
	var top_margin: MarginContainer = _margin(22, 14, 22, 14)
	top_panel.add_child(top_margin)
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 20)
	top_margin.add_child(top_row)

	var back_button: Button = _icon_button(ICON_HOME, "В меню")
	back_button.pressed.connect(_on_menu_pressed)
	top_row.add_child(back_button)

	var heading: Label = _label("Уровни", 34, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(heading)
	var open_count: int = 2 if level_one_complete else 1
	top_row.add_child(_label("%d / 6" % open_count, 18, COL_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	grid.position = Vector2(180.0, 205.0)
	grid.size = Vector2(1240.0, 560.0)
	screen_layer.add_child(grid)

	var forest_subtitle: String = "Пройдено" if level_one_complete else "5 слов"
	var forest_card: Button = _level_card(1, "Лес", forest_subtitle, true)
	forest_card.pressed.connect(Callable(self, "_on_level_selected").bind("forest"))
	grid.add_child(forest_card)

	var village_subtitle: String = "Пройдено" if village_complete else ("5 слов" if level_one_complete else "После леса")
	var village_card: Button = _level_card(2, "Деревня", village_subtitle, level_one_complete)
	village_card.icon = VILLAGE_CHAPTER_ICON if level_one_complete else ICON_LOCK
	village_card.pressed.connect(Callable(self, "_on_level_selected").bind("village"))
	grid.add_child(village_card)

	var future_levels: Array = [
		[3, "Море"],
		[4, "Город"],
		[5, "Сказки"],
		[6, "Башня"]
	]
	for data in future_levels:
		var locked_card: Button = _level_card(int(data[0]), String(data[1]), "Скоро", false)
		grid.add_child(locked_card)


func _on_level_selected(level_id: String) -> void:
	_ui_click()
	if level_id == "village" and not level_one_complete:
		return
	current_level_id = level_id
	intro_replay_only = false
	if level_id == "village" and not village_transition_seen:
		_show_village_transition()
	else:
		_start_game()


func _on_play_pressed() -> void:
	_ui_click()
	intro_replay_only = false
	if not intro_seen:
		current_level_id = "forest"
		_show_intro(0)
		return
	if not level_one_complete:
		current_level_id = "forest"
		_start_game()
		return
	current_level_id = "village"
	if not village_transition_seen:
		_show_village_transition()
	else:
		_start_game()


func _on_replay_intro_pressed() -> void:
	_ui_click()
	_clear_modal()
	intro_replay_only = true
	_show_intro(0)


func _finish_intro() -> void:
	intro_seen = true
	_save_local_state()
	if intro_replay_only:
		intro_replay_only = false
		_show_main_menu()
		return
	current_level_id = "forest"
	_start_game()


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
	if game.has_method("configure_chapter"):
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
	if current_level_id == "village":
		_replace_label_text(modal_layer, "Глава 1 · Лес", "Глава 2 · Деревня")


func _show_result_modal(victory: bool) -> void:
	super._show_result_modal(victory)
	if victory and current_level_id == "forest" and not village_transition_seen:
		_replace_button_text(modal_layer, "К уровням", "Дальше")


func _on_levels_pressed() -> void:
	_ui_click()
	if current_screen == "game" and game != null and is_instance_valid(game):
		var finished: bool = bool(game.get("chapter_complete"))
		if finished and current_level_id == "forest" and not village_transition_seen:
			_show_village_transition()
			return
	_show_level_select()


func _show_village_transition() -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "village_transition"
	current_modal = ""
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	var background: ColorRect = ColorRect.new()
	background.color = Color("020914")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(background)
	screen_layer.add_child(background)

	var page_back: PanelContainer = PanelContainer.new()
	page_back.position = Vector2(28.0, 22.0)
	page_back.size = Vector2(1544.0, 856.0)
	page_back.add_theme_stylebox_override("panel", _comic_page_style())
	page_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(page_back)

	# One comic page with three panels: a large success frame and two story beats.
	_add_comic_panel(VILLAGE_TRANSITION_FRAMES[0], Rect2(55.0, 145.0, 720.0, 405.0))
	_add_comic_panel(VILLAGE_TRANSITION_FRAMES[1], Rect2(825.0, 70.0, 720.0, 405.0))
	_add_comic_panel(VILLAGE_TRANSITION_FRAMES[2], Rect2(825.0, 493.0, 720.0, 405.0))

	var title: Label = _label("Лес спасён", 28, COL_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(180.0, 595.0)
	title.size = Vector2(470.0, 46.0)
	screen_layer.add_child(title)

	var start_button: Button = _button("В деревню", "primary", VILLAGE_CHAPTER_ICON, 62.0)
	start_button.position = Vector2(245.0, 665.0)
	start_button.size = Vector2(340.0, 62.0)
	start_button.pressed.connect(_on_village_transition_start)
	screen_layer.add_child(start_button)

	var levels_button: Button = _button("К уровням", "ghost", ICON_CHAPTER, 54.0)
	levels_button.position = Vector2(245.0, 744.0)
	levels_button.size = Vector2(340.0, 54.0)
	levels_button.pressed.connect(_on_village_transition_levels)
	screen_layer.add_child(levels_button)

	for child in screen_layer.get_children():
		if child == background:
			continue
		if child is CanvasItem:
			(child as CanvasItem).modulate.a = 0.0
	var fade: Tween = create_tween()
	fade.set_parallel(true)
	for child in screen_layer.get_children():
		if child == background:
			continue
		if child is CanvasItem:
			fade.tween_property(child, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_village_transition_start() -> void:
	_ui_click()
	_finish_village_transition()


func _on_village_transition_levels() -> void:
	_ui_click()
	_show_level_select()


func _finish_village_transition() -> void:
	village_transition_seen = true
	current_level_id = "village"
	_save_local_state()
	_start_game()


func _store_victory_stats() -> void:
	if game == null or not is_instance_valid(game):
		return
	if current_level_id == "forest":
		level_one_complete = true
	elif current_level_id == "village":
		village_complete = true

	var score_value: int = int(game.get("score"))
	var time_value: float = float(game.get("elapsed"))
	best_score = maxi(best_score, score_value)
	if best_time <= 0.0 or time_value < best_time:
		best_time = time_value
	_save_local_state()


func _reset_progress_data() -> void:
	village_complete = false
	village_transition_seen = false
	current_level_id = "forest"
	intro_replay_only = false
	super._reset_progress_data()


func _load_local_state() -> void:
	super._load_local_state()
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		village_complete = false
		village_transition_seen = false
		return
	village_complete = bool(config.get_value("progress", "village_complete", false))
	village_transition_seen = bool(config.get_value("story", "village_transition_seen", false))
	if not level_one_complete:
		village_complete = false
		village_transition_seen = false


func _save_local_state() -> void:
	super._save_local_state()
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("progress", "village_complete", village_complete)
	config.set_value("story", "village_transition_seen", village_transition_seen)
	config.save(SETTINGS_PATH)


func _replace_label_text(root: Node, old_text: String, new_text: String) -> void:
	for child in root.get_children():
		if child is Label and (child as Label).text == old_text:
			(child as Label).text = new_text
		_replace_label_text(child, old_text, new_text)


func _replace_button_text(root: Node, old_text: String, new_text: String) -> void:
	for child in root.get_children():
		if child is Button and (child as Button).text == old_text:
			(child as Button).text = new_text
		_replace_button_text(child, old_text, new_text)
