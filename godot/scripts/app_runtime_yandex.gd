extends "res://scripts/app_runtime_full.gd"

# Yandex Games runtime adapter.
# Keeps platform concerns outside the core gameplay and campaign scripts.

const CLOUD_SCHEMA: int = 1
const CLOUD_DEBOUNCE_SECONDS: float = 2.0
const CLOUD_RETRY_BASE_SECONDS: float = 3.0
const CLOUD_RETRY_MAX_SECONDS: float = 30.0
const INTERSTITIAL_MIN_GAMEPLAY_SECONDS: float = 180.0
const INTERSTITIAL_MIN_COMPLETED_LEVELS: int = 2

var _cloud_sync_enabled: bool = false
var _cloud_dirty: bool = false
var _cloud_timer: float = 0.0
var _cloud_save_in_flight: bool = false
var _cloud_revision_in_flight: int = -1
var _cloud_retry_attempts: int = 0

var _platform_pause_active: bool = false
var _resume_game_after_platform_pause: bool = false
var _ad_pause_active: bool = false
var _resume_game_after_ad: bool = false
var _interstitial_pending: bool = false
var _gameplay_seconds_since_interstitial: float = 0.0
var _completed_levels_since_interstitial: int = 0


func _ready() -> void:
	# Wait for SDK bootstrap before loading local state so cloud progress can be
	# restored before the menu is shown. Native/local builds fall back immediately.
	if not YandexGames.initialization_finished:
		await YandexGames.initialized

	_apply_platform_language()
	var cloud_applied: bool = _merge_cloud_into_local_file()

	super._ready()
	_connect_platform_signals()
	_cloud_sync_enabled = true

	# If the cloud did not replace local data, publish the current local snapshot.
	if not cloud_applied:
		_queue_cloud_sync()

	# Game Ready must be sent only after the playable UI exists.
	YandexGames.loading_ready()

	if YandexGames.external_paused:
		_on_platform_pause()


func _process(delta: float) -> void:
	super._process(delta)

	if current_screen == "game" and game != null and is_instance_valid(game):
		var paused: bool = bool(game.get("manual_paused")) or bool(game.get("focus_paused")) or not current_modal.is_empty()
		var finished: bool = bool(game.get("game_over")) or bool(game.get("chapter_complete"))
		if not paused and not finished and not _platform_pause_active and not _ad_pause_active:
			_gameplay_seconds_since_interstitial += delta

	if not _cloud_sync_enabled or not _cloud_dirty or _cloud_save_in_flight:
		return
	_cloud_timer -= delta
	if _cloud_timer <= 0.0:
		_sync_cloud_now(false)


func _start_game() -> void:
	super._start_game()
	YandexGames.gameplay_start()


func _show_main_menu() -> void:
	YandexGames.gameplay_stop()
	super._show_main_menu()


func _show_level_select() -> void:
	YandexGames.gameplay_stop()
	super._show_level_select()


func _show_location_levels(location_id: String) -> void:
	YandexGames.gameplay_stop()
	super._show_location_levels(location_id)


func _show_location_transition(target_id: String) -> void:
	YandexGames.gameplay_stop()
	super._show_location_transition(target_id)


func _show_finale(page_index: int = 0) -> void:
	YandexGames.gameplay_stop()
	super._show_finale(page_index)


func _show_pause_modal() -> void:
	YandexGames.gameplay_stop()
	super._show_pause_modal()


func _show_result_modal(victory: bool) -> void:
	YandexGames.gameplay_stop()
	if victory:
		_completed_levels_since_interstitial += 1
	super._show_result_modal(victory)


func _show_settings_modal(from_game: bool) -> void:
	if from_game:
		YandexGames.gameplay_stop()
	super._show_settings_modal(from_game)

	# Product decision: intro replay is not exposed in Settings.
	var replay_button: Button = _find_button_by_text(modal_layer, "Посмотреть вступление")
	if replay_button != null:
		var parent: Node = replay_button.get_parent()
		if parent != null:
			parent.remove_child(replay_button)
		replay_button.free()

	var panel: PanelContainer = _get_current_modal_panel()
	if panel != null:
		panel.custom_minimum_size = Vector2(610.0, 590.0)
		_center_control(panel)


func _resume_game() -> void:
	super._resume_game()
	if current_screen == "game" and current_modal.is_empty() and not _platform_pause_active and not _ad_pause_active:
		YandexGames.gameplay_start()


