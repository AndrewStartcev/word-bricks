extends "res://scripts/app_runtime_yandex.gd"

# Production UI skin. This layer applies the delivered visual assets while
# keeping campaign, save and Yandex Games behaviour in the inherited runtime.

const UI_LOGO: Texture2D = preload("res://assets/ui/logo/logo_main_small.png")

const UI_BUTTON_PRIMARY_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_primary_normal.png")
const UI_BUTTON_PRIMARY_HOVER: Texture2D = preload("res://assets/ui/buttons/button_primary_hover.png")
const UI_BUTTON_PRIMARY_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_primary_pressed.png")
const UI_BUTTON_PRIMARY_DISABLED: Texture2D = preload("res://assets/ui/buttons/button_primary_disabled.png")

const UI_BUTTON_SECONDARY_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_secondary_normal.png")
const UI_BUTTON_SECONDARY_HOVER: Texture2D = preload("res://assets/ui/buttons/button_secondary_hover.png")
const UI_BUTTON_SECONDARY_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_secondary_pressed.png")
const UI_BUTTON_SECONDARY_DISABLED: Texture2D = preload("res://assets/ui/buttons/button_secondary_disabled.png")

const UI_BUTTON_SMALL_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_small_normal.png")
const UI_BUTTON_SMALL_HOVER: Texture2D = preload("res://assets/ui/buttons/button_small_hover.png")
const UI_BUTTON_SMALL_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_small_pressed.png")
const UI_BUTTON_SMALL_DISABLED: Texture2D = preload("res://assets/ui/buttons/button_small_disabled.png")

const UI_PANEL_MODAL_LARGE: Texture2D = preload("res://assets/ui/panels/panel_modal_large.png")
const UI_PANEL_MODAL_MEDIUM: Texture2D = preload("res://assets/ui/panels/panel_modal_medium.png")
const UI_PANEL_MODAL_SMALL: Texture2D = preload("res://assets/ui/panels/panel_modal_small.png")

const UI_ICON_PLAY: Texture2D = preload("res://assets/ui/icons/icon_play.svg")
const UI_ICON_WORLD_MAP: Texture2D = preload("res://assets/ui/icons/icon_world_map.svg")

const UI_PARCHMENT_TEXT: Color = Color("3b2a19")
const UI_PARCHMENT_MUTED: Color = Color("725b3d")


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

	_add_background(screen_layer, 0.16)

	var owl: TextureRect = TextureRect.new()
	owl.texture = OWL_IDLE
	owl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	owl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owl.position = Vector2(56.0, 500.0)
	owl.size = Vector2(350.0, 350.0)
	screen_layer.add_child(owl)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(650.0, 700.0)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_center_control(panel, Vector2(70.0, -10.0))
	screen_layer.add_child(panel)

	var margin: MarginContainer = _margin(28, 8, 28, 24)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var logo: TextureRect = TextureRect.new()
	logo.texture = UI_LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(600.0, 270.0)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(logo)
	column.add_child(_modal_spacer(8.0))

	var play_button: Button = _button("Играть", "primary", UI_ICON_PLAY, 112.0)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)

	var levels_button: Button = _button("Карта мира", "secondary", UI_ICON_WORLD_MAP, 98.0)
	levels_button.pressed.connect(_on_levels_pressed)
	column.add_child(levels_button)

	var settings_button: Button = _button("Настройки", "secondary", ICON_SETTINGS, 98.0)
	settings_button.pressed.connect(_on_menu_settings_pressed)
	column.add_child(settings_button)

	_animate_in(panel)


func _show_pause_modal() -> void:
	super._show_pause_modal()
	if current_modal != "pause":
		return
	_tune_modal_tree(modal_layer, "pause", false)


func _show_settings_modal(from_game: bool) -> void:
	super._show_settings_modal(from_game)
	if current_modal != "settings":
		return
	_tune_modal_tree(modal_layer, "settings", false)


func _show_result_modal(victory: bool) -> void:
	super._show_result_modal(victory)
	if current_modal != ("victory" if victory else "defeat"):
		return
	_tune_modal_tree(modal_layer, "result", victory)


