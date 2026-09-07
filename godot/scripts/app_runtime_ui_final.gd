extends "res://scripts/app_runtime_ui.gd"

# Final production composition pass for menu, maps and settings.
# Keeps gameplay/modals from app_runtime_ui.gd and composes delivered assets
# according to the designer safe-area and scaling notes.

const FINAL_LEVEL_CATALOG = preload("res://scripts/level_catalog.gd")

const FINAL_HEADER_LONG: Texture2D = preload("res://assets/ui/panels/panel_header_long.webp")
const FINAL_WORLD_NODE_COMPLETE: Texture2D = preload("res://assets/ui/world_map/location_node_complete.webp")
const FINAL_WORLD_NODE_CURRENT: Texture2D = preload("res://assets/ui/world_map/location_node_current.webp")
const FINAL_WORLD_NODE_LOCKED: Texture2D = preload("res://assets/ui/world_map/location_node_locked.png")
const FINAL_WORLD_NODE_OPEN: Texture2D = preload("res://assets/ui/world_map/location_node_open.webp")
const FINAL_WORLD_LABEL: Texture2D = preload("res://assets/ui/world_map/location_label_plate.png")
const FINAL_WORLD_PROGRESS: Texture2D = preload("res://assets/ui/world_map/location_progress_plate.png")
const FINAL_WORLD_PATH_SEGMENT: Texture2D = preload("res://assets/ui/world_map/path_segment.png")
const FINAL_WORLD_PATH_DOT: Texture2D = preload("res://assets/ui/world_map/path_dot.png")
const FINAL_WORLD_PATH_GLOW: Texture2D = preload("res://assets/ui/world_map/path_glow.png")

const FINAL_LEVEL_NODE_COMPLETE: Texture2D = preload("res://assets/ui/level_map/level_node_complete.png")
const FINAL_LEVEL_NODE_CURRENT: Texture2D = preload("res://assets/ui/level_map/level_node_current.png")
const FINAL_LEVEL_NODE_LOCKED: Texture2D = preload("res://assets/ui/level_map/level_node_locked.png")
const FINAL_LEVEL_NODE_OPEN: Texture2D = preload("res://assets/ui/level_map/level_node_open.png")
const FINAL_LEVEL_PATH_SEGMENT: Texture2D = preload("res://assets/ui/level_map/level_path_segment.png")
const FINAL_LEVEL_PATH_DOT: Texture2D = preload("res://assets/ui/level_map/level_path_dot.png")

const FINAL_ICON_RESET: Texture2D = preload("res://assets/ui/icons/icon_reset.svg")


func _show_main_menu() -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "menu"
	result_seen = false
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_background(screen_layer, 0.10)

	# One deliberate decorative cluster on each side; the centre is reserved for UI.
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(-35.0, -12.0, 430.0, 155.0), 0.72)
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(1205.0, -12.0, 430.0, 155.0), 0.72, true)

	var owl: TextureRect = _add_texture(screen_layer, OWL_IDLE, Rect2(38.0, 475.0, 360.0, 360.0), 1.0)
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_add_texture(screen_layer, UI_DECOR_BOOKS, Rect2(1285.0, 650.0, 245.0, 185.0), 0.94)
	_add_texture(screen_layer, UI_DECOR_LANTERN, Rect2(1390.0, 570.0, 150.0, 215.0), 0.96)
	_add_texture(screen_layer, UI_DECOR_CRYSTALS, Rect2(1140.0, 720.0, 165.0, 120.0), 0.78)

	# Main visual axis: logo -> primary CTA -> two secondary actions.
	var logo: TextureRect = _add_texture(screen_layer, UI_LOGO, Rect2(475.0, 72.0, 650.0, 290.0), 1.0)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var play_button: Button = _button("Играть", "primary", null, 118.0)
	play_button.position = Vector2(500.0, 390.0)
	play_button.size = Vector2(600.0, 118.0)
	play_button.pressed.connect(_on_play_pressed)
	screen_layer.add_child(play_button)

	var map_button: Button = _button("Карта мира", "menu_secondary", null, 92.0)
	map_button.position = Vector2(555.0, 535.0)
	map_button.size = Vector2(490.0, 92.0)
	map_button.pressed.connect(_on_levels_pressed)
	screen_layer.add_child(map_button)

	var settings_button: Button = _button("Настройки", "menu_secondary", null, 92.0)
	settings_button.position = Vector2(555.0, 650.0)
	settings_button.size = Vector2(490.0, 92.0)
	settings_button.pressed.connect(_on_menu_settings_pressed)
	screen_layer.add_child(settings_button)

	_animate_in(logo)
	_animate_in(play_button)


