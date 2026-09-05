extends "res://scripts/app_runtime_full.gd"

# Temporary preview helpers for production review:
# - F cycles through locations through their pre-location comic transition;
# - preview transitions never change or save campaign progress;
# - settings no longer exposes intro replay.

var preview_transition_active: bool = false
var preview_unlock_all: bool = false


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

	current_level_id = next_location_id
	current_stage_number = 1
	transition_target_id = next_location_id

	# Forest has no inter-location transition. Cycling back to it previews the
	# original opening comic instead.
	if next_location_id == "forest":
		preview_transition_active = false
		preview_unlock_all = false
		_show_intro(0)
		return

	# Temporarily bypass progression only while the inherited transition screen is
	# being built. No completion flags or save data are changed.
	preview_transition_active = true
	preview_unlock_all = true
	_show_location_transition(next_location_id)
	preview_unlock_all = false


func _is_location_unlocked(location_id: String) -> bool:
	if preview_unlock_all:
		return true
	return super._is_location_unlocked(location_id)


func _finish_location_transition() -> void:
	if preview_transition_active:
		preview_transition_active = false
		preview_unlock_all = false
		transition_target_id = ""
		current_stage_number = 1
		_start_game()
		return
	super._finish_location_transition()


func _show_level_select() -> void:
	preview_transition_active = false
	preview_unlock_all = false
	super._show_level_select()


func _find_button_by_text(root: Node, wanted_text: String) -> Button:
	for child in root.get_children():
		if child is Button and (child as Button).text == wanted_text:
			return child as Button
		var nested: Button = _find_button_by_text(child, wanted_text)
		if nested != null:
			return nested
	return null