func _restart_game() -> void:
	super._restart_game()
	if current_screen == "game" and not _platform_pause_active and not _ad_pause_active:
		YandexGames.gameplay_start()


func _on_levels_pressed() -> void:
	# Fullscreen ads are requested only after an explicit user action at a logical
	# break. Our own cooldown prevents an ad request after every short round; Yandex
	# still controls whether an eligible request is actually shown.
	if current_screen == "game" and game != null and is_instance_valid(game) and bool(game.get("chapter_complete")):
		_ui_click()
		if _can_request_interstitial():
			_interstitial_pending = true
			YandexGames.gameplay_stop()
			YandexGames.show_fullscreen_ad()
			return
		_continue_after_completed_level()
		return

	super._on_levels_pressed()


func _can_request_interstitial() -> bool:
	return (
		YandexGames.sdk_ready
		and not _interstitial_pending
		and _completed_levels_since_interstitial >= INTERSTITIAL_MIN_COMPLETED_LEVELS
		and _gameplay_seconds_since_interstitial >= INTERSTITIAL_MIN_GAMEPLAY_SECONDS
	)


func request_rewarded_hint() -> void:
	# Ready for the final UI pass: a future "+ hint for ad" button can call this.
	if current_screen != "game" or game == null or not is_instance_valid(game):
		return
	YandexGames.gameplay_stop()
	YandexGames.show_rewarded_ad("hint")


func request_yandex_auth() -> void:
	# Must only be called from a clearly labelled voluntary authorization button.
	YandexGames.open_auth_dialog()


func request_yandex_review() -> void:
	YandexGames.request_review()


func request_yandex_shortcut() -> void:
	YandexGames.request_shortcut()


func _continue_after_completed_level() -> void:
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


func _connect_platform_signals() -> void:
	if not YandexGames.external_pause.is_connected(_on_platform_pause):
		YandexGames.external_pause.connect(_on_platform_pause)
	if not YandexGames.external_resume.is_connected(_on_platform_resume):
		YandexGames.external_resume.connect(_on_platform_resume)
	if not YandexGames.fullscreen_opened.is_connected(_on_ad_opened):
		YandexGames.fullscreen_opened.connect(_on_ad_opened)
	if not YandexGames.fullscreen_closed.is_connected(_on_fullscreen_closed):
		YandexGames.fullscreen_closed.connect(_on_fullscreen_closed)
	if not YandexGames.rewarded_opened.is_connected(_on_rewarded_opened):
		YandexGames.rewarded_opened.connect(_on_rewarded_opened)
	if not YandexGames.rewarded.is_connected(_on_rewarded):
		YandexGames.rewarded.connect(_on_rewarded)
	if not YandexGames.rewarded_closed.is_connected(_on_rewarded_closed):
		YandexGames.rewarded_closed.connect(_on_rewarded_closed)
	if not YandexGames.cloud_saved.is_connected(_on_cloud_saved):
		YandexGames.cloud_saved.connect(_on_cloud_saved)
	if not YandexGames.account_changed.is_connected(_on_account_changed):
		YandexGames.account_changed.connect(_on_account_changed)


func _on_platform_pause() -> void:
	if _platform_pause_active:
		return
	_platform_pause_active = true
	_resume_game_after_platform_pause = false

	if app_audio != null:
		app_audio.set_suspended("yandex_platform", true)

	if current_screen == "game" and game != null and is_instance_valid(game):
		var already_paused: bool = bool(game.get("manual_paused")) or not current_modal.is_empty()
		var finished: bool = bool(game.get("game_over")) or bool(game.get("chapter_complete"))
		_resume_game_after_platform_pause = not already_paused and not finished
		if _resume_game_after_platform_pause:
			_pause_game(true)

	if _cloud_dirty:
		_sync_cloud_now(true)


func _on_platform_resume() -> void:
	if not _platform_pause_active:
		return
	_platform_pause_active = false

	if app_audio != null:
		app_audio.set_suspended("yandex_platform", false)

	var resume_from_ad: bool = _resume_game_after_ad and not _ad_pause_active
	if (_resume_game_after_platform_pause or resume_from_ad) and current_screen == "game" and current_modal.is_empty():
		_pause_game(false)
		YandexGames.gameplay_start()
	_resume_game_after_platform_pause = false
	if resume_from_ad:
		_resume_game_after_ad = false


func _on_ad_opened() -> void:
	_begin_ad_pause()


func _on_rewarded_opened(_tag: String) -> void:
	_begin_ad_pause()


