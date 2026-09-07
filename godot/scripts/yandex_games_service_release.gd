extends "res://scripts/yandex_games_service_hardened.gd"

# Web release wrapper. JavaScriptBridge.eval() is synchronous in the single-threaded
# Web build, so polling the SDK ten times per second wastes main-thread time inside
# the Yandex iframe. Keep bootstrap responsive, then poll platform events at a much
# lower cadence once initialization is complete.

const RELEASE_INIT_POLL_INTERVAL: float = 0.20
const RELEASE_RUNTIME_POLL_INTERVAL: float = 0.75


func _process(delta: float) -> void:
	if not available:
		return

	_init_elapsed += delta
	_poll_accumulator += delta
	var interval: float = RELEASE_RUNTIME_POLL_INTERVAL if initialization_finished else RELEASE_INIT_POLL_INTERVAL
	if _poll_accumulator < interval:
		if not initialization_finished and _init_elapsed >= INIT_TIMEOUT:
			_finish_initialization(false, "SDK initialization timeout")
		return

	_poll_accumulator = 0.0
	_poll_js_state()

	if not initialization_finished and _init_elapsed >= INIT_TIMEOUT:
		_finish_initialization(false, "SDK initialization timeout")
