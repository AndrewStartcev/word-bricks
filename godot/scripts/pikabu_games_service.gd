extends Node

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
signal account_changed
signal account_selection_opened

const POLL_INTERVAL := 0.25
const INIT_TIMEOUT := 12.0

var available := false
var initialization_finished := false
var sdk_ready := false
var player_ready := false
var player_authorized := false
var external_paused := false
var detected_language := "ru"
var effective_language := "ru"
var cloud_data: Dictionary = {}
var server_time_ms := 0
var last_error := ""

var _poll_accumulator := 0.0
var _init_elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		initialization_finished = true
		initialized.emit(false)
		set_process(false)
		return
	available = true
	JavaScriptBridge.eval(_bridge_source(), true)
	set_process(true)

func _process(delta: float) -> void:
	if not available:
		return
	_init_elapsed += delta
	_poll_accumulator += delta
	if _poll_accumulator < POLL_INTERVAL:
		if not initialization_finished and _init_elapsed >= INIT_TIMEOUT:
			_finish_initialization(false, "Pikabu SDK initialization timeout")
		return
	_poll_accumulator = 0.0
	_poll_state()

func loading_ready() -> void:
	if sdk_ready:
		JavaScriptBridge.eval("window.__slovopadPikabu && window.__slovopadPikabu.gameStarted();", true)

func gameplay_start() -> void:
	pass

func gameplay_stop() -> void:
	pass

func save_cloud(payload: Dictionary, _flush: bool = false) -> void:
	if not sdk_ready or not player_ready:
		cloud_saved.emit(false)
		return
	var code := "window.__slovopadPikabu && window.__slovopadPikabu.saveCloud(%s);" % JSON.stringify(payload)
	JavaScriptBridge.eval(code, true)

func show_fullscreen_ad() -> void:
	if not sdk_ready:
		fullscreen_closed.emit(false)
		return
	JavaScriptBridge.eval("window.__slovopadPikabu && window.__slovopadPikabu.showFullscreen();", true)

func show_rewarded_ad(tag: String = "reward") -> void:
	if not sdk_ready:
		rewarded_closed.emit(tag, false)
		return
	JavaScriptBridge.eval("window.__slovopadPikabu && window.__slovopadPikabu.showRewarded(%s);" % JSON.stringify(tag), true)

func request_review() -> void:
	review_finished.emit(false)

func request_shortcut() -> void:
	shortcut_finished.emit(false)

func open_auth_dialog() -> void:
	if sdk_ready:
		JavaScriptBridge.eval("window.__slovopadPikabu && window.__slovopadPikabu.openAuth();", true)

func refresh_server_time() -> int:
	server_time_ms = int(Time.get_unix_time_from_system() * 1000.0)
	return server_time_ms

func _poll_state() -> void:
	var raw: Variant = JavaScriptBridge.eval("JSON.stringify(window.__slovopadPikabu ? window.__slovopadPikabu.snapshot() : null);", true)
	if raw == null:
		return
	var parsed := JSON.parse_string(String(raw))
	if not (parsed is Dictionary):
		return
	var state: Dictionary = parsed
	sdk_ready = bool(state.get("sdkReady", false))
	player_ready = bool(state.get("playerReady", false))
	player_authorized = bool(state.get("playerAuthorized", false))
	last_error = String(state.get("lastError", ""))
	var cloud: Variant = state.get("cloudData", {})
	if cloud is Dictionary:
		cloud_data = (cloud as Dictionary).duplicate(true)
	var events: Variant = state.get("events", [])
	if events is Array:
		for item in events:
			if item is Dictionary:
				_handle_event(item)
	if not initialization_finished and sdk_ready:
		_finish_initialization(true, "")

func _handle_event(event: Dictionary) -> void:
	match String(event.get("type", "")):
		"pause":
			external_paused = true
			external_pause.emit()
		"resume":
			external_paused = false
			external_resume.emit()
		"fullscreen_open": fullscreen_opened.emit()
		"fullscreen_close": fullscreen_closed.emit(bool(event.get("wasShown", false)))
		"rewarded_open": rewarded_opened.emit(String(event.get("tag", "reward")))
		"rewarded": rewarded.emit(String(event.get("tag", "reward")))
		"rewarded_close": rewarded_closed.emit(String(event.get("tag", "reward")), bool(event.get("wasShown", false)))
		"cloud_saved": cloud_saved.emit(bool(event.get("success", false)))
		"account_changed": account_changed.emit()

func _finish_initialization(success: bool, error_text: String) -> void:
	if initialization_finished:
		return
	initialization_finished = true
	if not success:
		sdk_ready = false
		last_error = error_text
	initialized.emit(success)

