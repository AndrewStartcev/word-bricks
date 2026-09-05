extends Control

const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/gameplay.tscn")
const AUDIO_SERVICE_SCRIPT: Script = preload("res://scripts/audio_service.gd")
const BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_forest.png")
const OWL_IDLE: Texture2D = preload("res://assets/characters/owl/owl_idle.png")
const OWL_HAPPY: Texture2D = preload("res://assets/characters/owl/owl_happy.png")
const OWL_DEFEAT: Texture2D = preload("res://assets/characters/owl/owl_defeat.png")
const ICON_SETTINGS: Texture2D = preload("res://assets/ui/icons/icon_settings.svg")
const ICON_PAUSE: Texture2D = preload("res://assets/ui/icons/icon_pause.svg")
const ICON_HOME: Texture2D = preload("res://assets/ui/icons/icon_home.svg")
const ICON_RESTART: Texture2D = preload("res://assets/ui/icons/icon_restart.svg")
const ICON_LOCK: Texture2D = preload("res://assets/ui/icons/icon_lock.svg")
const ICON_CHAPTER: Texture2D = preload("res://assets/ui/icons/icon_chapter_forest.svg")
const ICON_MUSIC: Texture2D = preload("res://assets/ui/icons/icon_music_on.svg")
const ICON_SOUND: Texture2D = preload("res://assets/ui/icons/icon_sound_on.svg")
const ICON_SCORE: Texture2D = preload("res://assets/ui/icons/icon_score.svg")
const ICON_COMBO: Texture2D = preload("res://assets/ui/icons/icon_combo.svg")
const ICON_TIME: Texture2D = preload("res://assets/ui/icons/icon_time.svg")

const SETTINGS_PATH := "user://word_bricks_settings.cfg"
const TEXT := Color("f5f8ff")
const MUTED := Color("9fb3d1")
const PRIMARY := Color("2f8df6")
const GREEN := Color("69de87")
const BORDER := Color(0.17, 0.46, 0.76, 0.72)
const PANEL := Color(0.018, 0.055, 0.115, 0.95)
const PANEL_SOFT := Color(0.025, 0.085, 0.16, 0.96)

var font := SystemFont.new()
var app_audio: Node
var game: Control
var screen := Control.new()
var hud := Control.new()
var modal := Control.new()
var screen_id := ""
var modal_id := ""
var result_seen := false

var music_enabled := true
var sfx_enabled := true
var music_volume := 0.72
var sfx_volume := 0.86
var level_complete := false
var best_score := 0
var best_time := 0.0


func _ready() -> void:
	font.font_names = PackedStringArray(["Rubik", "Nunito", "Trebuchet MS", "Verdana", "Arial"])
	_load_state()
	app_audio = AUDIO_SERVICE_SCRIPT.new()
	add_child(app_audio)
	_apply_audio(app_audio)
	for layer in [screen, hud, modal]:
		_full(layer)
		add_child(layer)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_menu()


func _process(_delta: float) -> void:
	if screen_id != "game" or game == null or not is_instance_valid(game) or not modal_id.is_empty():
		return
	if bool(game.get("chapter_complete")) and not result_seen:
		result_seen = true
		show_result(true)
	elif bool(game.get("game_over")) and not result_seen:
		result_seen = true
		show_result(false)
	elif bool(game.get("settings_open")):
		game.set("settings_open", false)
		show_settings(true)
	elif bool(game.get("manual_paused")):
		show_pause()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		_unlock_audio()
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if screen_id == "game":
		if not modal_id.is_empty():
			if key.keycode == KEY_ESCAPE:
				if modal_id == "settings":
					close_settings()
				elif modal_id == "pause":
					resume_game()
				get_viewport().set_input_as_handled()
			return
		if key.keycode == KEY_ESCAPE or key.keycode == KEY_P:
			show_pause()
			get_viewport().set_input_as_handled()
	elif screen_id == "levels" and key.keycode == KEY_ESCAPE:
		show_menu()
		get_viewport().set_input_as_handled()


