extends "res://scripts/app_runtime_yandex.gd"

# Production UI skin. This layer applies the delivered visual assets while
# keeping campaign, save and Yandex Games behaviour in the inherited runtime.

const UI_LOGO: Texture2D = preload("res://assets/ui/logo/logo_main_small.webp")

const UI_BUTTON_PRIMARY_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_primary_normal.webp")
const UI_BUTTON_PRIMARY_HOVER: Texture2D = preload("res://assets/ui/buttons/button_primary_hover.webp")
const UI_BUTTON_PRIMARY_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_primary_pressed.webp")
const UI_BUTTON_PRIMARY_DISABLED: Texture2D = preload("res://assets/ui/buttons/button_primary_disabled.webp")

const UI_BUTTON_SECONDARY_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_secondary_normal.webp")
const UI_BUTTON_SECONDARY_HOVER: Texture2D = preload("res://assets/ui/buttons/button_secondary_hover.webp")
const UI_BUTTON_SECONDARY_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_secondary_pressed.webp")
const UI_BUTTON_SECONDARY_DISABLED: Texture2D = preload("res://assets/ui/buttons/button_secondary_disabled.webp")

const UI_BUTTON_SMALL_NORMAL: Texture2D = preload("res://assets/ui/buttons/button_small_normal.png")
const UI_BUTTON_SMALL_HOVER: Texture2D = preload("res://assets/ui/buttons/button_small_hover.png")
const UI_BUTTON_SMALL_PRESSED: Texture2D = preload("res://assets/ui/buttons/button_small_pressed.png")
const UI_BUTTON_SMALL_DISABLED: Texture2D = preload("res://assets/ui/buttons/button_small_disabled.png")

const UI_PANEL_MODAL_LARGE: Texture2D = preload("res://assets/ui/panels/panel_modal_large.webp")
const UI_PANEL_MODAL_MEDIUM: Texture2D = preload("res://assets/ui/panels/panel_modal_medium.webp")
const UI_PANEL_MODAL_SMALL: Texture2D = preload("res://assets/ui/panels/panel_modal_small.webp")

const UI_ICON_PLAY: Texture2D = preload("res://assets/ui/icons/icon_play.svg")
const UI_ICON_WORLD_MAP: Texture2D = preload("res://assets/ui/icons/icon_world_map.svg")
const UI_ICON_LOADING: Texture2D = preload("res://assets/ui/icons/icon_loading.svg")

# Stage 4 loading assets.
const UI_LOADING_BAR_FRAME: Texture2D = preload("res://assets/ui/loading/loading_bar_frame.webp")
const UI_LOADING_BAR_FILL: Texture2D = preload("res://assets/ui/loading/loading_bar_fill.png")
const UI_LOADING_BAR_GLOW: Texture2D = preload("res://assets/ui/loading/loading_bar_glow.webp")
const UI_LOADING_BOOKS: Texture2D = preload("res://assets/ui/loading/loading_decor_books.webp")
const UI_LOADING_LANTERN: Texture2D = preload("res://assets/ui/loading/loading_decor_lantern.webp")
const UI_LOADING_CRYSTALS: Texture2D = preload("res://assets/ui/loading/loading_decor_crystals.webp")

# Stage 4 reusable decor.
const UI_DECOR_BOOKS: Texture2D = preload("res://assets/ui/decor/decor_books_stack.webp")
const UI_DECOR_LANTERN: Texture2D = preload("res://assets/ui/decor/decor_lantern.webp")
const UI_DECOR_CRYSTALS: Texture2D = preload("res://assets/ui/decor/decor_crystals.webp")
const UI_DECOR_WOOD_SIGN: Texture2D = preload("res://assets/ui/decor/decor_wood_sign.webp")
const UI_DECOR_BRANCH: Texture2D = preload("res://assets/ui/decor/decor_branch_leaves.webp")
const UI_DECOR_SCROLL_SMALL: Texture2D = preload("res://assets/ui/decor/decor_scroll_small.webp")
const UI_DECOR_SCROLL_LARGE: Texture2D = preload("res://assets/ui/decor/decor_scroll_large.webp")

