extends Control

# Application shell around gameplay.
# Menus and modals use real Control nodes; the gameplay board remains in game.gd.

const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/gameplay.tscn")
const AUDIO_SERVICE_SCRIPT: Script = preload("res://scripts/audio_service.gd")

const BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_forest.webp")
const OWL_IDLE: Texture2D = preload("res://assets/characters/owl/owl_idle.webp")
const OWL_HAPPY: Texture2D = preload("res://assets/characters/owl/owl_happy.webp")
const OWL_DEFEAT: Texture2D = preload("res://assets/characters/owl/owl_defeat.webp")

const ICON_SETTINGS: Texture2D = preload("res://assets/ui/icons/icon_settings.svg")
const ICON_PAUSE: Texture2D = preload("res://assets/ui/icons/icon_pause.svg")
const ICON_HOME: Texture2D = preload("res://assets/ui/icons/icon_home.svg")
const ICON_RESTART: Texture2D = preload("res://assets/ui/icons/icon_restart.svg")
const ICON_LOCK: Texture2D = preload("res://assets/ui/icons/icon_lock.svg")
const ICON_CHAPTER: Texture2D = preload("res://assets/ui/icons/icon_chapter_forest.svg")
const ICON_MUSIC_ON: Texture2D = preload("res://assets/ui/icons/icon_music_on.svg")
const ICON_SOUND_ON: Texture2D = preload("res://assets/ui/icons/icon_sound_on.svg")
const ICON_SCORE: Texture2D = preload("res://assets/ui/icons/icon_score.svg")
const ICON_COMBO: Texture2D = preload("res://assets/ui/icons/icon_combo.svg")
const ICON_TIME: Texture2D = preload("res://assets/ui/icons/icon_time.svg")

const SETTINGS_PATH: String = "user://word_bricks_settings.cfg"

const COL_PANEL: Color = Color(0.018, 0.055, 0.115, 0.94)
const COL_PANEL_SOFT: Color = Color(0.025, 0.085, 0.16, 0.94)
const COL_BORDER: Color = Color(0.17, 0.46, 0.76, 0.72)
const COL_TEXT: Color = Color("f5f8ff")
const COL_MUTED: Color = Color("9fb3d1")
const COL_PRIMARY: Color = Color("2f8df6")
const COL_PRIMARY_HOVER: Color = Color("46a2ff")
const COL_PRIMARY_PRESS: Color = Color("1f72d1")
const COL_GREEN: Color = Color("69de87")

var game_font: SystemFont = SystemFont.new()
var app_audio: Node = null
var game: Control = null

var screen_layer: Control
var gameplay_ui_layer: Control
var modal_layer: Control

var current_screen: String = ""
var current_modal: String = ""
var result_seen: bool = false

var music_enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 0.72
var sfx_volume: float = 0.86
var level_one_complete: bool = false
var best_score: int = 0
var best_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_font.font_names = PackedStringArray(["Rubik", "Nunito", "Trebuchet MS", "Verdana", "Arial"])

	_load_local_state()

	app_audio = AUDIO_SERVICE_SCRIPT.new()
	app_audio.name = "AppAudioService"
	add_child(app_audio)
	_apply_audio_state(app_audio)

	screen_layer = Control.new()
	screen_layer.name = "ScreenLayer"
	_full_rect(screen_layer)
	screen_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_layer)

	gameplay_ui_layer = Control.new()
	gameplay_ui_layer.name = "GameplayUILayer"
	_full_rect(gameplay_ui_layer)
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gameplay_ui_layer)

	modal_layer = Control.new()
	modal_layer.name = "ModalLayer"
	_full_rect(modal_layer)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)

	_show_main_menu()