func show_menu() -> void:
	_dispose_game()
	_clear(screen); _clear(hud); _clear_modal()
	screen_id = "menu"
	result_seen = false
	app_audio.set_suspended("gameplay", false)
	_background(screen, 0.30)

	var owl := TextureRect.new()
	owl.texture = OWL_IDLE
	owl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	owl.position = Vector2(80, 500)
	owl.size = Vector2(320, 320)
	owl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(owl)

	var panel := _panel(Vector2(520, 555), PANEL, true)
	_center(panel, Vector2(80, 0)); screen.add_child(panel)
	var col := _panel_column(panel, 54, 46)
	col.add_child(_label("СЛОВОПАД", 58, TEXT))
	col.add_child(_label("Лес · 5 слов", 20, GREEN))
	col.add_child(_spacer(18))
	var play := _button("Играть", "primary", null, 70); play.pressed.connect(_on_play); col.add_child(play)
	var levels := _button("Уровни", "secondary", ICON_CHAPTER, 62); levels.pressed.connect(_on_levels); col.add_child(levels)
	var settings := _button("Настройки", "secondary", ICON_SETTINGS, 62); settings.pressed.connect(_on_settings_menu); col.add_child(settings)
	col.add_child(_label("Лес пройден" if level_complete else "Первый уровень открыт", 16, GREEN if level_complete else MUTED))
	_animate(panel)