# Stage 4 chapter/transition assets.
const UI_TRANSITION_TITLE: Texture2D = preload("res://assets/ui/transitions/chapter_title_plate.webp")
const UI_TRANSITION_CARD: Texture2D = preload("res://assets/ui/transitions/chapter_card.webp")
const UI_TRANSITION_ARROW: Texture2D = preload("res://assets/ui/transitions/transition_arrow.png")
const UI_TRANSITION_SEPARATOR: Texture2D = preload("res://assets/ui/transitions/transition_separator.png")
const UI_TRANSITION_NAME: Texture2D = preload("res://assets/ui/transitions/transition_name_plate.webp")

const UI_PARCHMENT_TEXT: Color = Color("3b2a19")
const UI_PARCHMENT_MUTED: Color = Color("725b3d")


func _ready() -> void:
	# Draw the production loading artwork immediately, before the Yandex bootstrap
	# may await the platform SDK. It is a direct child so it survives until the
	# inherited runtime has created its regular screen layers.
	var boot_overlay: Control = _create_boot_loading()
	await get_tree().process_frame
	await super._ready()
	if boot_overlay != null and is_instance_valid(boot_overlay):
		var fade: Tween = create_tween()
		fade.tween_property(boot_overlay, "modulate:a", 0.0, 0.18)
		fade.tween_callback(boot_overlay.queue_free)


func _create_boot_loading() -> Control:
	var overlay: Control = Control.new()
	overlay.name = "ProductionLoading"
	_full_rect(overlay)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var bg: TextureRect = TextureRect.new()
	bg.texture = BACKGROUND
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(bg)
	overlay.add_child(bg)

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.005, 0.018, 0.05, 0.36)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(shade)
	overlay.add_child(shade)

	_add_texture(overlay, UI_DECOR_BRANCH, Rect2(-40.0, -12.0, 470.0, 170.0), 0.90)
	_add_texture(overlay, UI_DECOR_BRANCH, Rect2(1170.0, -12.0, 470.0, 170.0), 0.90, true)
	_add_texture(overlay, UI_LOADING_BOOKS, Rect2(85.0, 620.0, 310.0, 230.0), 1.0)
	_add_texture(overlay, UI_LOADING_LANTERN, Rect2(1270.0, 570.0, 210.0, 270.0), 1.0)
	_add_texture(overlay, UI_LOADING_CRYSTALS, Rect2(1080.0, 675.0, 220.0, 165.0), 0.95)

	var logo: TextureRect = _add_texture(overlay, UI_LOGO, Rect2(470.0, 105.0, 660.0, 300.0), 1.0)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_add_texture(overlay, UI_LOADING_BAR_GLOW, Rect2(280.0, 555.0, 1040.0, 140.0), 0.78)
	var fill_clip: Control = Control.new()
	fill_clip.position = Vector2(350.0, 595.0)
	fill_clip.size = Vector2(100.0, 60.0)
	fill_clip.clip_contents = true
	fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(fill_clip)
	_add_texture(fill_clip, UI_LOADING_BAR_FILL, Rect2(0.0, 0.0, 900.0, 60.0), 1.0)
	_add_texture(overlay, UI_LOADING_BAR_FRAME, Rect2(300.0, 570.0, 1000.0, 110.0), 1.0)
	_add_texture(overlay, UI_ICON_LOADING, Rect2(760.0, 700.0, 80.0, 80.0), 0.95)

	var caption: Label = _label("Магия слов пробуждается…", 22, Color("f7e4b1"), HORIZONTAL_ALIGNMENT_CENTER)
	caption.position = Vector2(500.0, 780.0)
	caption.size = Vector2(600.0, 42.0)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(caption)

	var progress_tween: Tween = create_tween()
	progress_tween.tween_property(fill_clip, "size:x", 810.0, 2.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	progress_tween.set_loops()
	return overlay


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

	_add_background(screen_layer, 0.14)

	# Stage 4 ambient decor. Kept at the edges so gameplay/menu controls remain clear.
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(-30.0, -8.0, 430.0, 155.0), 0.72)
	_add_texture(screen_layer, UI_DECOR_BRANCH, Rect2(1200.0, -8.0, 430.0, 155.0), 0.72, true)
	_add_texture(screen_layer, UI_DECOR_BOOKS, Rect2(1260.0, 650.0, 255.0, 190.0), 0.92)
	_add_texture(screen_layer, UI_DECOR_LANTERN, Rect2(1380.0, 585.0, 145.0, 210.0), 0.94)
	_add_texture(screen_layer, UI_DECOR_CRYSTALS, Rect2(1115.0, 725.0, 180.0, 130.0), 0.72)
	_add_texture(screen_layer, UI_DECOR_WOOD_SIGN, Rect2(625.0, 816.0, 350.0, 66.0), 0.38)

	var owl: TextureRect = TextureRect.new()
	owl.texture = OWL_IDLE
	owl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	owl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owl.position = Vector2(46.0, 500.0)
	owl.size = Vector2(360.0, 360.0)
	screen_layer.add_child(owl)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(720.0, 710.0)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_center_control(panel, Vector2(78.0, -8.0))
	screen_layer.add_child(panel)

	var margin: MarginContainer = _margin(20, 0, 20, 18)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	var logo: TextureRect = TextureRect.new()
	logo.texture = UI_LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(680.0, 300.0)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(logo)
	column.add_child(_modal_spacer(2.0))

	var play_button: Button = _button("Играть", "primary", UI_ICON_PLAY, 116.0)
	_style_menu_button(play_button, 560.0)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)

	var levels_button: Button = _button("Карта мира", "menu_secondary", UI_ICON_WORLD_MAP, 88.0)
	_style_menu_button(levels_button, 500.0)
	levels_button.pressed.connect(_on_levels_pressed)
	column.add_child(levels_button)

	var settings_button: Button = _button("Настройки", "menu_secondary", ICON_SETTINGS, 88.0)
	_style_menu_button(settings_button, 500.0)
	settings_button.pressed.connect(_on_menu_settings_pressed)
	column.add_child(settings_button)

	_animate_in(panel)