func _process(_delta: float) -> void:
	if current_screen != "game" or game == null or not is_instance_valid(game):
		return

	if current_modal.is_empty():
		if bool(game.get("chapter_complete")) and not result_seen:
			result_seen = true
			_show_result_modal(true)
			return
		if bool(game.get("game_over")) and not result_seen:
			result_seen = true
			_show_result_modal(false)
			return
		if bool(game.get("settings_open")):
			game.set("settings_open", false)
			_show_settings_modal(true)
			return
		if bool(game.get("manual_paused")):
			_show_pause_modal()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		_unlock_app_audio()

	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if current_screen == "game":
		if not current_modal.is_empty():
			if key_event.keycode == KEY_ESCAPE:
				if current_modal == "settings":
					_close_settings_modal()
				elif current_modal == "pause":
					_resume_game()
				get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
			_show_pause_modal()
			get_viewport().set_input_as_handled()
			return

	if current_screen == "levels" and key_event.keycode == KEY_ESCAPE:
		_show_main_menu()
		get_viewport().set_input_as_handled()


func _show_main_menu() -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "menu"
	result_seen = false

	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_background(screen_layer, 0.30)

	var owl: TextureRect = TextureRect.new()
	owl.texture = OWL_IDLE
	owl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	owl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owl.position = Vector2(80.0, 500.0)
	owl.size = Vector2(320.0, 320.0)
	screen_layer.add_child(owl)

	var panel: PanelContainer = _panel(Vector2(520.0, 555.0), COL_PANEL)
	_center_control(panel, Vector2(80.0, 0.0))
	screen_layer.add_child(panel)

	var margin: MarginContainer = _margin(54, 46, 54, 46)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	column.add_child(_label("СЛОВОПАД", 58, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_label("Лес · 5 слов", 20, COL_GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(18.0))

	var play_button: Button = _button("Играть", "primary", null, 70.0)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)

	var levels_button: Button = _button("Уровни", "secondary", ICON_CHAPTER, 62.0)
	levels_button.pressed.connect(_on_levels_pressed)
	column.add_child(levels_button)

	var settings_button: Button = _button("Настройки", "secondary", ICON_SETTINGS, 62.0)
	settings_button.pressed.connect(_on_menu_settings_pressed)
	column.add_child(settings_button)

	var status_text: String = "Лес пройден" if level_one_complete else "Первый уровень открыт"
	var status_color: Color = COL_GREEN if level_one_complete else COL_MUTED
	column.add_child(_label(status_text, 16, status_color, HORIZONTAL_ALIGNMENT_CENTER))

	_animate_in(panel)


func _show_level_select() -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "levels"

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
	top_row.add_child(_label("1 / 6", 18, COL_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	grid.position = Vector2(180.0, 205.0)
	grid.size = Vector2(1240.0, 560.0)
	screen_layer.add_child(grid)

	var levels: Array[Dictionary] = [
		{"title":"Лес", "subtitle":"5 слов", "open":true},
		{"title":"Море", "subtitle":"Скоро", "open":false},
		{"title":"Город", "subtitle":"Скоро", "open":false},
		{"title":"Еда", "subtitle":"Скоро", "open":false},
		{"title":"Космос", "subtitle":"Скоро", "open":false},
		{"title":"Сказки", "subtitle":"Скоро", "open":false}
	]

	for index in range(levels.size()):
		var data: Dictionary = levels[index]
		var unlocked: bool = bool(data["open"])
		var card: Button = _level_card(index + 1, String(data["title"]), String(data["subtitle"]), unlocked)
		if unlocked:
			card.pressed.connect(_on_play_pressed)
		grid.add_child(card)


func _start_game() -> void:
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "game"
	result_seen = false

	if app_audio != null:
		app_audio.set_suspended("gameplay", true)

	game = GAMEPLAY_SCENE.instantiate() as Control
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
	if game == null or not is_instance_valid(game):
		return
	if current_modal == "pause":
		return

	_clear_modal()
	current_modal = "pause"
	_pause_game(true)

	var panel: PanelContainer = _modal_panel(Vector2(520.0, 500.0))
	var column: VBoxContainer = _modal_column(panel)
	column.add_child(_label("Пауза", 44, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_label("Глава 1 · Лес", 18, COL_GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(12.0))

	var continue_button: Button = _button("Продолжить", "primary", null, 68.0)
	continue_button.pressed.connect(_on_resume_pressed)
	column.add_child(continue_button)

	var restart_button: Button = _button("Начать заново", "secondary", ICON_RESTART, 58.0)
	restart_button.pressed.connect(_on_restart_pressed)
	column.add_child(restart_button)

	var settings_button: Button = _button("Настройки", "secondary", ICON_SETTINGS, 58.0)
	settings_button.pressed.connect(_on_game_settings_pressed)
	column.add_child(settings_button)

	var levels_button: Button = _button("К уровням", "ghost", ICON_CHAPTER, 52.0)
	levels_button.pressed.connect(_on_levels_pressed)
	column.add_child(levels_button)

	var menu_button: Button = _button("В меню", "ghost", ICON_HOME, 52.0)
	menu_button.pressed.connect(_on_menu_pressed)
	column.add_child(menu_button)

	_animate_in(panel)


func _show_result_modal(victory: bool) -> void:
	if game == null or not is_instance_valid(game):
		return

	_clear_modal()
	current_modal = "victory" if victory else "defeat"
	_pause_game(true)

	var panel: PanelContainer = _modal_panel(Vector2(650.0, 570.0))
	var column: VBoxContainer = _modal_column(panel)

	var owl: TextureRect = TextureRect.new()
	owl.texture = OWL_HAPPY if victory else OWL_DEFEAT
	owl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	owl.custom_minimum_size = Vector2(180.0, 140.0)
	owl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(owl)

	var title_text: String = "Глава пройдена!" if victory else "Партия окончена"
	var title_color: Color = COL_GREEN if victory else COL_TEXT
	column.add_child(_label(title_text, 42, title_color, HORIZONTAL_ALIGNMENT_CENTER))

	var completed_words_value: Variant = game.get("completed_words")
	var completed_count: int = 0
	if completed_words_value is Array:
		completed_count = (completed_words_value as Array).size()
	column.add_child(_label("%d / 5 слов" % completed_count, 18, COL_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(4.0))

	var stats: HBoxContainer = HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 12)
	stats.add_child(_stat_card("Очки", str(int(game.get("score"))), ICON_SCORE))
	stats.add_child(_stat_card("Время", _format_time(float(game.get("elapsed"))), ICON_TIME))
	stats.add_child(_stat_card("Комбо", "x%d" % maxi(1, int(game.get("best_combo"))), ICON_COMBO))
	column.add_child(stats)
	column.add_child(_modal_spacer(10.0))

	if victory:
		_store_victory_stats()
		var levels_button: Button = _button("К уровням", "primary", ICON_CHAPTER, 66.0)
		levels_button.pressed.connect(_on_levels_pressed)
		column.add_child(levels_button)
	else:
		var retry_button: Button = _button("Начать заново", "primary", ICON_RESTART, 66.0)
		retry_button.pressed.connect(_on_restart_pressed)
		column.add_child(retry_button)

	var replay_button: Button = _button("Играть ещё раз", "secondary", ICON_RESTART, 56.0)
	replay_button.pressed.connect(_on_restart_pressed)
	column.add_child(replay_button)

	var menu_button: Button = _button("В меню", "ghost", ICON_HOME, 52.0)
	menu_button.pressed.connect(_on_menu_pressed)
	column.add_child(menu_button)

	_animate_in(panel)


func _show_settings_modal(from_game: bool) -> void:
	_clear_modal()
	current_modal = "settings"

	if from_game and game != null and is_instance_valid(game):
		game.set("settings_open", false)
		_pause_game(true)

	var panel: PanelContainer = _modal_panel(Vector2(610.0, 500.0))
	var column: VBoxContainer = _modal_column(panel)
	column.add_child(_label("Настройки", 40, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(8.0))
	column.add_child(_settings_row("Музыка", ICON_MUSIC_ON, true))
	column.add_child(_settings_row("Звуки", ICON_SOUND_ON, false))
	column.add_child(_modal_spacer(12.0))

	var done_button: Button = _button("Готово", "primary", null, 64.0)
	done_button.pressed.connect(_on_settings_done_pressed)
	column.add_child(done_button)
	_animate_in(panel)


func _settings_row(title: String, icon: Texture2D, is_music: bool) -> Control:
	var wrap: PanelContainer = _panel(Vector2(0.0, 108.0), COL_PANEL_SOFT)
	wrap.custom_minimum_size = Vector2(0.0, 108.0)
	var margin: MarginContainer = _margin(18, 14, 18, 14)
	wrap.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(42.0, 42.0)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_rect)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(120.0, 0.0)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	text_box.add_child(_label(title, 20, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT))

	var value_label: Label = _label("", 14, COL_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	text_box.add_child(value_label)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.custom_minimum_size = Vector2(220.0, 36.0)
	var initial_volume: float = music_volume if is_music else sfx_volume
	slider.value = initial_volume * 100.0
	row.add_child(slider)
	value_label.text = "%d%%" % int(slider.value)

	var toggle: CheckButton = CheckButton.new()
	var initial_enabled: bool = music_enabled if is_music else sfx_enabled
	toggle.text = "Вкл" if initial_enabled else "Выкл"
	toggle.button_pressed = initial_enabled
	toggle.custom_minimum_size = Vector2(90.0, 44.0)
	_apply_control_font(toggle, 16, COL_TEXT)
	row.add_child(toggle)

	slider.value_changed.connect(_on_volume_changed.bind(is_music, value_label))
	toggle.toggled.connect(_on_toggle_changed.bind(is_music, toggle))
	return wrap


func _on_volume_changed(value: float, is_music: bool, value_label: Label) -> void:
	if is_music:
		music_volume = value / 100.0
	else:
		sfx_volume = value / 100.0
	value_label.text = "%d%%" % int(value)
	_apply_audio_everywhere()
	_save_local_state()


func _on_toggle_changed(enabled: bool, is_music: bool, toggle: CheckButton) -> void:
	if is_music:
		music_enabled = enabled
	else:
		sfx_enabled = enabled
	toggle.text = "Вкл" if enabled else "Выкл"
	_apply_audio_everywhere()
	_save_local_state()


func _close_settings_modal() -> void:
	var return_to_game: bool = current_screen == "game"
	_clear_modal()
	if return_to_game:
		_show_pause_modal()


func _resume_game() -> void:
	_clear_modal()
	_pause_game(false)


func _restart_game() -> void:
	_clear_modal()
	result_seen = false
	if game == null or not is_instance_valid(game):
		_start_game()
		return
	game.call("_reset_game")
	_sync_game_audio()


func _pause_game(value: bool) -> void:
	if game == null or not is_instance_valid(game):
		return
	game.set("manual_paused", value)
	if not value:
		game.set("focus_paused", false)
	if game.has_method("_sync_audio_pause"):
		game.call("_sync_audio_pause")
	game.queue_redraw()


func _on_play_pressed() -> void:
	_ui_click()
	_start_game()


func _on_levels_pressed() -> void:
	_ui_click()
	_show_level_select()


func _on_menu_pressed() -> void:
	_ui_click()
	_show_main_menu()


func _on_pause_pressed() -> void:
	_ui_click()
	_show_pause_modal()


func _on_resume_pressed() -> void:
	_ui_click()
	_resume_game()


func _on_restart_pressed() -> void:
	_ui_click()
	_restart_game()


func _on_menu_settings_pressed() -> void:
	_ui_click()
	_show_settings_modal(false)


func _on_game_settings_pressed() -> void:
	_ui_click()
	_show_settings_modal(true)


func _on_settings_done_pressed() -> void:
	_ui_click()
	_close_settings_modal()


func _dispose_game() -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
	game = null


func _clear_modal() -> void:
	current_modal = ""
	_clear_layer(modal_layer)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _modal_panel(panel_size: Vector2) -> PanelContainer:
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.002, 0.01, 0.025, 0.76)
	_full_rect(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(shade)

	var panel: PanelContainer = _panel(panel_size, Color(0.014, 0.05, 0.105, 0.99), true)
	_center_control(panel)
	modal_layer.add_child(panel)
	return panel


func _modal_column(panel: PanelContainer) -> VBoxContainer:
	var margin: MarginContainer = _margin(48, 34, 48, 34)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	return column


func _stat_card(label_text: String, value_text: String, icon: Texture2D) -> Control:
	var panel: PanelContainer = _panel(Vector2(160.0, 86.0), COL_PANEL_SOFT)
	panel.custom_minimum_size = Vector2(160.0, 86.0)
	var margin: MarginContainer = _margin(12, 10, 12, 10)
	panel.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var image: TextureRect = TextureRect.new()
	image.texture = icon
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(34.0, 34.0)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(image)

	var column: VBoxContainer = VBoxContainer.new()
	row.add_child(column)
	column.add_child(_label(label_text, 13, COL_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	column.add_child(_label(value_text, 20, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	return panel


func _level_card(number: int, title: String, subtitle: String, unlocked: bool) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(380.0, 210.0)
	button.text = "%02d\n%s\n%s" % [number, title, subtitle]
	button.icon = ICON_CHAPTER if unlocked else ICON_LOCK
	button.icon_max_width = 54
	button.expand_icon = true
	button.disabled = not unlocked
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_control_font(button, 23, COL_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.61, 0.72, 0.78))
	button.add_theme_stylebox_override("normal", _style_box(Color(0.018, 0.065, 0.125, 0.94), COL_BORDER, 12, true))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.03, 0.11, 0.20, 0.98), Color(0.28, 0.67, 1.0, 0.9), 12, true))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.025, 0.085, 0.16, 1.0), COL_PRIMARY, 12, false))
	button.add_theme_stylebox_override("disabled", _style_box(Color(0.018, 0.045, 0.085, 0.84), Color(0.12, 0.22, 0.35, 0.6), 12, false))
	return button


func _floating_icon_button(icon: Texture2D) -> Button:
	var button: Button = Button.new()
	button.icon = icon
	button.expand_icon = true
	button.icon_max_width = 30
	button.size = Vector2(58.0, 58.0)
	button.custom_minimum_size = Vector2(58.0, 58.0)
	button.add_theme_stylebox_override("normal", _style_box(Color(0.015, 0.055, 0.115, 0.96), Color(0.13, 0.43, 0.78, 0.82), 10, true))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.035, 0.11, 0.20, 0.98), Color(0.34, 0.73, 1.0, 0.95), 10, true))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.02, 0.075, 0.14, 1.0), COL_PRIMARY, 10, false))
	return button