func _bridge_source() -> String:
	return """
(() => {
  if (window.__slovopadPikabu) return;
  const bridge = {
    sdk: null,
    events: [],
    state: { sdkReady:false, playerReady:false, playerAuthorized:false, cloudData:{}, lastError:'' },
    push(type, extra={}) { this.events.push(Object.assign({type}, extra)); },
    snapshot() { return Object.assign({}, this.state, {events:this.events.splice(0)}); },
    async loadSdk() {
      if (window.PkbSDK) return;
      await new Promise((resolve, reject) => {
        const s = document.createElement('script');
        s.src = 'https://games.pikabu.ru/sdk/sdk.js';
        s.async = true;
        s.onload = resolve;
        s.onerror = reject;
        document.head.appendChild(s);
      });
    },
    async loadCloud() {
      if (!this.sdk || !this.sdk.player || !this.sdk.player.id) return;
      try {
        const r = await fetch('cloud.php?action=load&player=' + encodeURIComponent(this.sdk.player.id), {cache:'no-store'});
        if (r.ok) {
          const data = await r.json();
          this.state.cloudData = data && data.data ? data.data : {};
        }
      } catch (e) { this.state.lastError = 'Cloud load: ' + String(e); }
    },
    async init() {
      try {
        await this.loadSdk();
        this.sdk = await window.PkbSDK.init();
        this.state.playerReady = !!(this.sdk && this.sdk.player);
        this.state.playerAuthorized = !!(this.sdk && this.sdk.player && this.sdk.player.isAuthorized);
        if (this.sdk && this.sdk.on) {
          this.sdk.on('userAuthorized', async () => {
            this.state.playerAuthorized = !!this.sdk.player.isAuthorized;
            await this.loadCloud();
            this.push('account_changed');
          });
        }
        document.addEventListener('visibilitychange', () => {
          if (document.hidden) this.push('pause'); else this.push('resume');
        });
        window.addEventListener('blur', () => this.push('pause'));
        window.addEventListener('focus', () => this.push('resume'));
        await this.loadCloud();
        this.state.sdkReady = true;
      } catch (e) { this.state.lastError = String(e); }
    },
    gameStarted() { try { this.sdk && this.sdk.gameStarted && this.sdk.gameStarted(); } catch (_) {} },
    async saveCloud(payload) {
      if (!this.sdk || !this.sdk.player || !this.sdk.player.id) { this.push('cloud_saved',{success:false}); return; }
      try {
        const r = await fetch('cloud.php?action=save&player=' + encodeURIComponent(this.sdk.player.id), {
          method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(payload)
        });
        this.state.cloudData = payload;
        this.push('cloud_saved',{success:r.ok});
      } catch (e) { this.state.lastError='Cloud save: '+String(e); this.push('cloud_saved',{success:false}); }
    },
    async showFullscreen() {
      if (!this.sdk || !this.sdk.ads || !this.sdk.ads.fullscreen) { this.push('fullscreen_close',{wasShown:false}); return; }
      try {
        const ad = this.sdk.ads.fullscreen;
        const can = ad.isSupported && await ad.canShow();
        if (!can) { this.push('fullscreen_close',{wasShown:false}); return; }
        this.push('fullscreen_open');
        const r = await ad.show();
        this.push('fullscreen_close',{wasShown:!!(r && r.rendered)});
      } catch (e) { this.state.lastError='Fullscreen: '+String(e); this.push('fullscreen_close',{wasShown:false}); }
    },
    async showRewarded(tag) {
      if (!this.sdk || !this.sdk.ads || !this.sdk.ads.rewarded) { this.push('rewarded_close',{tag,wasShown:false}); return; }
      try {
        const ad = this.sdk.ads.rewarded;
        const can = ad.isSupported && await ad.canShow();
        if (!can) { this.push('rewarded_close',{tag,wasShown:false}); return; }
        this.push('rewarded_open',{tag});
        const r = await ad.show();
        if (r && r.reward) this.push('rewarded',{tag});
        this.push('rewarded_close',{tag,wasShown:!!(r && r.rendered)});
      } catch (e) { this.state.lastError='Rewarded: '+String(e); this.push('rewarded_close',{tag,wasShown:false}); }
    },
    async openAuth() {
      try { if (this.sdk && this.sdk.auth && this.sdk.auth.openAuthDialog) await this.sdk.auth.openAuthDialog(); } catch (_) {}
    }
  };
  window.__slovopadPikabu = bridge;
  bridge.init();
})();
"""
