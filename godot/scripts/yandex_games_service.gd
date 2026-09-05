extends Node

# Yandex Games platform service for Godot Web.
# The game code talks only to this node; direct SDK calls stay inside the JS shim.

signal initialized(success: bool)
signal external_pause
signal external_resume
signal fullscreen_opened
signal fullscreen_closed(was_shown: bool)
signal rewarded_opened(tag: String)
signal rewarded(tag: String)
signal rewarded_closed(tag: String, was_shown: bool)
signal cloud_saved(success: bool)
signal review_finished(sent: bool)
signal shortcut_finished(accepted: bool)

const SUPPORTED_LANGUAGES: Array[String] = ["ru"]
const DEFAULT_LANGUAGE: String = "ru"
const CLOUD_KEY: String = "slovopad_save"
const POLL_INTERVAL: float = 0.10
const INIT_TIMEOUT: float = 10.0

var available: bool = false
var initialization_finished: bool = false
var sdk_ready: bool = false
var player_ready: bool = false
var player_authorized: bool = false
var detected_language: String = DEFAULT_LANGUAGE
var effective_language: String = DEFAULT_LANGUAGE
var cloud_data: Dictionary = {}
var server_time_ms: int = 0
var last_error: String = ""

var _poll_accumulator: float = 0.0
var _init_elapsed: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		initialization_finished = true
		initialized.emit(false)
		set_process(false)
		return

	available = true
	_install_bridge()
	set_process(true)


func _process(delta: float) -> void:
	if not available:
		return

	_init_elapsed += delta
	_poll_accumulator += delta
	if _poll_accumulator < POLL_INTERVAL:
		if not initialization_finished and _init_elapsed >= INIT_TIMEOUT:
			_finish_initialization(false, "SDK initialization timeout")
		return
	_poll_accumulator = 0.0
	_poll_js_state()

	if not initialization_finished and _init_elapsed >= INIT_TIMEOUT:
		_finish_initialization(false, "SDK initialization timeout")


func loading_ready() -> void:
	if not sdk_ready:
		return
	_eval("window.__slovopadYandex && window.__slovopadYandex.loadingReady();")


func gameplay_start() -> void:
	if not sdk_ready:
		return
	_eval("window.__slovopadYandex && window.__slovopadYandex.gameplayStart();")


func gameplay_stop() -> void:
	if not sdk_ready:
		return
	_eval("window.__slovopadYandex && window.__slovopadYandex.gameplayStop();")


func save_cloud(payload: Dictionary, flush: bool = false) -> void:
	if not sdk_ready or not player_ready:
		cloud_saved.emit(false)
		return
	var payload_json: String = JSON.stringify(payload)
	var code: String = "window.__slovopadYandex && window.__slovopadYandex.saveCloud(%s, %s);" % [payload_json, "true" if flush else "false"]
	_eval(code)


func show_fullscreen_ad() -> void:
	if not sdk_ready:
		fullscreen_closed.emit(false)
		return
	_eval("window.__slovopadYandex && window.__slovopadYandex.showFullscreenAdv();")


func show_rewarded_ad(tag: String = "reward") -> void:
	if not sdk_ready:
		rewarded_closed.emit(tag, false)
		return
	var safe_tag: String = JSON.stringify(tag)
	_eval("window.__slovopadYandex && window.__slovopadYandex.showRewardedVideo(%s);" % safe_tag)


func request_review() -> void:
	if not sdk_ready:
		review_finished.emit(false)
		return
	_eval("window.__slovopadYandex && window.__slovopadYandex.requestReview();")


func request_shortcut() -> void:
	if not sdk_ready:
		shortcut_finished.emit(false)
		return
	_eval("window.__slovopadYandex && window.__slovopadYandex.requestShortcut();")


func open_auth_dialog() -> void:
	if not sdk_ready:
		return
	_eval("window.__slovopadYandex && window.__slovopadYandex.openAuthDialog();")


func refresh_server_time() -> int:
	if not sdk_ready:
		return server_time_ms
	var value: Variant = _eval("window.__slovopadYandex ? window.__slovopadYandex.getServerTime() : 0;")
	server_time_ms = int(value)
	return server_time_ms


func _install_bridge() -> void:
	_eval(_bridge_source())


