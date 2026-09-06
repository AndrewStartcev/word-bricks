extends "res://scripts/app_runtime_ui.gd"

# Final production composition pass for maps and settings.
# Keeps the already approved menu/gameplay/modals from app_runtime_ui.gd.

const FINAL_LEVEL_CATALOG = preload("res://scripts/level_catalog.gd")

const FINAL_HEADER_LONG: Texture2D = preload("res://assets/ui/panels/panel_header_long.png")
const FINAL_HEADER_MEDIUM: Texture2D = preload("res://assets/ui/panels/panel_header_medium.png")
const FINAL_HEADER_SMALL: Texture2D = preload("res://assets/ui/panels/panel_header_small.png")

const FINAL_WORLD_NODE_COMPLETE: Texture2D = preload("res://assets/ui/world_map/location_node_complete.png")
const FINAL_WORLD_NODE_CURRENT: Texture2D = preload("res://assets/ui/world_map/location_node_current.png")
const FINAL_WORLD_NODE_LOCKED: Texture2D = preload("res://assets/ui/world_map/location_node_locked.png")
const FINAL_WORLD_NODE_OPEN: Texture2D = preload("res://assets/ui/world_map/location_node_open.png")
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

const FINAL_ICON_BACK: Texture2D = preload("res://assets/ui/icons/icon_back.svg")
const FINAL_ICON_RESET: Texture2D = preload("res://assets/ui/icons/icon_reset.svg")
const FINAL_WOOD_SIGN: Texture2D = preload("res://assets/ui/decor/decor_wood_sign.png")


func _show_main_menu() -> void:
	super._show_main_menu()
	# The wooden board is not a free-standing menu decoration. It is reserved for
	# labelled transition/navigation use, so remove the tiny empty board from menu.
	for child in screen_layer.get_children():
		if child is TextureRect and (child as TextureRect).texture == FINAL_WOOD_SIGN:
			child.queue_free()


