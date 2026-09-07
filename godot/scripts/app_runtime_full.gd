extends "res://scripts/app_runtime_levels.gd"

# Full campaign runtime:
# intro -> 6 locations x 10 levels -> inter-location comic pages -> finale.
# The older runtime layers remain as compatibility/migration helpers, while this
# layer owns the complete campaign state and all newly delivered production art.

const FULL_PROGRESS_VERSION: int = 1
const TOTAL_CAMPAIGN_LEVELS: int = 60

const SEA_MENU_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_sea.webp")
const CITY_MENU_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_city.webp")
const FAIRYTALES_MENU_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_fairytales.webp")
const TOWER_MENU_BACKGROUND: Texture2D = preload("res://assets/backgrounds/background_tower.webp")

const SEA_CHAPTER_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_sea.svg")
const CITY_CHAPTER_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_city.svg")
const FAIRYTALES_CHAPTER_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_fairytales.svg")
const TOWER_CHAPTER_ICON: Texture2D = preload("res://assets/ui/icons/icon_chapter_tower.svg")

const SEA_TRANSITION_FRAMES: Array[Texture2D] = [
	preload("res://assets/comics/sea_unlock/sea_unlock_01.webp"),
	preload("res://assets/comics/sea_unlock/sea_unlock_02.webp"),
	preload("res://assets/comics/sea_unlock/sea_unlock_03.webp")
]
const CITY_TRANSITION_FRAMES: Array[Texture2D] = [
	preload("res://assets/comics/city_unlock/city_unlock_01.webp"),
	preload("res://assets/comics/city_unlock/city_unlock_02.webp"),
	preload("res://assets/comics/city_unlock/city_unlock_03.webp")
]
const FAIRYTALES_TRANSITION_FRAMES: Array[Texture2D] = [
	preload("res://assets/comics/fairytales_unlock/fairytales_unlock_01.webp"),
	preload("res://assets/comics/fairytales_unlock/fairytales_unlock_02.webp"),
	preload("res://assets/comics/fairytales_unlock/fairytales_unlock_03.webp")
]
const TOWER_TRANSITION_FRAMES: Array[Texture2D] = [
	preload("res://assets/comics/tower_unlock/tower_unlock_01.webp"),
	preload("res://assets/comics/tower_unlock/tower_unlock_02.webp"),
	preload("res://assets/comics/tower_unlock/tower_unlock_03.webp")
]
const FINALE_FRAMES: Array[Texture2D] = [
	preload("res://assets/comics/finale/finale_01.webp"),
	preload("res://assets/comics/finale/finale_02.webp"),
	preload("res://assets/comics/finale/finale_03.webp"),
	preload("res://assets/comics/finale/finale_04.webp")
]
const FINALE_PAGES: Array = [[0, 1], [2, 3]]

const TRANSITION_CTA: Dictionary = {
	"village": "В деревню",
	"sea": "К морю",
	"city": "В город",
	"fairytales": "В мир сказок",
	"tower": "В башню"
}
const LOCATION_FINISH_TITLES: Dictionary = {
	"forest": "Лес восстановлен!",
	"village": "Деревня восстановлена!",
	"sea": "Море восстановлено!",
	"city": "Город восстановлен!",
	"fairytales": "Сказки восстановлены!",
	"tower": "Башня пройдена!"
}