func _poll_js_state() -> void:
	var raw: Variant = _eval("JSON.stringify(window.__slovopadYandex ? window.__slovopadYandex.snapshot() : null);")
	if raw == null:
		return
	var text: String = String(raw)
	if text.is_empty() or text == "null":
		return
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return
	var state: Dictionary = parsed as Dictionary

	var sdk_state: String = String(state.get("sdkState", "loading"))
	sdk_ready = sdk_state == "ready"
	player_ready = bool(state.get("playerReady", false))
	player_authorized = bool(state.get("playerAuthorized", false))
	detected_language = String(state.get("language", DEFAULT_LANGUAGE))
	effective_language = String(state.get("effectiveLanguage", DEFAULT_LANGUAGE))
	server_time_ms = int(state.get("serverTime", server_time_ms))
	last_error = String(state.get("lastError", last_error))

	var cloud_value: Variant = state.get("cloudData", {})
	if cloud_value is Dictionary:
		cloud_data = (cloud_value as Dictionary).duplicate(true)

	var events_value: Variant = state.get("events", [])
	if events_value is Array:
		for raw_event in events_value:
			if raw_event is Dictionary:
				_handle_event(raw_event as Dictionary)

	if not initialization_finished:
		if sdk_state == "ready":
			_finish_initialization(true, "")
		elif sdk_state == "failed":
			_finish_initialization(false, last_error)


func _handle_event(event: Dictionary) -> void:
	var event_type: String = String(event.get("type", ""))
	match event_type:
		"pause":
			external_pause.emit()
		"resume":
			external_resume.emit()
		"fullscreen_open":
			fullscreen_opened.emit()
		"fullscreen_close":
			fullscreen_closed.emit(bool(event.get("wasShown", false)))
		"rewarded_open":
			rewarded_opened.emit(String(event.get("tag", "reward")))
		"rewarded":
			rewarded.emit(String(event.get("tag", "reward")))
		"rewarded_close":
			rewarded_closed.emit(String(event.get("tag", "reward")), bool(event.get("wasShown", false)))
		"cloud_saved":
			cloud_saved.emit(bool(event.get("success", false)))
		"review_finished":
			review_finished.emit(bool(event.get("sent", false)))
		"shortcut_finished":
			shortcut_finished.emit(bool(event.get("accepted", false)))


func _finish_initialization(success: bool, error_text: String) -> void:
	if initialization_finished:
		return
	initialization_finished = true
	if not success:
		sdk_ready = false
		last_error = error_text
	initialized.emit(success)


func _eval(code: String) -> Variant:
	if not OS.has_feature("web"):
		return null
	return JavaScriptBridge.eval(code, true)