func _button(text: String, variant: String, _icon: Texture2D = null, height: float = 60.0) -> Button:
	var button: Button = Button.new()
	button.text = text
	var display_height: float = maxf(height, 72.0)
	button.custom_minimum_size = Vector2(0.0, display_height)
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_control_font(button, 28 if display_height >= 96.0 else 23, Color("fff7dc"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("fff0bd"))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.64, 0.70))

	var use_small: bool = display_height <= 76.0
	var normal_tex: Texture2D
	var hover_tex: Texture2D
	var pressed_tex: Texture2D
	var disabled_tex: Texture2D
	if use_small:
		normal_tex = UI_BUTTON_SMALL_NORMAL
		hover_tex = UI_BUTTON_SMALL_HOVER
		pressed_tex = UI_BUTTON_SMALL_PRESSED
		disabled_tex = UI_BUTTON_SMALL_DISABLED
	elif variant == "primary":
		normal_tex = UI_BUTTON_PRIMARY_NORMAL
		hover_tex = UI_BUTTON_PRIMARY_HOVER
		pressed_tex = UI_BUTTON_PRIMARY_PRESSED
		disabled_tex = UI_BUTTON_PRIMARY_DISABLED
	else:
		normal_tex = UI_BUTTON_SECONDARY_NORMAL
		hover_tex = UI_BUTTON_SECONDARY_HOVER
		pressed_tex = UI_BUTTON_SECONDARY_PRESSED
		disabled_tex = UI_BUTTON_SECONDARY_DISABLED

	button.add_theme_stylebox_override("normal", _button_texture_box(normal_tex, display_height))
	button.add_theme_stylebox_override("hover", _button_texture_box(hover_tex, display_height))
	button.add_theme_stylebox_override("pressed", _button_texture_box(pressed_tex, display_height))
	button.add_theme_stylebox_override("disabled", _button_texture_box(disabled_tex, display_height))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _modal_panel(panel_size: Vector2) -> PanelContainer:
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.002, 0.008, 0.02, 0.76)
	_full_rect(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(shade)

	var texture: Texture2D = UI_PANEL_MODAL_SMALL
	if panel_size.x >= 900.0 or panel_size.y >= 720.0:
		texture = UI_PANEL_MODAL_LARGE
	elif panel_size.x >= 620.0 or panel_size.y >= 540.0:
		texture = UI_PANEL_MODAL_MEDIUM

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_texture_box(texture))
	_center_control(panel)
	modal_layer.add_child(panel)
	return panel


func _button_texture_box(texture: Texture2D, target_height: float) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = 72.0
	box.texture_margin_right = 72.0
	var vertical_slice: float = 26.0 if target_height >= 96.0 else 20.0
	box.texture_margin_top = vertical_slice
	box.texture_margin_bottom = vertical_slice
	box.content_margin_left = 30.0
	box.content_margin_right = 30.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box


func _panel_texture_box(texture: Texture2D) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = 96.0
	box.texture_margin_right = 96.0
	box.texture_margin_top = 96.0
	box.texture_margin_bottom = 96.0
	box.content_margin_left = 32.0
	box.content_margin_right = 32.0
	box.content_margin_top = 30.0
	box.content_margin_bottom = 30.0
	return box


func _tune_modal_tree(node: Node, mode: String, victory: bool) -> void:
	for child in node.get_children():
		if child is Label:
			_tune_modal_label(child as Label, mode, victory)
		elif child is Button:
			_tune_modal_button(child as Button, mode, victory)
		elif child is PanelContainer and child.get_parent() != modal_layer:
			_tune_inner_panel(child as PanelContainer, mode)
		_tune_modal_tree(child, mode, victory)


func _tune_modal_label(label: Label, mode: String, victory: bool) -> void:
	var text_value: String = label.text
	if mode == "pause":
		if text_value == "Пауза":
			label.add_theme_font_size_override("font_size", 52)
			label.add_theme_color_override("font_color", UI_PARCHMENT_TEXT)
		elif "Уровень" in text_value or text_value.begins_with("Глава "):
			label.visible = false
	elif mode == "settings":
		if text_value == "Настройки":
			label.text = "Звук"
			label.add_theme_font_size_override("font_size", 48)
			label.add_theme_color_override("font_color", UI_PARCHMENT_TEXT)
	elif mode == "result":
		if text_value == "Глава пройдена!":
			label.text = "Уровень пройден!"
			label.add_theme_font_size_override("font_size", 46)
			label.add_theme_color_override("font_color", UI_PARCHMENT_TEXT)
		elif text_value == "Партия окончена":
			label.add_theme_font_size_override("font_size", 46)
			label.add_theme_color_override("font_color", UI_PARCHMENT_TEXT)
		elif "/ 5 слов" in text_value:
			label.visible = false


func _tune_modal_button(button: Button, mode: String, victory: bool) -> void:
	if mode == "pause" and button.text == "К уровням":
		button.visible = false
		return
	if mode == "settings":
		if button.text == "Готово":
			button.text = "Назад"
		elif button.text == "Сбросить прогресс":
			button.visible = false
			return
	if mode == "result" and not victory and button.text == "Играть ещё раз":
		button.visible = false
		return

	var preferred_height: float = 84.0
	if button.text in ["Продолжить", "Начать заново", "Назад"]:
		preferred_height = 90.0
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, preferred_height)
	_apply_control_font(button, 24, Color("fff7dc"))


func _tune_inner_panel(panel: PanelContainer, mode: String) -> void:
	if mode != "settings":
		return
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0.035, 0.085, 0.14, 0.88)
	box.border_color = Color(0.64, 0.46, 0.20, 0.55)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	box.content_margin_left = 20.0
	box.content_margin_right = 20.0
	box.content_margin_top = 14.0
	box.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", box)