func _begin_ad_pause() -> void:
	_ad_pause_active = true
	_resume_game_after_ad = false
	if app_audio != null:
		app_audio.set_suspended("yandex_ad", true)

	if current_screen == "game" and game != null and is_instance_valid(game):
		var already_paused: bool = bool(game.get("manual_paused")) or not current_modal.is_empty()
		var finished: bool = bool(game.get("game_over")) or bool(game.get("chapter_complete"))
		_resume_game_after_ad = not already_paused and not finished
		if _resume_game_after_ad:
			_pause_game(true)


func _end_ad_pause() -> void:
	_ad_pause_active = false
	if app_audio != null:
		app_audio.set_suspended("yandex_ad", false)

	if _resume_game_after_ad and not _platform_pause_active and current_screen == "game" and current_modal.is_empty():
		_pause_game(false)
		YandexGames.gameplay_start()
		_resume_game_after_ad = false


func _on_fullscreen_closed(_was_shown: bool) -> void:
	_end_ad_pause()
	if not _interstitial_pending:
		return
	_interstitial_pending = false
	# Reset on every completed request, including wasShown=false, so the app does
	# not hammer the SDK again on the very next short level.
	_gameplay_seconds_since_interstitial = 0.0
	_completed_levels_since_interstitial = 0
	_continue_after_completed_level()


func _on_rewarded(tag: String) -> void:
	if tag != "hint":
		return
	if current_screen == "game" and game != null and is_instance_valid(game):
		game.set("hint_charges", int(game.get("hint_charges")) + 1)
		game.queue_redraw()


func _on_rewarded_closed(_tag: String, _was_shown: bool) -> void:
	_end_ad_pause()
	if current_screen == "game" and game != null and is_instance_valid(game) and current_modal.is_empty() and not _platform_pause_active and not _ad_pause_active:
		YandexGames.gameplay_start()


func _save_local_state() -> void:
	super._save_local_state()
	if not _cloud_sync_enabled:
		return
	_bump_cloud_revision()
	_queue_cloud_sync()


func _queue_cloud_sync() -> void:
	# Native builds and a failed SDK keep using local saves only.
	if not YandexGames.available or not YandexGames.sdk_ready:
		return
	# Mark dirty even when Player is temporarily unavailable. _process() will retry
	# once it becomes ready instead of silently losing a save.
	_cloud_dirty = true
	_cloud_timer = CLOUD_DEBOUNCE_SECONDS
	_cloud_retry_attempts = 0


func _sync_cloud_now(flush: bool) -> void:
	if _cloud_save_in_flight:
		return
	if not YandexGames.sdk_ready or not YandexGames.player_ready:
		_cloud_dirty = true
		_cloud_timer = CLOUD_RETRY_BASE_SECONDS
		return

	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_cloud_dirty = true
		_cloud_timer = CLOUD_RETRY_BASE_SECONDS
		return

	var revision: int = int(config.get_value("platform", "cloud_revision", 0))
	var local_saved_at: int = int(config.get_value("platform", "local_saved_at", 0))
	if local_saved_at <= 0:
		local_saved_at = YandexGames.refresh_server_time()
	var payload: Dictionary = {
		"schema": CLOUD_SCHEMA,
		"revision": revision,
		"saved_at": local_saved_at,
		"config": _config_to_dictionary(config)
	}
	_cloud_save_in_flight = true
	_cloud_revision_in_flight = revision
	YandexGames.save_cloud(payload, flush)
	_cloud_timer = 0.0


func _on_cloud_saved(success: bool) -> void:
	var sent_revision: int = _cloud_revision_in_flight
	_cloud_save_in_flight = false
	_cloud_revision_in_flight = -1

	if success:
		_cloud_retry_attempts = 0
		var current_revision: int = _current_cloud_revision()
		if current_revision <= sent_revision:
			_cloud_dirty = false
			_cloud_timer = 0.0
		else:
			# Local state changed while the previous request was in flight.
			_cloud_dirty = true
			_cloud_timer = CLOUD_DEBOUNCE_SECONDS
		return

	_cloud_dirty = true
	_cloud_retry_attempts += 1
	var exponent: int = mini(_cloud_retry_attempts - 1, 4)
	_cloud_timer = minf(CLOUD_RETRY_MAX_SECONDS, CLOUD_RETRY_BASE_SECONDS * pow(2.0, float(exponent)))


func _current_cloud_revision() -> int:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return 0
	return int(config.get_value("platform", "cloud_revision", 0))


