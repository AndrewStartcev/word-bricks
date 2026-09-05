extends "res://scripts/app_runtime_full.gd"

# Temporary preview helpers for production review:
# - F cycles through all locations without changing campaign progress;
# - settings no longer exposes intro replay.


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
			_unlock_app_audio()
			_debug_cycle_location()
			get_viewport().set_input_as_handled()
			return

	super._input(event)


func _show_settings_modal(from_game: bool) -> void:
	super._show_settings_modal(from_game)

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


func _debug_cycle_location() -> void:
	var order: Array = LEVEL_CATALOG.LOCATION_ORDER
	if order.is_empty():
		return

	var current_index: int = order.find(current_level_id)
	if current_index < 0:
		current_index = 0
	var next_index: int = (current_index + 1) % order.size()
	var next_location_id: String = String(order[next_index])

	# Preview only: do not unlock, complete or save anything.
	# Jump straight into level 1 so backgrounds/UI can be reviewed quickly.
	current_level_id = next_location_id
	current_stage_number = 1
	transition_target_id = ""
	_start_game()


func _find_button_by_text(root: Node, wanted_text: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == wanted_text:
			return child as Button
		var nested: Button = _find_button_by_text(child, wanted_text)
		if nested != null:
			return nested
	return null
