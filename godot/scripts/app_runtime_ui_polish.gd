extends "res://scripts/app_runtime_ui_final.gd"

# Final visual polish for the approved menu/map composition.
# Release runtime contains no debug level-cycling shortcuts.


func _show_main_menu() -> void:
	_stop_platform_gameplay_final()
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "menu"
	result_seen = false
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_background(screen_layer, 0.08)

	# Keep the menu independent from location-specific foreground scenery.
	var owl: TextureRect = _add_texture(screen_layer, OWL_IDLE, Rect2(38.0, 475.0, 360.0, 360.0), 1.0)
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# The logo is the main visual anchor and should dominate the upper half.
	var logo: TextureRect = _add_texture(screen_layer, UI_LOGO, Rect2(405.0, 28.0, 790.0, 350.0), 1.0)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var play_button: Button = _button("Играть", "primary", null, 120.0)
	play_button.position = Vector2(490.0, 390.0)
	play_button.size = Vector2(620.0, 120.0)
	play_button.pressed.connect(_on_play_pressed)
	screen_layer.add_child(play_button)

	var map_button: Button = _button("Карта мира", "menu_secondary", null, 94.0)
	map_button.position = Vector2(545.0, 535.0)
	map_button.size = Vector2(510.0, 94.0)
	map_button.pressed.connect(_on_levels_pressed)
	screen_layer.add_child(map_button)

	var settings_button: Button = _button("Настройки", "menu_secondary", null, 94.0)
	settings_button.position = Vector2(545.0, 650.0)
	settings_button.size = Vector2(510.0, 94.0)
	settings_button.pressed.connect(_on_menu_settings_pressed)
	screen_layer.add_child(settings_button)

	_animate_in(logo)
	_animate_in(play_button)


func _show_settings_modal(from_game: bool) -> void:
	if from_game:
		_stop_platform_gameplay_final()
	super._show_settings_modal(from_game)


func _add_world_header() -> void:
	var menu_button: Button = _button("Меню", "menu_secondary", null, 88.0)
	menu_button.position = Vector2(82.0, 32.0)
	menu_button.size = Vector2(240.0, 88.0)
	menu_button.pressed.connect(_on_menu_pressed)
	screen_layer.add_child(menu_button)

	_add_texture(screen_layer, FINAL_HEADER_LONG, Rect2(490.0, 18.0, 620.0, 140.0), 1.0)
	var title: Label = _label("Карта мира", 32, UI_PARCHMENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(575.0, 44.0)
	title.size = Vector2(450.0, 64.0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(title)


func _add_level_header(location_id: String) -> void:
	var back_button: Button = _button("К карте мира", "menu_secondary", null, 88.0)
	back_button.position = Vector2(82.0, 32.0)
	back_button.size = Vector2(285.0, 88.0)
	back_button.pressed.connect(_show_level_select)
	screen_layer.add_child(back_button)

	_add_texture(screen_layer, FINAL_HEADER_LONG, Rect2(490.0, 18.0, 620.0, 140.0), 1.0)
	var heading: Label = _label("%s · уровни" % FINAL_LEVEL_CATALOG.location_title(location_id), 30, UI_PARCHMENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	heading.position = Vector2(565.0, 44.0)
	heading.size = Vector2(470.0, 64.0)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(heading)