func _show_settings_modal(from_game: bool) -> void:
	_clear_modal()
	current_modal = "settings"
	if from_game and game != null and is_instance_valid(game):
		game.set("settings_open", false)
		_pause_game(true)

	var panel: PanelContainer = _modal_panel(Vector2(650.0, 690.0))
	var column: VBoxContainer = _modal_column(panel)
	column.add_child(_label("Звук", 48, UI_PARCHMENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(8.0))
	column.add_child(_settings_row("Музыка", ICON_MUSIC_ON, true))
	column.add_child(_settings_row("Звуки", ICON_SOUND_ON, false))
	column.add_child(_modal_spacer(14.0))

	var back_button: Button = _button("Назад", "secondary", null, 88.0)
	back_button.pressed.connect(_on_settings_done_pressed)
	column.add_child(back_button)

	var reset_button: Button = _button("Сбросить прогресс", "menu_secondary", null, 76.0)
	reset_button.add_theme_color_override("font_color", Color("f2d7d1"))
	reset_button.add_theme_color_override("font_hover_color", Color("fff1ed"))
	reset_button.tooltip_text = "Начать прохождение заново"
	reset_button.pressed.connect(_on_reset_progress_final)
	column.add_child(reset_button)

	_animate_in(panel)
	call_deferred("_center_modal_panel_exact", panel)


func _on_reset_progress_final() -> void:
	_ui_click()
	_reset_progress_data()
	_save_local_state()
	_clear_modal()
	_show_main_menu()


func _show_level_select() -> void:
	_stop_platform_gameplay_final()
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "locations"
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_background(screen_layer, 0.34)
	_add_map_canvas(Rect2(72.0, 154.0, 1456.0, 646.0))
	_add_world_header()

	var points: Array[Vector2] = [
		Vector2(220.0, 610.0), Vector2(455.0, 455.0), Vector2(705.0, 585.0),
		Vector2(955.0, 415.0), Vector2(1210.0, 565.0), Vector2(1370.0, 325.0)
	]
	_add_textured_route(points, FINAL_WORLD_PATH_SEGMENT, FINAL_WORLD_PATH_DOT, 18.0)

	for i in range(FINAL_LEVEL_CATALOG.LOCATION_ORDER.size()):
		var location_id: String = FINAL_LEVEL_CATALOG.LOCATION_ORDER[i]
		_add_world_node_final(
			location_id,
			i + 1,
			FINAL_LEVEL_CATALOG.location_title(location_id),
			points[i],
			_is_location_unlocked(location_id),
			_completed_for_location(location_id)
		)


func _show_location_levels(location_id: String) -> void:
	_stop_platform_gameplay_final()
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "location_levels"
	current_level_id = location_id
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_location_background(screen_layer, location_id, 0.32)
	_add_map_canvas(Rect2(72.0, 154.0, 1456.0, 646.0))
	_add_level_header(location_id)

	var points: Array[Vector2] = [
		Vector2(205.0, 645.0), Vector2(430.0, 645.0), Vector2(655.0, 645.0),
		Vector2(880.0, 645.0), Vector2(1105.0, 645.0), Vector2(1340.0, 525.0),
		Vector2(1110.0, 370.0), Vector2(875.0, 370.0), Vector2(640.0, 370.0), Vector2(405.0, 255.0)
	]
	_add_textured_route(points, FINAL_LEVEL_PATH_SEGMENT, FINAL_LEVEL_PATH_DOT, 14.0)

	var completed: int = _completed_for_location(location_id)
	for i in range(10):
		var level_number: int = i + 1
		var done: bool = level_number <= completed
		var unlocked: bool = level_number <= mini(10, completed + 1) or completed >= 10
		_add_level_node_final(location_id, level_number, points[i], unlocked, done)


func _add_world_header() -> void:
	var menu_button: Button = _button("Меню", "menu_secondary", null, 88.0)
	menu_button.position = Vector2(82.0, 32.0)
	menu_button.size = Vector2(240.0, 88.0)
	menu_button.pressed.connect(_on_menu_pressed)
	screen_layer.add_child(menu_button)

	# Preserve the source 800×180 aspect ratio; stretching it flatter distorts the centre ornament.
	_add_texture(screen_layer, FINAL_HEADER_LONG, Rect2(490.0, 18.0, 620.0, 140.0), 1.0)
	var title: Label = _label("Карта мира", 32, UI_PARCHMENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(585.0, 60.0)
	title.size = Vector2(430.0, 48.0)
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
	heading.position = Vector2(575.0, 60.0)
	heading.size = Vector2(450.0, 48.0)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(heading)


func _add_map_canvas(rect: Rect2) -> void:
	var canvas: PanelContainer = PanelContainer.new()
	canvas.position = rect.position
	canvas.size = rect.size
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.025, 0.065, 0.58)
	style.border_color = Color(0.43, 0.30, 0.12, 0.72)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	canvas.add_theme_stylebox_override("panel", style)
	screen_layer.add_child(canvas)
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(68.0, 138.0, 330.0, 115.0), 0.34)
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(1202.0, 138.0, 330.0, 115.0), 0.34, true)
	_add_texture(screen_layer, UI_DECOR_CRYSTALS, Rect2(1310.0, 690.0, 150.0, 105.0), 0.28)