func _show_settings_modal(from_game: bool) -> void:
	super._show_settings_modal(from_game)
	if current_modal != "settings":
		return
	var reset_button: Button = _find_button_exact(modal_layer, "Сбросить прогресс")
	if reset_button != null:
		reset_button.visible = true
		reset_button.custom_minimum_size.y = 76.0
		reset_button.icon = FINAL_ICON_RESET
		_apply_control_font(reset_button, 21, Color("f6e7d0"))
	var panel: PanelContainer = _active_modal_panel()
	if panel != null:
		panel.custom_minimum_size = Vector2(650.0, 690.0)
		call_deferred("_center_modal_panel_exact", panel)


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
		Vector2(220.0, 620.0),
		Vector2(455.0, 475.0),
		Vector2(705.0, 600.0),
		Vector2(955.0, 435.0),
		Vector2(1210.0, 590.0),
		Vector2(1370.0, 345.0)
	]
	_add_textured_route(points, FINAL_WORLD_PATH_SEGMENT, FINAL_WORLD_PATH_DOT, 18.0)

	for i in range(FINAL_LEVEL_CATALOG.LOCATION_ORDER.size()):
		var location_id: String = FINAL_LEVEL_CATALOG.LOCATION_ORDER[i]
		var completed: int = _completed_for_location(location_id)
		var unlocked: bool = _is_location_unlocked(location_id)
		_add_world_node_final(location_id, i + 1, FINAL_LEVEL_CATALOG.location_title(location_id), points[i], unlocked, completed)

	var hint_scroll: TextureRect = _add_texture(screen_layer, UI_DECOR_SCROLL_LARGE, Rect2(470.0, 758.0, 660.0, 92.0), 0.92)
	hint_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint: Label = _label("Возвращай слова — и путь будет открываться дальше", 18, UI_PARCHMENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(535.0, 783.0)
	hint.size = Vector2(530.0, 34.0)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(hint)


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
	_add_map_canvas(Rect2(72.0, 150.0, 1456.0, 650.0))
	_add_level_header(location_id)

	var points: Array[Vector2] = [
		Vector2(205.0, 650.0), Vector2(430.0, 650.0), Vector2(655.0, 650.0),
		Vector2(880.0, 650.0), Vector2(1105.0, 650.0), Vector2(1340.0, 535.0),
		Vector2(1110.0, 380.0), Vector2(875.0, 380.0), Vector2(640.0, 380.0), Vector2(405.0, 265.0)
	]
	_add_textured_route(points, FINAL_LEVEL_PATH_SEGMENT, FINAL_LEVEL_PATH_DOT, 14.0)

	var completed: int = _completed_for_location(location_id)
	for i in range(10):
		var level_number: int = i + 1
		var done: bool = level_number <= completed
		var unlocked: bool = level_number <= mini(10, completed + 1) or completed >= 10
		_add_level_node_final(location_id, level_number, points[i], unlocked, done)

	var back_button: Button = _button("К карте мира", "menu_secondary", FINAL_ICON_BACK, 76.0)
	back_button.position = Vector2(640.0, 804.0)
	back_button.size = Vector2(320.0, 76.0)
	back_button.pressed.connect(_show_level_select)
	screen_layer.add_child(back_button)


func _add_world_header() -> void:
	_add_texture(screen_layer, FINAL_HEADER_LONG, Rect2(88.0, 36.0, 1424.0, 105.0), 1.0)
	var home: Button = _icon_button(ICON_HOME, "В меню")
	home.position = Vector2(116.0, 55.0)
	home.size = Vector2(66.0, 66.0)
	home.pressed.connect(_on_menu_pressed)
	screen_layer.add_child(home)
	var title: Label = _label("Карта мира", 34, Color("fff7df"), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(205.0, 59.0)
	title.size = Vector2(520.0, 56.0)
	screen_layer.add_child(title)
	var progress: Label = _label("%d / 60 уровней" % _total_completed_levels(), 19, Color("d8e2f4"), HORIZONTAL_ALIGNMENT_RIGHT)
	progress.position = Vector2(1210.0, 67.0)
	progress.size = Vector2(230.0, 42.0)
	screen_layer.add_child(progress)


func _add_level_header(location_id: String) -> void:
	_add_texture(screen_layer, FINAL_HEADER_LONG, Rect2(88.0, 36.0, 1424.0, 105.0), 1.0)
	var icon_back: Button = _icon_button(FINAL_ICON_BACK, "К карте мира")
	icon_back.position = Vector2(116.0, 55.0)
	icon_back.size = Vector2(66.0, 66.0)
	icon_back.pressed.connect(_show_level_select)
	screen_layer.add_child(icon_back)
	var chapter_icon: TextureRect = _add_texture(screen_layer, _icon_for_location(location_id), Rect2(202.0, 58.0, 50.0, 50.0), 1.0)
	chapter_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var heading: Label = _label("%s · карта уровней" % FINAL_LEVEL_CATALOG.location_title(location_id), 31, Color("fff7df"), HORIZONTAL_ALIGNMENT_LEFT)
	heading.position = Vector2(267.0, 59.0)
	heading.size = Vector2(720.0, 55.0)
	screen_layer.add_child(heading)
	var progress: Label = _label("%d / 10" % _completed_for_location(location_id), 20, Color("d8e2f4"), HORIZONTAL_ALIGNMENT_RIGHT)
	progress.position = Vector2(1300.0, 66.0)
	progress.size = Vector2(140.0, 42.0)
	screen_layer.add_child(progress)


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
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(68.0, 138.0, 330.0, 115.0), 0.42)
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(1202.0, 138.0, 330.0, 115.0), 0.42, true)
	_add_texture(screen_layer, UI_DECOR_CRYSTALS, Rect2(1310.0, 690.0, 150.0, 105.0), 0.34)


func _add_world_node_final(location_id: String, number: int, title: String, center: Vector2, unlocked: bool, completed: int) -> void:
	var texture: Texture2D = FINAL_WORLD_NODE_LOCKED
	if completed >= 10:
		texture = FINAL_WORLD_NODE_COMPLETE
	elif unlocked:
		texture = FINAL_WORLD_NODE_CURRENT

	if unlocked and completed < 10:
		_add_texture(screen_layer, FINAL_WORLD_PATH_GLOW, Rect2(center.x - 92.0, center.y - 92.0, 184.0, 184.0), 0.66)
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
	title_style.bg_color = Color(0.015, 0.045, 0.09, 0.88)
	title_style.border_color = Color(0.55, 0.37, 0.14, 0.78)
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


func _find_button_exact(node: Node, text_value: String) -> Button:
	for child in node.get_children():
		if child is Button and (child as Button).text == text_value:
			return child as Button
		var nested: Button = _find_button_exact(child, text_value)
		if nested != null:
			return nested
	return null


func _active_modal_panel() -> PanelContainer:
	for child in modal_layer.get_children():
		if child is PanelContainer:
			return child as PanelContainer
	return null


func _stop_platform_gameplay_final() -> void:
	var service: Node = get_node_or_null("/root/YandexGames")
	if service != null and service.has_method("gameplay_stop"):
		service.call("gameplay_stop")
