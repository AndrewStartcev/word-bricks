extends "res://scripts/app_runtime_compat.gd"

# Story/progression layer:
# - five-frame intro comic before the first game;
# - one-time migration that clears old prototype progression;
# - replay intro and reset progression from settings.

const SAVE_VERSION: int = 2

const INTRO_FRAMES: Array[Texture2D] = [
	preload("res://assets/comics/intro/intro_01_world.png"),
	preload("res://assets/comics/intro/intro_02_wizard.png"),
	preload("res://assets/comics/intro/intro_03_disappearance.png"),
	preload("res://assets/comics/intro/intro_04_owl.png"),
	preload("res://assets/comics/intro/intro_05_journey.png")
]

var intro_seen: bool = false
var intro_index: int = 0
var settings_from_game: bool = false


func _input(event: InputEvent) -> void:
	if current_screen == "intro" and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_RIGHT:
				_unlock_app_audio()
				_advance_intro()
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode == KEY_ESCAPE:
				_unlock_app_audio()
				_finish_intro()
				get_viewport().set_input_as_handled()
				return

	super._input(event)


func _on_play_pressed() -> void:
	_ui_click()
	if intro_seen:
		_start_game()
	else:
		_show_intro(0)


func _show_intro(frame_index: int = 0) -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "intro"
	current_modal = ""
	intro_index = clampi(frame_index, 0, INTRO_FRAMES.size() - 1)

	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_render_intro_frame()


func _render_intro_frame() -> void:
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)

	var background: ColorRect = ColorRect.new()
	background.color = Color("020914")
	_full_rect(background)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(background)

	var frame: TextureRect = TextureRect.new()
	frame.texture = INTRO_FRAMES[intro_index]
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(frame)
	frame.modulate.a = 0.0
	screen_layer.add_child(frame)

	var fade: Tween = create_tween()
	fade.tween_property(frame, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var counter_panel: PanelContainer = _panel(Vector2(112.0, 44.0), Color(0.008, 0.025, 0.055, 0.78))
	counter_panel.position = Vector2(42.0, 38.0)
	screen_layer.add_child(counter_panel)
	var counter_margin: MarginContainer = _margin(12, 6, 12, 6)
	counter_panel.add_child(counter_margin)
	counter_margin.add_child(_label("%d / %d" % [intro_index + 1, INTRO_FRAMES.size()], 16, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))

	var skip_button: Button = _button("Пропустить", "ghost", null, 48.0)
	skip_button.position = Vector2(1370.0, 34.0)
	skip_button.size = Vector2(180.0, 48.0)
	skip_button.pressed.connect(_on_intro_skip_pressed)
	screen_layer.add_child(skip_button)

	var next_text: String = "Начать" if intro_index == INTRO_FRAMES.size() - 1 else "Далее"
	var next_button: Button = _button(next_text, "primary", null, 58.0)
	next_button.position = Vector2(1320.0, 806.0)
	next_button.size = Vector2(230.0, 58.0)
	next_button.pressed.connect(_on_intro_next_pressed)
	screen_layer.add_child(next_button)


func _on_intro_next_pressed() -> void:
	_ui_click()
	_advance_intro()


func _on_intro_skip_pressed() -> void:
	_ui_click()
	_finish_intro()


func _advance_intro() -> void:
	if intro_index >= INTRO_FRAMES.size() - 1:
		_finish_intro()
		return
	intro_index += 1
	_render_intro_frame()


func _finish_intro() -> void:
	intro_seen = true
	_save_local_state()
	_start_game()


func _show_settings_modal(from_game: bool) -> void:
	settings_from_game = from_game
	super._show_settings_modal(from_game)

	var panel: PanelContainer = _get_current_modal_panel()
	if panel == null:
		return

	panel.custom_minimum_size = Vector2(610.0, 650.0)
	_center_control(panel)

	var column: VBoxContainer = _get_modal_main_column(panel)
	if column == null:
		return

	column.add_child(_modal_spacer(4.0))

	var replay_intro_button: Button = _button("Посмотреть вступление", "ghost", null, 52.0)
	replay_intro_button.pressed.connect(_on_replay_intro_pressed)
	column.add_child(replay_intro_button)

	var reset_button: Button = _button("Сбросить прогресс", "ghost", ICON_RESTART, 52.0)
	reset_button.add_theme_color_override("font_color", Color("ffc9c9"))
	reset_button.pressed.connect(_on_reset_progress_pressed)
	column.add_child(reset_button)


func _on_replay_intro_pressed() -> void:
	_ui_click()
	_clear_modal()
	_show_intro(0)


func _on_reset_progress_pressed() -> void:
	_ui_click()
	_show_reset_progress_confirm()


func _show_reset_progress_confirm() -> void:
	_clear_modal()
	current_modal = "reset_confirm"

	if current_screen == "game":
		_pause_game(true)

	var panel: PanelContainer = _modal_panel(Vector2(560.0, 360.0))
	var column: VBoxContainer = _modal_column(panel)
	column.add_child(_label("Сбросить прогресс?", 34, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_label("Уровни, рекорды и просмотр вступления будут сброшены.\nНастройки музыки и звука останутся.", 17, COL_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(10.0))

	var confirm_button: Button = _button("Сбросить", "primary", ICON_RESTART, 60.0)
	confirm_button.pressed.connect(_confirm_progress_reset)
	column.add_child(confirm_button)

	var cancel_button: Button = _button("Отмена", "ghost", null, 52.0)
	cancel_button.pressed.connect(_cancel_progress_reset)
	column.add_child(cancel_button)
	_animate_in(panel)


func _confirm_progress_reset() -> void:
	_ui_click()
	_reset_progress_data()
	_show_main_menu()


func _cancel_progress_reset() -> void:
	_ui_click()
	_clear_modal()
	_show_settings_modal(settings_from_game)


func _reset_progress_data() -> void:
	intro_seen = false
	level_one_complete = false
	best_score = 0
	best_time = 0.0
	result_seen = false
	_save_local_state()


func _load_local_state() -> void:
	super._load_local_state()

	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		intro_seen = false
		return

	var stored_version: int = int(config.get_value("meta", "save_version", 0))
	intro_seen = bool(config.get_value("story", "intro_seen", false))

	# Prototype saves existed before story progression. Clear only progression once,
	# while preserving the user's audio preferences.
	if stored_version < SAVE_VERSION:
		intro_seen = false
		level_one_complete = false
		best_score = 0
		best_time = 0.0
		_save_local_state()


func _save_local_state() -> void:
	super._save_local_state()

	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("meta", "save_version", SAVE_VERSION)
	config.set_value("story", "intro_seen", intro_seen)
	config.save(SETTINGS_PATH)


func _get_current_modal_panel() -> PanelContainer:
	for child in modal_layer.get_children():
		if child is PanelContainer:
			return child as PanelContainer
	return null


func _get_modal_main_column(panel: PanelContainer) -> VBoxContainer:
	if panel.get_child_count() == 0:
		return null
	var margin: Node = panel.get_child(0)
	for child in margin.get_children():
		if child is VBoxContainer:
			return child as VBoxContainer
	return null
