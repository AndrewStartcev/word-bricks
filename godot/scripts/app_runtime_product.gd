extends "res://scripts/app_runtime_yandex.gd"

# Product-level runtime layer.
# Keeps release UI decisions separate from the Yandex platform adapter so the
# upcoming production asset pass can live here without polluting SDK code.


func _show_settings_modal(from_game: bool) -> void:
	super._show_settings_modal(from_game)

	# Intro replay was a development convenience. The release settings only keep
	# audio controls and progress reset.
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


func _find_button_by_text(root: Node, wanted_text: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == wanted_text:
			return child as Button
		var nested: Button = _find_button_by_text(child, wanted_text)
		if nested != null:
			return nested
	return null
