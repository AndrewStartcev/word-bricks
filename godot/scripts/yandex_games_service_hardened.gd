extends "res://scripts/yandex_games_service.gd"

# Production hardening on top of the base Yandex bridge.
# Patches ad callbacks so any SDK error always releases the game flow instead of
# leaving the runtime waiting forever for an onClose callback.


func _ready() -> void:
	super._ready()
	if OS.has_feature("web"):
		_eval(_hardening_patch_source())


func _hardening_patch_source() -> String:
	return """
(() => {
    const bridge = window.__slovopadYandex;
    if (!bridge || bridge.__slovopadHardeningApplied) return;
    bridge.__slovopadHardeningApplied = true;

    bridge.showFullscreenAdv = function() {
        if (!this.ysdk || !this.ysdk.adv) {
            this.push('fullscreen_close', { wasShown: false });
            return;
        }

        let finished = false;
        const finish = (wasShown) => {
            if (finished) return;
            finished = true;
            this.push('fullscreen_close', { wasShown: !!wasShown });
        };

        try {
            this.ysdk.adv.showFullscreenAdv({
                callbacks: {
                    onOpen: () => this.push('fullscreen_open'),
                    onClose: (wasShown) => finish(wasShown),
                    onError: (error) => {
                        this.state.lastError = 'Fullscreen ad: ' + String(error && error.message ? error.message : error);
                        finish(false);
                    }
                }
            });
        } catch (error) {
            this.state.lastError = 'Fullscreen ad: ' + String(error && error.message ? error.message : error);
            finish(false);
        }
    };

    bridge.showRewardedVideo = function(tag) {
        const rewardTag = String(tag || 'reward');
        if (!this.ysdk || !this.ysdk.adv) {
            this.push('rewarded_close', { tag: rewardTag, wasShown: false });
            return;
        }

        let finished = false;
        const finish = (wasShown) => {
            if (finished) return;
            finished = true;
            this.push('rewarded_close', { tag: rewardTag, wasShown: !!wasShown });
        };

        try {
            this.ysdk.adv.showRewardedVideo({
                callbacks: {
                    onOpen: () => this.push('rewarded_open', { tag: rewardTag }),
                    onRewarded: () => this.push('rewarded', { tag: rewardTag }),
                    onClose: (wasShown) => finish(wasShown),
                    onError: (error) => {
                        this.state.lastError = 'Rewarded ad: ' + String(error && error.message ? error.message : error);
                        finish(false);
                    }
                }
            });
        } catch (error) {
            this.state.lastError = 'Rewarded ad: ' + String(error && error.message ? error.message : error);
            finish(false);
        }
    };
})();
"""