var completed_levels: Dictionary = {
	"forest": 0,
	"village": 0,
	"sea": 0,
	"city": 0,
	"fairytales": 0,
	"tower": 0
}
var transition_seen: Dictionary = {
	"village": false,
	"sea": false,
	"city": false,
	"fairytales": false,
	"tower": false
}
var transition_target_id: String = ""
var finale_seen: bool = false
var finale_page: int = 0


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if current_screen == "chapter_transition":
				if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_RIGHT:
					_unlock_app_audio()
					_finish_location_transition()
					get_viewport().set_input_as_handled()
					return
				if key_event.keycode == KEY_ESCAPE:
					_unlock_app_audio()
					_show_level_select()
					get_viewport().set_input_as_handled()
					return
			if current_screen == "finale":
				if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_RIGHT:
					_unlock_app_audio()
					_advance_finale()
					get_viewport().set_input_as_handled()
					return
				if key_event.keycode == KEY_ESCAPE:
					_unlock_app_audio()
					_finish_finale()
					get_viewport().set_input_as_handled()
					return
	super._input(event)


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

	var panel: PanelContainer = _panel(Vector2(520.0, 555.0), COL_PANEL)
	_center_control(panel, Vector2(80.0, 0.0))
	screen_layer.add_child(panel)
	var margin: MarginContainer = _margin(54, 46, 54, 46)
	panel.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var active_id: String = _active_location_id()
	var active_completed: int = _completed_for_location(active_id)
	column.add_child(_label("СЛОВОПАД", 58, COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_label("%s · %d / 10 уровней" % [LEVEL_CATALOG.location_title(active_id), active_completed], 20, COL_GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(_modal_spacer(18.0))

	var play_button: Button = _button("Играть", "primary", null, 70.0)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)
	var levels_button: Button = _button("Карта мира", "secondary", _icon_for_location(active_id), 62.0)
	levels_button.pressed.connect(_on_levels_pressed)
	column.add_child(levels_button)
	var settings_button: Button = _button("Настройки", "secondary", ICON_SETTINGS, 62.0)
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


func _show_level_select() -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "locations"
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	_add_background(screen_layer, 0.48)

	var top_panel: PanelContainer = _panel(Vector2(1420.0, 90.0), Color(0.012, 0.040, 0.085, 0.92))
	top_panel.position = Vector2(90.0, 45.0)
	screen_layer.add_child(top_panel)
	var top_margin: MarginContainer = _margin(20, 13, 24, 13)
	top_panel.add_child(top_margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	top_margin.add_child(row)
	var home: Button = _icon_button(ICON_HOME, "В меню")
	home.pressed.connect(_on_menu_pressed)
	row.add_child(home)
	var title: Label = _label("Карта мира", 34, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(_label("%d / %d уровней" % [_total_completed_levels(), TOTAL_CAMPAIGN_LEVELS], 18, COL_GREEN if _campaign_complete() else COL_MUTED, HORIZONTAL_ALIGNMENT_RIGHT))

	var hint_text: String = "Мир восстановлен — все слова снова на своих местах" if _campaign_complete() else "Возвращай слова — и дорога будет открываться дальше"
	var hint: Label = _label(hint_text, 18, Color(0.72, 0.84, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(380.0, 148.0)
	hint.size = Vector2(840.0, 40.0)
	screen_layer.add_child(hint)

	var points: Array[Vector2] = [
		Vector2(250.0, 620.0), Vector2(505.0, 470.0), Vector2(775.0, 585.0),
		Vector2(1045.0, 420.0), Vector2(1310.0, 565.0), Vector2(1180.0, 245.0)
	]
	_add_route(points, Color(0.25, 0.55, 0.82, 0.42), 8.0)

	for i in range(LEVEL_CATALOG.LOCATION_ORDER.size()):
		var location_id: String = LEVEL_CATALOG.LOCATION_ORDER[i]
		var unlocked: bool = _is_location_unlocked(location_id)
		var icon: Texture2D = _icon_for_location(location_id) if unlocked else ICON_LOCK
		_add_location_node(location_id, LEVEL_CATALOG.location_title(location_id), i + 1, points[i], unlocked, _completed_for_location(location_id), icon)


func _on_location_selected(location_id: String) -> void:
	_ui_click()
	if not _is_location_unlocked(location_id):
		return
	current_level_id = location_id
	if _needs_transition(location_id):
		_show_location_transition(location_id)
		return
	_show_location_levels(location_id)


func _on_play_pressed() -> void:
	_ui_click()
	intro_replay_only = false
	if not intro_seen:
		current_level_id = "forest"
		current_stage_number = 1
		_show_intro(0)
		return
	if _campaign_complete():
		if not finale_seen:
			_show_finale(0)
		else:
			_show_level_select()
		return

	var active_id: String = _active_location_id()
	current_level_id = active_id
	if _needs_transition(active_id):
		_show_location_transition(active_id)
		return
	current_stage_number = mini(10, _completed_for_location(active_id) + 1)
	_start_game()


func _finish_intro() -> void:
	intro_seen = true
	_save_local_state()
	if intro_replay_only:
		intro_replay_only = false
		_show_main_menu()
		return
	current_level_id = "forest"
	current_stage_number = 1
	_start_game()


func _show_village_transition() -> void:
	_show_location_transition("village")


func _show_location_transition(target_id: String) -> void:
	if target_id == "forest" or not _is_location_unlocked(target_id):
		_show_level_select()
		return
	var frames: Array = _transition_frames(target_id)
	if frames.size() < 3:
		transition_seen[target_id] = true
		_save_local_state()
		_show_location_levels(target_id)
		return

	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "chapter_transition"
	current_modal = ""
	transition_target_id = target_id
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

	_add_comic_panel(frames[0] as Texture2D, Rect2(55.0, 145.0, 720.0, 405.0))
	_add_comic_panel(frames[1] as Texture2D, Rect2(825.0, 70.0, 720.0, 405.0))
	_add_comic_panel(frames[2] as Texture2D, Rect2(825.0, 493.0, 720.0, 405.0))

	var previous_id: String = LEVEL_CATALOG.previous_location(target_id)
	var title_text: String = "%s восстановлен" % LEVEL_CATALOG.location_title(previous_id)
	if previous_id == "village":
		title_text = "Деревня восстановлена"
	elif previous_id == "sea":
		title_text = "Море восстановлено"
	elif previous_id == "fairytales":
		title_text = "Сказки восстановлены"
	var title: Label = _label(title_text, 28, COL_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(165.0, 590.0)
	title.size = Vector2(500.0, 46.0)
	screen_layer.add_child(title)

	var start_button: Button = _button(String(TRANSITION_CTA.get(target_id, "Продолжить")), "primary", _icon_for_location(target_id), 62.0)
	start_button.position = Vector2(245.0, 665.0)
	start_button.size = Vector2(340.0, 62.0)
	start_button.pressed.connect(_finish_location_transition)
	screen_layer.add_child(start_button)
	var map_button: Button = _button("К карте мира", "ghost", ICON_CHAPTER, 54.0)
	map_button.position = Vector2(245.0, 744.0)
	map_button.size = Vector2(340.0, 54.0)
	map_button.pressed.connect(_show_level_select)
	screen_layer.add_child(map_button)

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


func _finish_location_transition() -> void:
	if transition_target_id.is_empty():
		transition_target_id = current_level_id
	transition_seen[transition_target_id] = true
	if transition_target_id == "village":
		village_transition_seen = true
	current_level_id = transition_target_id
	current_stage_number = mini(10, _completed_for_location(current_level_id) + 1)
	_save_local_state()
	_show_location_levels(current_level_id)


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

	var title_text: String = "Партия окончена"
	if victory:
		title_text = "Уровень %d пройден!" % current_stage_number if current_stage_number < 10 else String(LOCATION_FINISH_TITLES.get(current_level_id, "Локация восстановлена!"))
	column.add_child(_label(title_text, 42, COL_GREEN if victory else COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER))

	var completed_words_value: Variant = game.get("completed_words")
	var completed_count: int = (completed_words_value as Array).size() if completed_words_value is Array else 0
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
		var next_text: String = "Следующий уровень" if current_stage_number < 10 else ("Финал" if current_level_id == "tower" else "Продолжить путь")
		var next_button: Button = _button(next_text, "primary", ICON_CHAPTER, 66.0)
		next_button.pressed.connect(_on_levels_pressed)
		column.add_child(next_button)
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


func _show_pause_modal() -> void:
	super._show_pause_modal()
	var wanted: String = "%s · Уровень %d / 10" % [LEVEL_CATALOG.location_title(current_level_id), current_stage_number]
	_replace_label_text(modal_layer, "Лес · Уровень %d / 10" % current_stage_number, wanted)
	_replace_label_text(modal_layer, "Деревня · Уровень %d / 10" % current_stage_number, wanted)


func _on_levels_pressed() -> void:
	_ui_click()
	if current_screen == "game" and game != null and is_instance_valid(game):
		if bool(game.get("chapter_complete")):
			if current_stage_number < 10:
				current_stage_number += 1
				_start_game()
				return
			var next_id: String = LEVEL_CATALOG.next_location(current_level_id)
			if not next_id.is_empty():
				current_level_id = next_id
				_show_location_transition(next_id)
				return
			_show_finale(0)
			return
		_show_location_levels(current_level_id)
		return
	_show_level_select()


func _store_victory_stats() -> void:
	if game == null or not is_instance_valid(game):
		return
	completed_levels[current_level_id] = maxi(_completed_for_location(current_level_id), current_stage_number)
	_sync_legacy_progress()
	var score_value: int = int(game.get("score"))
	var time_value: float = float(game.get("elapsed"))
	best_score = maxi(best_score, score_value)
	if best_time <= 0.0 or time_value < best_time:
		best_time = time_value
	_save_local_state()


func _show_finale(page_index: int = 0) -> void:
	_dispose_game()
	_clear_layer(screen_layer)
	_clear_layer(gameplay_ui_layer)
	_clear_modal()
	current_screen = "finale"
	current_modal = ""
	finale_page = clampi(page_index, 0, FINALE_PAGES.size() - 1)
	gameplay_ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if app_audio != null:
		app_audio.set_suspended("gameplay", false)

	var background: ColorRect = ColorRect.new()
	background.color = Color("020914")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(background)
	screen_layer.add_child(background)
	var page_back: PanelContainer = PanelContainer.new()
	page_back.position = Vector2(28.0, 24.0)
	page_back.size = Vector2(1544.0, 852.0)
	page_back.add_theme_stylebox_override("panel", _comic_page_style())
	page_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(page_back)

	var page: Array = FINALE_PAGES[finale_page]
	_add_comic_panel(FINALE_FRAMES[int(page[0])], Rect2(62.0, 165.0, 718.0, 404.0))
	_add_comic_panel(FINALE_FRAMES[int(page[1])], Rect2(820.0, 165.0, 718.0, 404.0))
	var counter: Label = _label("Финал · %d / %d" % [finale_page + 1, FINALE_PAGES.size()], 17, COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	counter.position = Vector2(58.0, 46.0)
	counter.size = Vector2(220.0, 36.0)
	screen_layer.add_child(counter)
	var skip_button: Button = _button("Пропустить", "ghost", null, 48.0)
	skip_button.position = Vector2(1370.0, 34.0)
	skip_button.size = Vector2(180.0, 48.0)
	skip_button.pressed.connect(_finish_finale)
	screen_layer.add_child(skip_button)
	var next_text: String = "В меню" if finale_page == FINALE_PAGES.size() - 1 else "Далее"
	var next_button: Button = _button(next_text, "primary", null, 58.0)
	next_button.position = Vector2(1320.0, 806.0)
	next_button.size = Vector2(230.0, 58.0)
	next_button.pressed.connect(_advance_finale)
	screen_layer.add_child(next_button)

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


func _advance_finale() -> void:
	_ui_click()
	if finale_page >= FINALE_PAGES.size() - 1:
		_finish_finale()
		return
	finale_page += 1
	_show_finale(finale_page)


func _finish_finale() -> void:
	finale_seen = true
	_save_local_state()
	_show_main_menu()


func _completed_for_location(location_id: String) -> int:
	return clampi(int(completed_levels.get(location_id, 0)), 0, 10)


func _is_location_unlocked(location_id: String) -> bool:
	if location_id == "forest":
		return true
	var previous_id: String = LEVEL_CATALOG.previous_location(location_id)
	return not previous_id.is_empty() and _completed_for_location(previous_id) >= 10


func _needs_transition(location_id: String) -> bool:
	return location_id != "forest" and _is_location_unlocked(location_id) and not bool(transition_seen.get(location_id, false))


func _active_location_id() -> String:
	for location_id in LEVEL_CATALOG.LOCATION_ORDER:
		if _is_location_unlocked(location_id) and _completed_for_location(location_id) < 10:
			return location_id
	return "tower"


func _campaign_complete() -> bool:
	return _completed_for_location("tower") >= 10


func _total_completed_levels() -> int:
	var total: int = 0
	for location_id in LEVEL_CATALOG.LOCATION_ORDER:
		total += _completed_for_location(location_id)
	return total


func _transition_frames(target_id: String) -> Array:
	match target_id:
		"village": return VILLAGE_TRANSITION_FRAMES
		"sea": return SEA_TRANSITION_FRAMES
		"city": return CITY_TRANSITION_FRAMES
		"fairytales": return FAIRYTALES_TRANSITION_FRAMES
		"tower": return TOWER_TRANSITION_FRAMES
		_: return []


func _icon_for_location(location_id: String) -> Texture2D:
	match location_id:
		"forest": return ICON_CHAPTER
		"village": return VILLAGE_CHAPTER_ICON
		"sea": return SEA_CHAPTER_ICON
		"city": return CITY_CHAPTER_ICON
		"fairytales": return FAIRYTALES_CHAPTER_ICON
		"tower": return TOWER_CHAPTER_ICON
		_: return ICON_CHAPTER


func _background_for_location(location_id: String) -> Texture2D:
	match location_id:
		"forest": return FOREST_MENU_BACKGROUND
		"village": return VILLAGE_MENU_BACKGROUND
		"sea": return SEA_MENU_BACKGROUND
		"city": return CITY_MENU_BACKGROUND
		"fairytales": return FAIRYTALES_MENU_BACKGROUND
		"tower": return TOWER_MENU_BACKGROUND
		_: return FOREST_MENU_BACKGROUND


func _add_background(parent: Control, darkness: float) -> void:
	_add_background_texture(parent, _background_for_location(_active_location_id()), darkness)


func _add_location_background(parent: Control, location_id: String, darkness: float) -> void:
	_add_background_texture(parent, _background_for_location(location_id), darkness)


func _add_background_texture(parent: Control, texture_value: Texture2D, darkness: float) -> void:
	var texture: TextureRect = TextureRect.new()
	texture.texture = texture_value
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


func _sync_legacy_progress() -> void:
	forest_completed_levels = _completed_for_location("forest")
	village_completed_levels = _completed_for_location("village")
	level_one_complete = forest_completed_levels >= 10
	village_complete = village_completed_levels >= 10
	village_transition_seen = bool(transition_seen.get("village", false))


func _reset_progress_data() -> void:
	for location_id in LEVEL_CATALOG.LOCATION_ORDER:
		completed_levels[location_id] = 0
	for target_id in transition_seen.keys():
		transition_seen[target_id] = false
	transition_target_id = ""
	finale_seen = false
	finale_page = 0
	current_level_id = "forest"
	current_stage_number = 1
	super._reset_progress_data()


func _load_local_state() -> void:
	super._load_local_state()
	completed_levels["forest"] = forest_completed_levels
	completed_levels["village"] = village_completed_levels
	transition_seen["village"] = village_transition_seen

	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_sync_legacy_progress()
		return
	var full_version: int = int(config.get_value("meta", "full_progress_version", 0))
	if full_version >= FULL_PROGRESS_VERSION:
		for location_id in LEVEL_CATALOG.LOCATION_ORDER:
			completed_levels[location_id] = clampi(int(config.get_value("campaign", "%s_completed" % location_id, completed_levels.get(location_id, 0))), 0, 10)
		for target_id in transition_seen.keys():
			transition_seen[target_id] = bool(config.get_value("story", "%s_transition_seen" % String(target_id), transition_seen[target_id]))
		finale_seen = bool(config.get_value("story", "finale_seen", false))
		var saved_location: String = String(config.get_value("campaign", "last_location", current_level_id))
		if LEVEL_CATALOG.LOCATION_ORDER.has(saved_location) and _is_location_unlocked(saved_location):
			current_level_id = saved_location
		current_stage_number = clampi(int(config.get_value("campaign", "last_level", current_stage_number)), 1, 10)

	# A transition cannot stay seen when the preceding location itself is locked.
	for target_id in transition_seen.keys():
		if not _is_location_unlocked(String(target_id)):
			transition_seen[target_id] = false
	if not _campaign_complete():
		finale_seen = false
	_sync_legacy_progress()
	if full_version < FULL_PROGRESS_VERSION:
		_save_local_state()


func _save_local_state() -> void:
	_sync_legacy_progress()
	super._save_local_state()
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("meta", "full_progress_version", FULL_PROGRESS_VERSION)
	for location_id in LEVEL_CATALOG.LOCATION_ORDER:
		config.set_value("campaign", "%s_completed" % location_id, _completed_for_location(location_id))
	for target_id in transition_seen.keys():
		config.set_value("story", "%s_transition_seen" % String(target_id), bool(transition_seen[target_id]))
	config.set_value("story", "finale_seen", finale_seen)
	config.set_value("campaign", "last_location", current_level_id)
	config.set_value("campaign", "last_level", current_stage_number)
	config.save(SETTINGS_PATH)
