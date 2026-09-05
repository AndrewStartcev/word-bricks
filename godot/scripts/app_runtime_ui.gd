extends "res://scripts/app_runtime_yandex.gd"

# Production UI skin. This layer only applies delivered visual assets while
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

	_add_background(screen_layer, 0.30)

	var owl: TextureRect = TextureRect.new()
	owl.texture = OWL_IDLE
	owl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	owl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owl.position = Vector2(80.0, 500.0)
	owl.size = Vector2(320.0, 320.0)
	screen_layer.add_child(owl)

	var panel: PanelContainer = _panel(Vector2(560.0, 620.0), Color(0.012, 0.035, 0.07, 0.88), true)
	_center_control(panel, Vector2(80.0, 0.0))
	screen_layer.add_child(panel)
	var margin: MarginContainer = _margin(50, 34, 50, 42)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var logo: TextureRect = TextureRect.new()
	logo.texture = UI_LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(440.0, 190.0)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(logo)

	var active_id: String = _active_location_id()
	var active_completed: int = _completed_for_location(active_id)
	column.add_child(_label("%s · %d / 10 уровней" % [LEVEL_CATALOG.location_title(active_id), active_completed], 20, COL_GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(8.0))

	var play_button: Button = _button("Играть", "primary", UI_ICON_PLAY, 72.0)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)
	var levels_button: Button = _button("Карта мира", "secondary", UI_ICON_WORLD_MAP, 64.0)
	levels_button.pressed.connect(_on_levels_pressed)
	column.add_child(levels_button)
	var settings_button: Button = _button("Настройки", "secondary", ICON_SETTINGS, 64.0)
	settings_button.pressed.connect(_on_menu_settings_pressed)
	column.add_child(settings_button)

	var status_text: String = ""
	if _campaign_complete():
		status_text = "Мир восстановлен" if finale_seen else "Остался финал"
	elif active_completed == 0 and active_id != "forest":
		status_text = "Открыта новая локация"
	elif active_completed == 0:
		status_text = "Начать путешествие"
	else:
		status_text = "Продолжить · Уровень %d" % mini(10, active_completed + 1)
	column.add_child(_label(status_text, 16, COL_GREEN if _campaign_complete() else COL_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_animate_in(panel)


func _button(text: String, variant: String, icon: Texture2D = null, height: float = 60.0) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, height)
	button.focus_mode = Control.FOCUS_ALL
	button.icon = icon
	button.icon_max_width = 26
	button.expand_icon = true
	button.add_theme_constant_override("h_separation", 14)
	_apply_control_font(button, 20, Color("fff7dc"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("fff0bd"))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.64, 0.70))

	if variant == "ghost":
		button.add_theme_stylebox_override("normal", _style_box(Color(0.015, 0.045, 0.085, 0.40), Color(0.14, 0.25, 0.38, 0.65), 10, false))
		button.add_theme_stylebox_override("hover", _style_box(Color(0.03, 0.08, 0.14, 0.82), Color(0.20, 0.48, 0.75, 0.75), 10, false))
		button.add_theme_stylebox_override("pressed", _style_box(Color(0.02, 0.06, 0.11, 0.95), COL_BORDER, 10, false))
		button.add_theme_stylebox_override("disabled", _style_box(Color(0.015, 0.035, 0.07, 0.35), Color(0.12, 0.20, 0.30, 0.45), 10, false))
	else:
		var use_small: bool = height <= 54.0
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

		button.add_theme_stylebox_override("normal", _button_texture_box(normal_tex))
		button.add_theme_stylebox_override("hover", _button_texture_box(hover_tex))
		button.add_theme_stylebox_override("pressed", _button_texture_box(pressed_tex))
		button.add_theme_stylebox_override("disabled", _button_texture_box(disabled_tex))

	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _modal_panel(panel_size: Vector2) -> PanelContainer:
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.002, 0.008, 0.02, 0.78)
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


func _button_texture_box(texture: Texture2D) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = 72.0
	box.texture_margin_right = 72.0
	box.texture_margin_top = 40.0
	box.texture_margin_bottom = 40.0
	box.content_margin_left = 24.0
	box.content_margin_right = 24.0
	box.content_margin_top = 12.0
	box.content_margin_bottom = 12.0
	return box


func _panel_texture_box(texture: Texture2D) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = 96.0
	box.texture_margin_right = 96.0
	box.texture_margin_top = 96.0
	box.texture_margin_bottom = 96.0
	box.content_margin_left = 28.0
	box.content_margin_right = 28.0
	box.content_margin_top = 24.0
	box.content_margin_bottom = 24.0
	return box