func _icon_button(icon: Texture2D, tooltip: String) -> Button:
	var button: Button = _floating_icon_button(icon)
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(54.0, 54.0)
	button.size = Vector2(54.0, 54.0)
	return button


func _button(text: String, variant: String, icon: Texture2D = null, height: float = 60.0) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, height)
	button.focus_mode = Control.FOCUS_ALL
	button.icon = icon
	button.icon_max_width = 26
	button.expand_icon = true
	button.add_theme_constant_override("h_separation", 14)
	_apply_control_font(button, 20, COL_TEXT)

	if variant == "primary":
		button.add_theme_stylebox_override("normal", _style_box(COL_PRIMARY, Color(0.52, 0.80, 1.0, 0.78), 10, true))
		button.add_theme_stylebox_override("hover", _style_box(COL_PRIMARY_HOVER, Color(0.72, 0.90, 1.0, 0.95), 10, true))
		button.add_theme_stylebox_override("pressed", _style_box(COL_PRIMARY_PRESS, Color(0.35, 0.65, 0.95, 0.9), 10, false))
	elif variant == "ghost":
		button.add_theme_stylebox_override("normal", _style_box(Color(0.015, 0.045, 0.085, 0.40), Color(0.14, 0.25, 0.38, 0.65), 10, false))
		button.add_theme_stylebox_override("hover", _style_box(Color(0.03, 0.08, 0.14, 0.82), Color(0.20, 0.48, 0.75, 0.75), 10, false))
		button.add_theme_stylebox_override("pressed", _style_box(Color(0.02, 0.06, 0.11, 0.95), COL_BORDER, 10, false))
	else:
		button.add_theme_stylebox_override("normal", _style_box(Color(0.025, 0.09, 0.17, 0.96), COL_BORDER, 10, false))
		button.add_theme_stylebox_override("hover", _style_box(Color(0.04, 0.13, 0.23, 0.98), Color(0.28, 0.66, 1.0, 0.88), 10, false))
		button.add_theme_stylebox_override("pressed", _style_box(Color(0.025, 0.075, 0.14, 1.0), COL_PRIMARY, 10, false))

	button.add_theme_stylebox_override("focus", _style_box(Color(0.0, 0.0, 0.0, 0.0), Color(0.55, 0.82, 1.0, 0.9), 10, false))
	return button