func _add_world_node_final(location_id: String, number: int, title: String, center: Vector2, unlocked: bool, completed: int) -> void:
	var texture: Texture2D = FINAL_WORLD_NODE_LOCKED
	if completed >= 10:
		texture = FINAL_WORLD_NODE_COMPLETE
	elif unlocked:
		texture = FINAL_WORLD_NODE_CURRENT

	if unlocked and completed < 10:
		_add_texture(screen_layer, FINAL_WORLD_PATH_GLOW, Rect2(center.x - 92.0, center.y - 92.0, 184.0, 184.0), 0.62)
	_add_dark_disc(center, 136.0)

	var button: TextureButton = TextureButton.new()
	button.texture_normal = texture
	button.texture_hover = FINAL_WORLD_NODE_OPEN if unlocked else texture
	button.texture_pressed = FINAL_WORLD_NODE_CURRENT
	button.texture_disabled = FINAL_WORLD_NODE_LOCKED
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = center - Vector2(76.0, 76.0)
	button.size = Vector2(152.0, 152.0)
	button.disabled = not unlocked
	if unlocked:
		button.pressed.connect(Callable(self, "_on_location_selected").bind(location_id))
	screen_layer.add_child(button)

	var chapter_icon: TextureRect = _add_texture(screen_layer, _icon_for_location(location_id) if unlocked else ICON_LOCK, Rect2(center.x - 31.0, center.y - 35.0, 62.0, 62.0), 1.0 if unlocked else 0.72)
	chapter_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_add_texture(screen_layer, FINAL_WORLD_LABEL, Rect2(center.x - 112.0, center.y + 71.0, 224.0, 54.0), 1.0)
	var label: Label = _label("%02d · %s" % [number, title], 18, Color("fff4d7") if unlocked else Color("a8afba"), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(center.x - 102.0, center.y + 83.0)
	label.size = Vector2(204.0, 28.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(label)

	_add_texture(screen_layer, FINAL_WORLD_PROGRESS, Rect2(center.x - 70.0, center.y + 119.0, 140.0, 40.0), 1.0)
	var progress: Label = _label("%d / 10" % completed, 15, Color("9cf0a7") if completed >= 10 else Color("fff2d1"), HORIZONTAL_ALIGNMENT_CENTER)
	progress.position = Vector2(center.x - 62.0, center.y + 128.0)
	progress.size = Vector2(124.0, 24.0)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(progress)


func _add_level_node_final(location_id: String, level_number: int, center: Vector2, unlocked: bool, done: bool) -> void:
	var texture: Texture2D = FINAL_LEVEL_NODE_LOCKED
	if done:
		texture = FINAL_LEVEL_NODE_COMPLETE
	elif unlocked:
		texture = FINAL_LEVEL_NODE_CURRENT
	_add_dark_disc(center, 100.0)

	var button: TextureButton = TextureButton.new()
	button.texture_normal = texture
	button.texture_hover = FINAL_LEVEL_NODE_OPEN if unlocked else texture
	button.texture_pressed = FINAL_LEVEL_NODE_CURRENT
	button.texture_disabled = FINAL_LEVEL_NODE_LOCKED
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.position = center - Vector2(57.0, 57.0)
	button.size = Vector2(114.0, 114.0)
	button.disabled = not unlocked
	if unlocked:
		button.pressed.connect(Callable(self, "_on_level_node_pressed").bind(location_id, level_number))
	screen_layer.add_child(button)

	var number_label: Label = _label(str(level_number), 28, Color("fff4d1") if unlocked else Color("8e98a8"), HORIZONTAL_ALIGNMENT_CENTER)
	number_label.position = center - Vector2(31.0, 22.0)
	number_label.size = Vector2(62.0, 44.0)
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(number_label)

	var title_panel: PanelContainer = PanelContainer.new()
	title_panel.position = Vector2(center.x - 92.0, center.y + 60.0)
	title_panel.size = Vector2(184.0, 38.0)
	title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_style: StyleBoxFlat = StyleBoxFlat.new()
	title_style.bg_color = Color(0.015, 0.045, 0.09, 0.90)
	title_style.border_color = Color(0.55, 0.37, 0.14, 0.82)
	title_style.border_width_left = 1
	title_style.border_width_top = 1
	title_style.border_width_right = 1
	title_style.border_width_bottom = 1
	title_style.corner_radius_top_left = 10
	title_style.corner_radius_top_right = 10
	title_style.corner_radius_bottom_left = 10
	title_style.corner_radius_bottom_right = 10
	title_panel.add_theme_stylebox_override("panel", title_style)
	screen_layer.add_child(title_panel)

	var title: Label = _label(FINAL_LEVEL_CATALOG.level_title(location_id, level_number), 14, Color("eef3fb") if unlocked else Color("8f9aaa"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(center.x - 86.0, center.y + 67.0)
	title.size = Vector2(172.0, 24.0)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(title)


func _add_dark_disc(center: Vector2, diameter: float) -> void:
	var disc: PanelContainer = PanelContainer.new()
	disc.position = center - Vector2(diameter * 0.5, diameter * 0.5)
	disc.size = Vector2(diameter, diameter)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.004, 0.025, 0.07, 0.88)
	style.border_color = Color(0.12, 0.27, 0.42, 0.58)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	var radius: int = int(diameter * 0.5)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	disc.add_theme_stylebox_override("panel", style)
	screen_layer.add_child(disc)


func _add_textured_route(points: Array[Vector2], segment_texture: Texture2D, dot_texture: Texture2D, height: float) -> void:
	if points.size() < 2:
		return
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
		segment.position = start
		segment.size = Vector2(length, height)
		segment.pivot_offset = Vector2(0.0, height * 0.5)
		segment.rotation = delta.angle()
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen_layer.add_child(segment)
		for step in [0.25, 0.5, 0.75]:
			var p: Vector2 = start.lerp(finish, step)
			_add_texture(screen_layer, dot_texture, Rect2(p.x - 7.0, p.y - 7.0, 14.0, 14.0), 0.82)


func _stop_platform_gameplay_final() -> void:
	var service: Node = get_node_or_null("/root/YandexGames")
	if service != null and service.has_method("gameplay_stop"):
		service.call("gameplay_stop")
