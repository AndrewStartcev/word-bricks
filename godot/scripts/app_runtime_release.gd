extends "res://scripts/app_runtime_ui_polish.gd"

# Final Web release wrapper. The loading artwork is visual only: it must never
# intercept pointer input after the menu appears, even if a Web tween stalls.


func _create_boot_loading() -> Control:
	var overlay: Control = super._create_boot_loading()
	if overlay != null:
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# All descendants created by the loading screen are decorative.
		for child in overlay.get_children():
			if child is Control:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return overlay


func _ready() -> void:
	await super._ready()
	# Hard guarantee for Web/Yandex: no stale fullscreen loading Control survives
	# above the interactive menu.
	var overlay: Node = get_node_or_null("ProductionLoading")
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