func _bump_cloud_revision() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var revision: int = int(config.get_value("platform", "cloud_revision", 0)) + 1
	var saved_at: int = 0
	if YandexGames.sdk_ready:
		saved_at = YandexGames.refresh_server_time()
	if saved_at <= 0:
		saved_at = int(Time.get_unix_time_from_system() * 1000.0)
	config.set_value("platform", "cloud_revision", revision)
	config.set_value("platform", "local_saved_at", saved_at)
	config.save(SETTINGS_PATH)


func _on_account_changed() -> void:
	# Never replace an active round from underneath the player. If an account
	# changes mid-game, the current local session remains authoritative and is
	# queued to the newly selected Player after the next save boundary.
	if current_screen == "game":
		_queue_cloud_sync()
		return

	_cloud_save_in_flight = false
	_cloud_revision_in_flight = -1
	var cloud_applied: bool = _merge_cloud_into_local_file()
	if cloud_applied:
		var sync_was_enabled: bool = _cloud_sync_enabled
		_cloud_sync_enabled = false
		_load_local_state()
		_cloud_sync_enabled = sync_was_enabled
		_refresh_screen_after_account_change()
	else:
		_queue_cloud_sync()


func _refresh_screen_after_account_change() -> void:
	match current_screen:
		"menu":
			_show_main_menu()
		"locations":
			_show_level_select()
		"location_levels":
			_show_location_levels(current_level_id)
		"chapter_transition":
			var target_id: String = transition_target_id if not transition_target_id.is_empty() else current_level_id
			_show_location_transition(target_id)
		"intro":
			_show_intro(intro_index)
		"finale":
			_show_finale(finale_page)


func _merge_cloud_into_local_file() -> bool:
	if not YandexGames.sdk_ready or YandexGames.cloud_data.is_empty():
		return false
	var cloud: Dictionary = YandexGames.cloud_data
	if int(cloud.get("schema", 0)) != CLOUD_SCHEMA:
		return false
	var cloud_config_value: Variant = cloud.get("config", {})
	if not (cloud_config_value is Dictionary):
		return false

	var local: ConfigFile = ConfigFile.new()
	var local_loaded: bool = local.load(SETTINGS_PATH) == OK
	var local_revision: int = int(local.get_value("platform", "cloud_revision", 0)) if local_loaded else 0
	var local_saved_at: int = int(local.get_value("platform", "local_saved_at", 0)) if local_loaded else 0
	var cloud_revision: int = int(cloud.get("revision", 0))
	var cloud_saved_at: int = int(cloud.get("saved_at", 0))

	if local_loaded:
		if local_saved_at > 0 and cloud_saved_at > 0:
			if local_saved_at > cloud_saved_at:
				return false
			if local_saved_at == cloud_saved_at and local_revision >= cloud_revision:
				return false
		elif local_revision >= cloud_revision:
			# Backward compatibility for saves made before timestamps were stored.
			return false

	var cloud_config: Dictionary = cloud_config_value as Dictionary
	for section_key in cloud_config.keys():
		var section_name: String = String(section_key)
		var section_value: Variant = cloud_config[section_key]
		if not (section_value is Dictionary):
			continue
		for key_value in (section_value as Dictionary).keys():
			local.set_value(section_name, String(key_value), (section_value as Dictionary)[key_value])
	local.set_value("platform", "cloud_revision", cloud_revision)
	if cloud_saved_at > 0:
		local.set_value("platform", "local_saved_at", cloud_saved_at)
	local.save(SETTINGS_PATH)
	return true


func _config_to_dictionary(config: ConfigFile) -> Dictionary:
	var output: Dictionary = {}
	for raw_section in config.get_sections():
		var section: String = String(raw_section)
		var values: Dictionary = {}
		for raw_key in config.get_section_keys(section):
			var key: String = String(raw_key)
			values[key] = config.get_value(section, key)
		output[section] = values
	return output


func _apply_platform_language() -> void:
	# The game currently declares only Russian. We still detect the Yandex locale at
	# launch (mandatory) and map unsupported locales to the declared fallback.
	var locale: String = YandexGames.effective_language
	if locale.is_empty():
		locale = "ru"
	TranslationServer.set_locale(locale)


func _find_button_by_text(root: Node, wanted_text: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == wanted_text:
			return child as Button
		var nested: Button = _find_button_by_text(child, wanted_text)
		if nested != null:
			return nested
	return null