func _show_level_select() -> void:
	super._show_level_select()
	if current_screen != "locations":
		return
	# Large parchment under the map hint and subtle crystals at the lower edge.
	var scroll: TextureRect = _add_texture(screen_layer, UI_DECOR_SCROLL_LARGE, Rect2(440.0, 132.0, 720.0, 96.0), 0.80)
	screen_layer.move_child(scroll, mini(2, screen_layer.get_child_count() - 1))
	_add_texture(screen_layer, UI_DECOR_CRYSTALS, Rect2(690.0, 785.0, 220.0, 125.0), 0.52)


func _show_location_levels(location_id: String) -> void:
	super._show_location_levels(location_id)
	if current_screen != "levels":
		return
	var scroll: TextureRect = _add_texture(screen_layer, UI_DECOR_SCROLL_SMALL, Rect2(615.0, 112.0, 370.0, 72.0), 0.70)
	screen_layer.move_child(scroll, mini(2, screen_layer.get_child_count() - 1))
	_add_texture(screen_layer, UI_DECOR_CRYSTALS, Rect2(1220.0, 740.0, 210.0, 120.0), 0.46)


func _show_location_transition(target_id: String) -> void:
	super._show_location_transition(target_id)
	if current_screen != "chapter_transition":
		return
	_decorate_transition(target_id)