func show_levels() -> void:
	_dispose_game()
	_clear(screen); _clear(hud); _clear_modal()
	screen_id = "levels"
	app_audio.set_suspended("gameplay", false)
	_background(screen, 0.42)

	var bar := _panel(Vector2(1420, 86), Color(0.015, 0.045, 0.095, 0.92), false)
	bar.position = Vector2(90, 54); screen.add_child(bar)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 18); _margin_wrap(bar, row, 18, 12)
	var home := _square_button(ICON_HOME); home.pressed.connect(_on_menu); row.add_child(home)
	var title := _label("Уровни", 34, TEXT, HORIZONTAL_ALIGNMENT_LEFT); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(title)
	row.add_child(_label("1 / 6", 18, MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

	var grid := GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 22); grid.add_theme_constant_override("v_separation", 22)
	grid.position = Vector2(180, 205); grid.size = Vector2(1240, 560); screen.add_child(grid)
	var data := [["Лес", "5 слов", true], ["Море", "Скоро", false], ["Город", "Скоро", false], ["Еда", "Скоро", false], ["Космос", "Скоро", false], ["Сказки", "Скоро", false]]
	for i in range(data.size()):
		var card := _level_card(i + 1, String(data[i][0]), String(data[i][1]), bool(data[i][2]))
		if bool(data[i][2]): card.pressed.connect(_on_play)
		grid.add_child(card)


func start_game() -> void:
	_clear(screen); _clear(hud); _clear_modal()
	screen_id = "game"; result_seen = false
	app_audio.set_suspended("gameplay", true)
	game = GAMEPLAY_SCENE.instantiate() as Control
	_full(game); screen.add_child(game)
	var settings := _square_button(ICON_SETTINGS); settings.position = Vector2(28, 22); settings.pressed.connect(_on_settings_game); hud.add_child(settings)
	var pause := _square_button(ICON_PAUSE); pause.position = Vector2(1510, 22); pause.pressed.connect(_on_pause); hud.add_child(pause)
	hud.mouse_filter = Control.MOUSE_FILTER_PASS
	call_deferred("_sync_game_audio")


func show_pause() -> void:
	if game == null or not is_instance_valid(game) or modal_id == "pause": return
	_clear_modal(); modal_id = "pause"; _pause_game(true)
	var panel := _modal_panel(Vector2(520, 500)); var col := _panel_column(panel, 48, 34)
	col.add_child(_label("Пауза", 44, TEXT)); col.add_child(_label("Глава 1 · Лес", 18, GREEN)); col.add_child(_spacer(12))
	var resume := _button("Продолжить", "primary", null, 68); resume.pressed.connect(_on_resume); col.add_child(resume)
	var restart := _button("Начать заново", "secondary", ICON_RESTART, 58); restart.pressed.connect(_on_restart); col.add_child(restart)
	var settings := _button("Настройки", "secondary", ICON_SETTINGS, 58); settings.pressed.connect(_on_settings_game); col.add_child(settings)
	var levels := _button("К уровням", "ghost", ICON_CHAPTER, 52); levels.pressed.connect(_on_levels); col.add_child(levels)
	var home := _button("В меню", "ghost", ICON_HOME, 52); home.pressed.connect(_on_menu); col.add_child(home)
	_animate(panel)


func show_result(victory: bool) -> void:
	_clear_modal(); modal_id = "victory" if victory else "defeat"; _pause_game(true)
	var panel := _modal_panel(Vector2(650, 570)); var col := _panel_column(panel, 48, 30)
	var owl := TextureRect.new(); owl.texture = OWL_HAPPY if victory else OWL_DEFEAT; owl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; owl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; owl.custom_minimum_size = Vector2(180, 140); owl.mouse_filter = Control.MOUSE_FILTER_IGNORE; col.add_child(owl)
	col.add_child(_label("Глава пройдена!" if victory else "Партия окончена", 42, GREEN if victory else TEXT))
	var completed := (game.get("completed_words") as Array).size(); col.add_child(_label("%d / 5 слов" % completed, 18, MUTED)); col.add_child(_spacer(4))
	var stats := HBoxContainer.new(); stats.alignment = BoxContainer.ALIGNMENT_CENTER; stats.add_theme_constant_override("separation", 12); stats.add_child(_stat("Очки", str(int(game.get("score"))), ICON_SCORE)); stats.add_child(_stat("Время", _time(float(game.get("elapsed"))), ICON_TIME)); stats.add_child(_stat("Комбо", "x%d" % maxi(1, int(game.get("best_combo"))), ICON_COMBO)); col.add_child(stats); col.add_child(_spacer(10))
	if victory:
		_store_victory()
		var levels := _button("К уровням", "primary", ICON_CHAPTER, 66); levels.pressed.connect(_on_levels); col.add_child(levels)
	else:
		var retry := _button("Начать заново", "primary", ICON_RESTART, 66); retry.pressed.connect(_on_restart); col.add_child(retry)
	var replay := _button("Играть ещё раз", "secondary", ICON_RESTART, 56); replay.pressed.connect(_on_restart); col.add_child(replay)
	var home := _button("В меню", "ghost", ICON_HOME, 52); home.pressed.connect(_on_menu); col.add_child(home)
	_animate(panel)


func show_settings(from_game: bool) -> void:
	_clear_modal(); modal_id = "settings"
	if from_game: _pause_game(true)
	var panel := _modal_panel(Vector2(610, 500)); var col := _panel_column(panel, 48, 34)
	col.add_child(_label("Настройки", 40, TEXT)); col.add_child(_spacer(6))
	col.add_child(_settings_row("Музыка", ICON_MUSIC, true)); col.add_child(_settings_row("Звуки", ICON_SOUND, false)); col.add_child(_spacer(10))
	var done := _button("Готово", "primary", null, 64); done.pressed.connect(_on_settings_done); col.add_child(done)
	_animate(panel)


func close_settings() -> void:
	var back_to_game := screen_id == "game"
	_clear_modal()
	if back_to_game: show_pause()


func resume_game() -> void:
	_clear_modal(); _pause_game(false)


func restart_game() -> void:
	_clear_modal(); result_seen = false
	if game == null or not is_instance_valid(game): start_game(); return
	game.call("_reset_game"); _sync_game_audio()


func _settings_row(title: String, icon: Texture2D, is_music: bool) -> Control:
	var panel := _panel(Vector2(0, 108), PANEL_SOFT, false); panel.custom_minimum_size.y = 108
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 14); _margin_wrap(panel, row, 16, 12)
	var image := TextureRect.new(); image.texture = icon; image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; image.custom_minimum_size = Vector2(42, 42); image.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(image)
	var text_col := VBoxContainer.new(); text_col.custom_minimum_size = Vector2(120, 0); text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(text_col)
	text_col.add_child(_label(title, 20, TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var value := _label("", 14, MUTED, HORIZONTAL_ALIGNMENT_LEFT); text_col.add_child(value)
	var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 100; slider.step = 5; slider.custom_minimum_size = Vector2(220, 36); slider.value = (music_volume if is_music else sfx_volume) * 100.0; row.add_child(slider)
	value.text = "%d%%" % int(slider.value)
	var toggle := CheckButton.new(); toggle.text = "Вкл" if (music_enabled if is_music else sfx_enabled) else "Выкл"; toggle.button_pressed = music_enabled if is_music else sfx_enabled; toggle.custom_minimum_size = Vector2(90, 44); _font_control(toggle, 16, TEXT); row.add_child(toggle)
	slider.value_changed.connect(_on_volume_changed.bind(is_music, value))
	toggle.toggled.connect(_on_toggle_changed.bind(is_music, toggle))
	return panel


func _on_volume_changed(v: float, is_music: bool, label: Label) -> void:
	if is_music: music_volume = v / 100.0
	else: sfx_volume = v / 100.0
	label.text = "%d%%" % int(v); _apply_audio_everywhere(); _save_state()


func _on_toggle_changed(enabled: bool, is_music: bool, toggle: CheckButton) -> void:
	if is_music: music_enabled = enabled
	else: sfx_enabled = enabled
	toggle.text = "Вкл" if enabled else "Выкл"; _apply_audio_everywhere(); _save_state()


func _on_play() -> void: _ui_click(); start_game()
func _on_levels() -> void: _ui_click(); show_levels()
func _on_menu() -> void: _ui_click(); show_menu()
func _on_pause() -> void: _ui_click(); show_pause()
func _on_resume() -> void: _ui_click(); resume_game()
func _on_restart() -> void: _ui_click(); restart_game()
func _on_settings_menu() -> void: _ui_click(); show_settings(false)
func _on_settings_game() -> void: _ui_click(); show_settings(true)
func _on_settings_done() -> void: _ui_click(); close_settings()


func _pause_game(value: bool) -> void:
	if game == null or not is_instance_valid(game): return
	game.set("manual_paused", value)
	if not value: game.set("focus_paused", false)
	if game.has_method("_sync_audio_pause"): game.call("_sync_audio_pause")
	game.queue_redraw()


func _modal_panel(size: Vector2) -> PanelContainer:
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new(); shade.color = Color(0.002, 0.01, 0.025, 0.76); shade.mouse_filter = Control.MOUSE_FILTER_STOP; _full(shade); modal.add_child(shade)
	var panel := _panel(size, Color(0.014, 0.05, 0.105, 0.99), true); _center(panel); modal.add_child(panel); return panel


func _panel(size: Vector2, color: Color, shadow: bool) -> PanelContainer:
	var p := PanelContainer.new(); p.custom_minimum_size = size; p.add_theme_stylebox_override("panel", _box(color, BORDER, 12, shadow)); return p


func _panel_column(panel: PanelContainer, mx: int, my: int) -> VBoxContainer:
	var col := VBoxContainer.new(); col.add_theme_constant_override("separation", 12); _margin_wrap(panel, col, mx, my); return col


func _margin_wrap(parent: Control, child: Control, horizontal: int, vertical: int) -> void:
	var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", horizontal); margin.add_theme_constant_override("margin_right", horizontal); margin.add_theme_constant_override("margin_top", vertical); margin.add_theme_constant_override("margin_bottom", vertical); parent.add_child(margin); margin.add_child(child)


func _button(text: String, variant: String, icon: Texture2D, height: float) -> Button:
	var b := Button.new(); b.text = text; b.icon = icon; b.expand_icon = true; b.icon_max_width = 26; b.custom_minimum_size = Vector2(0, height); b.add_theme_constant_override("h_separation", 14); _font_control(b, 20, TEXT)
	if variant == "primary": b.add_theme_stylebox_override("normal", _box(PRIMARY, Color(0.52, 0.80, 1, 0.78), 10, true)); b.add_theme_stylebox_override("hover", _box(Color("46a2ff"), Color(0.72, 0.90, 1, 0.95), 10, true)); b.add_theme_stylebox_override("pressed", _box(Color("1f72d1"), PRIMARY, 10, false))
	elif variant == "ghost": b.add_theme_stylebox_override("normal", _box(Color(0.015, 0.045, 0.085, 0.42), Color(0.14, 0.25, 0.38, 0.65), 10, false)); b.add_theme_stylebox_override("hover", _box(Color(0.03, 0.08, 0.14, 0.85), BORDER, 10, false)); b.add_theme_stylebox_override("pressed", _box(Color(0.02, 0.06, 0.11, 0.95), PRIMARY, 10, false))
	else: b.add_theme_stylebox_override("normal", _box(Color(0.025, 0.09, 0.17, 0.97), BORDER, 10, false)); b.add_theme_stylebox_override("hover", _box(Color(0.04, 0.13, 0.23, 0.99), Color(0.28, 0.66, 1, 0.88), 10, false)); b.add_theme_stylebox_override("pressed", _box(Color(0.025, 0.075, 0.14, 1), PRIMARY, 10, false))
	b.add_theme_stylebox_override("focus", _box(Color(0,0,0,0), Color(0.55,0.82,1,0.9), 10, false)); return b


func _square_button(icon: Texture2D) -> Button:
	var b := Button.new(); b.icon = icon; b.expand_icon = true; b.icon_max_width = 30; b.size = Vector2(58, 58); b.custom_minimum_size = Vector2(58,58); b.add_theme_stylebox_override("normal", _box(Color(0.015,0.055,0.115,0.97), Color(0.13,0.43,0.78,0.82),10,true)); b.add_theme_stylebox_override("hover", _box(Color(0.035,0.11,0.20,0.99),Color(0.34,0.73,1,0.95),10,true)); b.add_theme_stylebox_override("pressed", _box(Color(0.02,0.075,0.14,1),PRIMARY,10,false)); return b


func _level_card(n: int, title: String, subtitle: String, unlocked: bool) -> Button:
	var b := Button.new(); b.custom_minimum_size = Vector2(380,210); b.text = "%02d\n%s\n%s" % [n,title,subtitle]; b.icon = ICON_CHAPTER if unlocked else ICON_LOCK; b.icon_max_width = 54; b.expand_icon = true; b.disabled = not unlocked; b.alignment = HORIZONTAL_ALIGNMENT_LEFT; _font_control(b, 23, TEXT); b.add_theme_stylebox_override("normal", _box(Color(0.018,0.065,0.125,0.95),BORDER,12,true)); b.add_theme_stylebox_override("hover", _box(Color(0.03,0.11,0.20,0.99),Color(0.28,0.67,1,0.9),12,true)); b.add_theme_stylebox_override("disabled", _box(Color(0.018,0.045,0.085,0.84),Color(0.12,0.22,0.35,0.6),12,false)); return b


func _stat(name: String, value: String, icon: Texture2D) -> Control:
	var p := _panel(Vector2(160,86), PANEL_SOFT, false); var row := HBoxContainer.new(); row.add_theme_constant_override("separation",10); _margin_wrap(p,row,12,10); var im := TextureRect.new(); im.texture=icon; im.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; im.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; im.custom_minimum_size=Vector2(34,34); im.mouse_filter=Control.MOUSE_FILTER_IGNORE; row.add_child(im); var c:=VBoxContainer.new(); row.add_child(c); c.add_child(_label(name,13,MUTED,HORIZONTAL_ALIGNMENT_LEFT)); c.add_child(_label(value,20,TEXT,HORIZONTAL_ALIGNMENT_LEFT)); return p


func _label(text: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new(); l.text=text; l.horizontal_alignment=align; l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.add_theme_font_override("font",font); l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",color); return l


func _font_control(c: Control, size: int, color: Color) -> void: c.add_theme_font_override("font",font); c.add_theme_font_size_override("font_size",size); c.add_theme_color_override("font_color",color)
func _spacer(h: float) -> Control: var c:=Control.new(); c.custom_minimum_size=Vector2(0,h); return c


func _box(fill: Color, border: Color, radius: int, shadow: bool) -> StyleBoxFlat:
	var b:=StyleBoxFlat.new(); b.bg_color=fill; b.border_color=border; b.border_width_left=1; b.border_width_top=1; b.border_width_right=1; b.border_width_bottom=1; b.corner_radius_top_left=radius; b.corner_radius_top_right=radius; b.corner_radius_bottom_left=radius; b.corner_radius_bottom_right=radius; b.content_margin_left=14; b.content_margin_right=14; b.content_margin_top=10; b.content_margin_bottom=10
	if shadow: b.shadow_color=Color(0,0,0,0.28); b.shadow_size=10; b.shadow_offset=Vector2(0,5)
	return b


func _background(parent: Control, darkness: float) -> void:
	var t:=TextureRect.new(); t.texture=BACKGROUND; t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; t.mouse_filter=Control.MOUSE_FILTER_IGNORE; _full(t); parent.add_child(t); var shade:=ColorRect.new(); shade.color=Color(0,0.015,0.045,darkness); shade.mouse_filter=Control.MOUSE_FILTER_IGNORE; _full(shade); parent.add_child(shade)


func _center(c: Control, offset:=Vector2.ZERO) -> void:
	var s:=c.custom_minimum_size; c.anchor_left=0.5; c.anchor_top=0.5; c.anchor_right=0.5; c.anchor_bottom=0.5; c.offset_left=-s.x/2+offset.x; c.offset_right=s.x/2+offset.x; c.offset_top=-s.y/2+offset.y; c.offset_bottom=s.y/2+offset.y


func _full(c: Control) -> void: c.anchor_left=0; c.anchor_top=0; c.anchor_right=1; c.anchor_bottom=1; c.offset_left=0; c.offset_top=0; c.offset_right=0; c.offset_bottom=0
func _clear(c: Control) -> void: for child in c.get_children(): child.queue_free()
func _clear_modal() -> void: modal_id=""; _clear(modal); modal.mouse_filter=Control.MOUSE_FILTER_IGNORE


func _animate(c: Control) -> void:
	c.modulate.a=0; c.scale=Vector2(0.97,0.97); c.pivot_offset=c.custom_minimum_size*0.5; var tw:=create_tween(); tw.set_parallel(true); tw.tween_property(c,"modulate:a",1.0,0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT); tw.tween_property(c,"scale",Vector2.ONE,0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _dispose_game() -> void: if game != null and is_instance_valid(game): game.queue_free(); game=null
func _ui_click() -> void: _unlock_audio(); if app_audio != null: app_audio.play_sfx("ui_click")
func _unlock_audio() -> void: if app_audio != null: app_audio.unlock_audio(); if screen_id != "game": app_audio.start_music()


func _apply_audio(service: Node) -> void:
	if service==null:return
	service.set_music_enabled(music_enabled); service.set_sfx_enabled(sfx_enabled); service.set_music_volume(music_volume); service.set_sfx_volume(sfx_volume)


func _sync_game_audio() -> void:
	if game==null or not is_instance_valid(game):return
	var service:Variant=game.get("audio_service"); if service==null:return
	_apply_audio(service); service.unlock_audio(); service.start_music()


func _apply_audio_everywhere() -> void: _apply_audio(app_audio); _sync_game_audio()


func _store_victory() -> void:
	level_complete=true; var score_value:=int(game.get("score")); var time_value:=float(game.get("elapsed")); best_score=maxi(best_score,score_value); if best_time<=0 or time_value<best_time:best_time=time_value; _save_state()


func _load_state() -> void:
	var cfg:=ConfigFile.new(); if cfg.load(SETTINGS_PATH)!=OK:return
	music_enabled=bool(cfg.get_value("audio","music_enabled",true)); sfx_enabled=bool(cfg.get_value("audio","sfx_enabled",true)); music_volume=float(cfg.get_value("audio","music_volume",0.72)); sfx_volume=float(cfg.get_value("audio","sfx_volume",0.86)); level_complete=bool(cfg.get_value("progress","level_complete",false)); best_score=int(cfg.get_value("progress","best_score",0)); best_time=float(cfg.get_value("progress","best_time",0.0))


func _save_state() -> void:
	var cfg:=ConfigFile.new(); cfg.set_value("audio","music_enabled",music_enabled); cfg.set_value("audio","sfx_enabled",sfx_enabled); cfg.set_value("audio","music_volume",music_volume); cfg.set_value("audio","sfx_volume",sfx_volume); cfg.set_value("progress","level_complete",level_complete); cfg.set_value("progress","best_score",best_score); cfg.set_value("progress","best_time",best_time); cfg.save(SETTINGS_PATH)


func _time(seconds: float) -> String: var total:=maxi(0,int(seconds)); return "%02d:%02d" % [total/60,total%60]