func _panel(panel_size: Vector2, color: Color, shadow: bool = false) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	if panel_size.x > 0.0 or panel_size.y > 0.0:
		panel.custom_minimum_size = panel_size
	panel.add_theme_stylebox_override("panel", _style_box(color, COL_BORDER, 12, shadow))
	return panel


func _style_box(fill: Color, border: Color, radius: int, shadow: bool) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	if shadow:
		box.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
		box.shadow_size = 10
		box.shadow_offset = Vector2(0.0, 5.0)
	return box


func _label(text: String, size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", game_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _apply_control_font(control: Control, size: int, color: Color) -> void:
	control.add_theme_font_override("font", game_font)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _modal_spacer(height: float) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	return spacer


func _add_background(parent: Control, darkness: float) -> void:
	var texture: TextureRect = TextureRect.new()
	texture.texture = BACKGROUND
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


func _center_control(control: Control, offset: Vector2 = Vector2.ZERO) -> void:
	var size: Vector2 = control.custom_minimum_size
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = -size.x * 0.5 + offset.x
	control.offset_top = -size.y * 0.5 + offset.y
	control.offset_right = size.x * 0.5 + offset.x
	control.offset_bottom = size.y * 0.5 + offset.y


func _full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _clear_layer(layer: Control) -> void:
	for child in layer.get_children():
		child.queue_free()


func _animate_in(control: Control) -> void:
	control.modulate.a = 0.0
	control.scale = Vector2(0.97, 0.97)
	control.pivot_offset = control.custom_minimum_size * 0.5
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ui_click() -> void:
	_unlock_app_audio()
	if app_audio != null:
		app_audio.play_sfx("ui_click")


func _unlock_app_audio() -> void:
	if app_audio == null:
		return
	app_audio.unlock_audio()
	if current_screen != "game":
		app_audio.start_music()


func _apply_audio_state(service: Node) -> void:
	if service == null:
		return
	service.set_music_enabled(music_enabled)
	service.set_sfx_enabled(sfx_enabled)
	service.set_music_volume(music_volume)
	service.set_sfx_volume(sfx_volume)


func _apply_audio_everywhere() -> void:
	_apply_audio_state(app_audio)
	_sync_game_audio()


func _sync_game_audio() -> void:
	if game == null or not is_instance_valid(game):
		return
	var service: Variant = game.get("audio_service")
	if service == null:
		return
	_apply_audio_state(service)
	service.unlock_audio()
	service.start_music()


func _store_victory_stats() -> void:
	if game == null or not is_instance_valid(game):
		return
	level_one_complete = true
	var score_value: int = int(game.get("score"))
	var time_value: float = float(game.get("elapsed"))
	best_score = maxi(best_score, score_value)
	if best_time <= 0.0 or time_value < best_time:
		best_time = time_value
	_save_local_state()


func _load_local_state() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_enabled = bool(config.get_value("audio", "music_enabled", true))
	sfx_enabled = bool(config.get_value("audio", "sfx_enabled", true))
	music_volume = float(config.get_value("audio", "music_volume", 0.72))
	sfx_volume = float(config.get_value("audio", "sfx_volume", 0.86))
	level_one_complete = bool(config.get_value("progress", "level_one_complete", false))
	best_score = int(config.get_value("progress", "best_score", 0))
	best_time = float(config.get_value("progress", "best_time", 0.0))


func _save_local_state() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("progress", "level_one_complete", level_one_complete)
	config.set_value("progress", "best_score", best_score)
	config.set_value("progress", "best_time", best_time)
	config.save(SETTINGS_PATH)


func _format_time(seconds_value: float) -> String:
	var total: int = maxi(0, int(seconds_value))
	var minutes: int = total / 60
	var seconds: int = total % 60
	return "%02d:%02d" % [minutes, seconds]