func _show_finale(page_index: int = 0) -> void:
	super._show_finale(page_index)
	if current_screen != "finale":
		return
	_add_texture(screen_layer, UI_TRANSITION_TITLE, Rect2(520.0, 30.0, 560.0, 86.0), 0.98)
	var title: Label = _label("Финал", 27, Color("f7e4b1"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(590.0, 51.0)
	title.size = Vector2(420.0, 40.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(title)
	_add_texture(screen_layer, UI_TRANSITION_SEPARATOR, Rect2(580.0, 684.0, 440.0, 45.0), 0.82)


func _decorate_transition(target_id: String) -> void:
	var previous_id: String = LEVEL_CATALOG.previous_location(target_id)
	var previous_title: String = LEVEL_CATALOG.location_title(previous_id)
	var target_title: String = LEVEL_CATALOG.location_title(target_id)

	var card: TextureRect = _add_texture(screen_layer, UI_TRANSITION_CARD, Rect2(105.0, 552.0, 620.0, 285.0), 0.96)
	screen_layer.move_child(card, mini(2, screen_layer.get_child_count() - 1))
	var name_plate: TextureRect = _add_texture(screen_layer, UI_TRANSITION_NAME, Rect2(160.0, 565.0, 510.0, 76.0), 1.0)
	screen_layer.move_child(name_plate, mini(3, screen_layer.get_child_count() - 1))
	_add_texture(screen_layer, UI_TRANSITION_SEPARATOR, Rect2(190.0, 632.0, 450.0, 42.0), 0.88)
	_add_texture(screen_layer, UI_TRANSITION_ARROW, Rect2(738.0, 395.0, 124.0, 92.0), 0.92)
	_add_texture(screen_layer, UI_TRANSITION_TITLE, Rect2(92.0, 42.0, 620.0, 88.0), 1.0)

	var top_title: Label = _label("%s → %s" % [previous_title, target_title], 27, Color("f7e4b1"), HORIZONTAL_ALIGNMENT_CENTER)
	top_title.position = Vector2(155.0, 64.0)
	top_title.size = Vector2(495.0, 40.0)
	top_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(top_title)


func _add_texture(parent: Control, texture: Texture2D, rect: Rect2, alpha: float = 1.0, flip_h: bool = false) -> TextureRect:
	var item: TextureRect = TextureRect.new()
	item.texture = texture
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.position = rect.position
	item.size = rect.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.modulate.a = alpha
	item.flip_h = flip_h
	parent.add_child(item)
	return item


func _style_menu_button(button: Button, width: float) -> void:
	button.custom_minimum_size.x = width
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _show_pause_modal() -> void:
	super._show_pause_modal()
	if current_modal != "pause":
		return
	_tune_modal_tree(modal_layer, "pause", false)
	call_deferred("_recenter_active_modal")


func _show_settings_modal(from_game: bool) -> void:
	super._show_settings_modal(from_game)
	if current_modal != "settings":
		return
	_tune_modal_tree(modal_layer, "settings", false)
	call_deferred("_recenter_active_modal")


func _show_result_modal(victory: bool) -> void:
	super._show_result_modal(victory)
	if current_modal != ("victory" if victory else "defeat"):
		return
	_tune_modal_tree(modal_layer, "result", victory)
	call_deferred("_recenter_active_modal")


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

	var use_small: bool = display_height <= 76.0 or variant == "menu_secondary"
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
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	modal_layer.add_child(panel)
	call_deferred("_center_modal_panel_exact", panel)
	return panel


func _modal_column(panel: PanelContainer) -> VBoxContainer:
	var margin: MarginContainer = _margin(48, 42, 48, 42)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	return column


func _center_modal_panel_exact(panel: PanelContainer) -> void:
	if panel == null or not is_instance_valid(panel) or modal_layer == null:
		return
	panel.position = (modal_layer.size - panel.size) * 0.5


func _recenter_active_modal() -> void:
	for child in modal_layer.get_children():
		if child is PanelContainer:
			_center_modal_panel_exact(child as PanelContainer)


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
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
			label.add_theme_font_size_override("font_size", 44)
			label.add_theme_color_override("font_color", UI_PARCHMENT_TEXT)
		elif text_value == "Партия окончена":
			label.add_theme_font_size_override("font_size", 44)
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