func _bridge_source() -> String:
	return """
(() => {
    if (window.__slovopadYandex) return;

    const bridge = {
        ysdk: null,
        player: null,
        events: [],
        supportedLanguages: ['ru'],
        state: {
            sdkState: 'loading',
            playerReady: false,
            playerAuthorized: false,
            language: 'ru',
            effectiveLanguage: 'ru',
            cloudData: {},
            serverTime: 0,
            lastError: ''
        },

        push(type, extra = {}) {
            this.events.push(Object.assign({ type }, extra));
        },

        snapshot() {
            return Object.assign({}, this.state, { events: this.events.splice(0) });
        },

        async loadSdk() {
            if (window.YaGames) return;
            const load = (src) => new Promise((resolve, reject) => {
                const existing = document.querySelector('script[data-slovopad-yandex-sdk="1"]');
                if (existing) {
                    existing.addEventListener('load', resolve, { once: true });
                    existing.addEventListener('error', reject, { once: true });
                    return;
                }
                const script = document.createElement('script');
                script.src = src;
                script.async = true;
                script.dataset.slovopadYandexSdk = '1';
                script.onload = resolve;
                script.onerror = reject;
                document.head.appendChild(script);
            });

            try {
                await load('/sdk.js');
            } catch (_) {
                const old = document.querySelector('script[data-slovopad-yandex-sdk="1"]');
                if (old) old.remove();
                await load('https://sdk.games.s3.yandex.net/sdk.js');
            }
        },

        async init() {
            try {
                await this.loadSdk();
                this.ysdk = await window.YaGames.init();

                // Requirement 2.14: language must be detected through the SDK at launch,
                // even for a single-language game.
                const detected = (this.ysdk.environment && this.ysdk.environment.i18n && this.ysdk.environment.i18n.lang) || 'ru';
                this.state.language = String(detected).toLowerCase();
                this.state.effectiveLanguage = this.supportedLanguages.includes(this.state.language) ? this.state.language : 'ru';
                this.state.serverTime = Number(this.ysdk.serverTime ? this.ysdk.serverTime() : Date.now());

                this.ysdk.on('game_api_pause', () => this.push('pause'));
                this.ysdk.on('game_api_resume', () => this.push('resume'));

                try {
                    this.player = await this.ysdk.getPlayer();
                    this.state.playerReady = !!this.player;
                    this.state.playerAuthorized = !!(this.player && this.player.isAuthorized && this.player.isAuthorized());
                    if (this.player) {
                        const data = await this.player.getData(['slovopad_save']);
                        this.state.cloudData = (data && data.slovopad_save) ? data.slovopad_save : {};
                    }
                } catch (playerError) {
                    this.state.playerReady = false;
                    this.state.lastError = 'Player init: ' + String(playerError && playerError.message ? playerError.message : playerError);
                }

                this.state.sdkState = 'ready';
            } catch (error) {
                this.state.sdkState = 'failed';
                this.state.lastError = String(error && error.message ? error.message : error);
            }
        },

        loadingReady() {
            try { this.ysdk && this.ysdk.features && this.ysdk.features.LoadingAPI && this.ysdk.features.LoadingAPI.ready(); } catch (_) {}
        },

        gameplayStart() {
            try { this.ysdk && this.ysdk.features && this.ysdk.features.GameplayAPI && this.ysdk.features.GameplayAPI.start(); } catch (_) {}
        },

        gameplayStop() {
            try { this.ysdk && this.ysdk.features && this.ysdk.features.GameplayAPI && this.ysdk.features.GameplayAPI.stop(); } catch (_) {}
        },

        getServerTime() {
            try {
                const value = Number(this.ysdk && this.ysdk.serverTime ? this.ysdk.serverTime() : Date.now());
                this.state.serverTime = value;
                return value;
            } catch (_) {
                return Number(this.state.serverTime || Date.now());
            }
        },

        async saveCloud(payload, flush) {
            if (!this.player) {
                this.push('cloud_saved', { success: false });
                return;
            }
            try {
                await this.player.setData({ slovopad_save: payload }, !!flush);
                this.state.cloudData = payload;
                this.push('cloud_saved', { success: true });
            } catch (error) {
                this.state.lastError = 'Cloud save: ' + String(error && error.message ? error.message : error);
                this.push('cloud_saved', { success: false });
            }
        },

        showFullscreenAdv() {
            if (!this.ysdk || !this.ysdk.adv) {
                this.push('fullscreen_close', { wasShown: false });
                return;
            }
            try {
                this.ysdk.adv.showFullscreenAdv({
                    callbacks: {
                        onOpen: () => this.push('fullscreen_open'),
                        onClose: (wasShown) => this.push('fullscreen_close', { wasShown: !!wasShown }),
                        onError: (error) => {
                            this.state.lastError = 'Fullscreen ad: ' + String(error && error.message ? error.message : error);
                        }
                    }
                });
            } catch (error) {
                this.state.lastError = 'Fullscreen ad: ' + String(error && error.message ? error.message : error);
                this.push('fullscreen_close', { wasShown: false });
            }
        },

        showRewardedVideo(tag) {
            const rewardTag = String(tag || 'reward');
            if (!this.ysdk || !this.ysdk.adv) {
                this.push('rewarded_close', { tag: rewardTag, wasShown: false });
                return;
            }
            try {
                this.ysdk.adv.showRewardedVideo({
                    callbacks: {
                        onOpen: () => this.push('rewarded_open', { tag: rewardTag }),
                        onRewarded: () => this.push('rewarded', { tag: rewardTag }),
                        onClose: (wasShown) => this.push('rewarded_close', { tag: rewardTag, wasShown: !!wasShown }),
                        onError: (error) => {
                            this.state.lastError = 'Rewarded ad: ' + String(error && error.message ? error.message : error);
                        }
                    }
                });
            } catch (error) {
                this.state.lastError = 'Rewarded ad: ' + String(error && error.message ? error.message : error);
                this.push('rewarded_close', { tag: rewardTag, wasShown: false });
            }
        },

        async openAuthDialog() {
            if (!this.ysdk || !this.ysdk.auth) return;
            try {
                await this.ysdk.auth.openAuthDialog();
                this.player = await this.ysdk.getPlayer();
                this.state.playerReady = !!this.player;
                this.state.playerAuthorized = !!(this.player && this.player.isAuthorized && this.player.isAuthorized());
            } catch (_) {}
        },

        async requestReview() {
            try {
                const check = await this.ysdk.feedback.canReview();
                if (!check || !check.value) {
                    this.push('review_finished', { sent: false });
                    return;
                }
                const result = await this.ysdk.feedback.requestReview();
                this.push('review_finished', { sent: !!(result && (result.feedbackSent || result.sentFeedback)) });
            } catch (_) {
                this.push('review_finished', { sent: false });
            }
        },

        async requestShortcut() {
            try {
                const check = await this.ysdk.shortcut.canShowPrompt();
                if (!check || !check.canShow) {
                    this.push('shortcut_finished', { accepted: false });
                    return;
                }
                const result = await this.ysdk.shortcut.showPrompt();
                this.push('shortcut_finished', { accepted: !!(result && result.outcome === 'accepted') });
            } catch (_) {
                this.push('shortcut_finished', { accepted: false });
            }
        }
    };

    window.__slovopadYandex = bridge;
    bridge.init();
})();
"""
