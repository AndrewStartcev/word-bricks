extends Node

# Centralized non-positional audio for the desktop/Web build.
# User volume lives on buses; per-event gain follows audio_manifest.json.

const MUSIC_TEMPLATE: AudioStreamOggVorbis = preload("res://assets/audio/music/music_forest_loop.ogg")

const SFX_STREAMS: Dictionary = {
	"ui_click": preload("res://assets/audio/sfx/sfx_ui_click.wav"),
	"ui_back": preload("res://assets/audio/sfx/sfx_ui_back.wav"),
	"piece_move": preload("res://assets/audio/sfx/sfx_piece_move.wav"),
	"piece_rotate": preload("res://assets/audio/sfx/sfx_piece_rotate.wav"),
	"piece_lock": preload("res://assets/audio/sfx/sfx_piece_lock.wav"),
	"line_clear": preload("res://assets/audio/sfx/sfx_line_clear.wav"),
	"word_complete": preload("res://assets/audio/sfx/sfx_word_complete.wav"),
	"chapter_complete": preload("res://assets/audio/sfx/sfx_chapter_complete.wav"),
	"hint": preload("res://assets/audio/sfx/sfx_hint.wav"),
	"invalid": preload("res://assets/audio/sfx/sfx_invalid.wav"),
	"defeat": preload("res://assets/audio/sfx/sfx_defeat.wav"),
	"coin_collect": preload("res://assets/audio/sfx/sfx_coin_collect.wav")
}

const SFX_GAIN_DB: Dictionary = {
	"ui_click": -15.0,
	"ui_back": -15.0,
	"piece_move": -23.0,
	"piece_rotate": -19.0,
	"piece_lock": -13.0,
	"line_clear": -12.0,
	"word_complete": -10.0,
	"chapter_complete": -9.0,
	"hint": -14.0,
	"invalid": -20.0,
	"defeat": -13.0,
	"coin_collect": -16.0
}

const SFX_COOLDOWN_MS: Dictionary = {
	"ui_click": 80,
	"ui_back": 100,
	"piece_move": 65,
	"piece_rotate": 90,
	"piece_lock": 100,
	"line_clear": 180,
	"word_complete": 400,
	"chapter_complete": 1000,
	"hint": 250,
	"invalid": 300,
	"defeat": 1000,
	"coin_collect": 80
}

const LOW_PRIORITY_EVENTS: Array[String] = ["ui_click", "ui_back", "piece_move"]
const MUSIC_GAIN_DB: float = -5.0
const SFX_POOL_SIZE: int = 8

var music_enabled: bool = true
var sfx_enabled: bool = true
var music_volume: float = 0.72
var sfx_volume: float = 0.86

var _audio_unlocked: bool = false
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _cooldown_until: Dictionary = {}
var _suspended_reasons: Dictionary = {}


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	_music_player.volume_db = MUSIC_GAIN_DB
	var music_stream: AudioStreamOggVorbis = MUSIC_TEMPLATE.duplicate() as AudioStreamOggVorbis
	music_stream.loop = true
	music_stream.loop_offset = 0.0
	_music_player.stream = music_stream
	add_child(_music_player)

	for i in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

	_apply_bus_state()


func unlock_audio() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	_update_music_state()


func play_sfx(event_id: String) -> void:
	if not sfx_enabled or not _audio_unlocked:
		return
	if not SFX_STREAMS.has(event_id):
		return

	var now: int = Time.get_ticks_msec()
	var next_allowed: int = int(_cooldown_until.get(event_id, 0))
	if now < next_allowed:
		return
	_cooldown_until[event_id] = now + int(SFX_COOLDOWN_MS.get(event_id, 0))

	var player: AudioStreamPlayer = _find_free_sfx_player()
	if player == null:
		if LOW_PRIORITY_EVENTS.has(event_id):
			return
		player = _sfx_players[0]

	player.stream = SFX_STREAMS[event_id] as AudioStream
	player.volume_db = float(SFX_GAIN_DB.get(event_id, -12.0))
	player.play()


func start_music() -> void:
	unlock_audio()
	_update_music_state()


func set_music_enabled(value: bool) -> void:
	music_enabled = value
	_apply_bus_state()
	_update_music_state()


func set_sfx_enabled(value: bool) -> void:
	sfx_enabled = value
	_apply_bus_state()
	if not sfx_enabled:
		_stop_all_sfx()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_state()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_state()


func set_suspended(reason: String, value: bool) -> void:
	if value:
		_suspended_reasons[reason] = true
	else:
		_suspended_reasons.erase(reason)
	_update_music_state()


func reset_round_audio() -> void:
	_cooldown_until.clear()
	_stop_all_sfx()


func is_music_enabled() -> bool:
	return music_enabled


func is_sfx_enabled() -> bool:
	return sfx_enabled


func get_music_volume() -> float:
	return music_volume


func get_sfx_volume() -> float:
	return sfx_volume


func _ensure_bus(bus_name: String) -> int:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index >= 0:
		return index
	AudioServer.add_bus()
	index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	return index


func _apply_bus_state() -> void:
	var music_bus: int = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_mute(music_bus, not music_enabled)
		AudioServer.set_bus_volume_db(music_bus, _linear_volume_to_db(music_volume))

	var sfx_bus: int = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_mute(sfx_bus, not sfx_enabled)
		AudioServer.set_bus_volume_db(sfx_bus, _linear_volume_to_db(sfx_volume))


func _linear_volume_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value)


func _update_music_state() -> void:
	if _music_player == null:
		return
	if not _audio_unlocked:
		return

	var should_suspend: bool = not _suspended_reasons.is_empty()
	if not _music_player.playing:
		_music_player.play()
	_music_player.stream_paused = should_suspend


func _find_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return null


func _stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()
