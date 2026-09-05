extends "res://scripts/app_runtime.gd"

# Godot 4 compatibility shim.
# `icon_max_width` is a Button theme constant, not a writable Button property.


func _level_card(number: int, title: String, subtitle: String, unlocked: bool) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(380.0, 210.0)
	button.text = "%02d\n%s\n%s" % [number, title, subtitle]
	button.icon = ICON_CHAPTER if unlocked else ICON_LOCK
	button.add_theme_constant_override("icon_max_width", 54)
	button.expand_icon = true
	button.disabled = not unlocked
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_control_font(button, 23, COL_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.61, 0.72, 0.78))
	button.add_theme_stylebox_override("normal", _style_box(Color(0.018, 0.065, 0.125, 0.94), COL_BORDER, 12, true))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.03, 0.11, 0.20, 0.98), Color(0.28, 0.67, 1.0, 0.9), 12, true))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.025, 0.085, 0.16, 1.0), COL_PRIMARY, 12, false))
	button.add_theme_stylebox_override("disabled", _style_box(Color(0.018, 0.045, 0.085, 0.84), Color(0.12, 0.22, 0.35, 0.6), 12, false))
	return button


func _floating_icon_button(icon: Texture2D) -> Button:
	var button: Button = Button.new()
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 30)
	button.size = Vector2(58.0, 58.0)
	button.custom_minimum_size = Vector2(58.0, 58.0)
	button.add_theme_stylebox_override("normal", _style_box(Color(0.015, 0.055, 0.115, 0.96), Color(0.13, 0.43, 0.78, 0.82), 10, true))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.035, 0.11, 0.20, 0.98), Color(0.34, 0.73, 1.0, 0.95), 10, true))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.02, 0.075, 0.14, 1.0), COL_PRIMARY, 10, false))
	return button


func _button(text: String, variant: String, icon: Texture2D = null, height: float = 60.0) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, height)
	button.focus_mode = Control.FOCUS_ALL
	button.icon = icon
	button.add_theme_constant_override("icon_max_width", 26)
	button.expand_icon = true
	button.add_theme_constant_override("h_separation", 14)
	_apply_control_font(button, 20, COL_TEXT)

	if variant == "primary":
		button.add_theme_stylebox_override("normal", _style_box(COL_PRIMARY, Color(0.52, 0.80, 1.0, 0.78), 10, true))
		button.add_theme_stylebox_override("hover", _style_box(COL_PRIMARY_HOVER, Color(0.72, 0.90, 1.0, 0.95), 10, true))
		button.add_theme_stylebox_override("pressed", _style_box(COL_PRIMARY_PRESS, Color(0.35, 0.65, 0.95, 0.9), 10, false))
	elif variant == "ghost":
		button.add_theme_stylebox_override("normal", _style_box(Color(0.015, 0.045, 0.085, 0.40), Color(0.14, 0.25, 0.38, 0.65), 10, false))
		button.add_theme_stylebox_override("hover", _style_box(Color(0.03, 0.08, 0.14, 0.82), Color(0.20, 0.48, 0.75, 0.75), 10, false))
		button.add_theme_stylebox_override("pressed", _style_box(Color(0.02, 0.06, 0.11, 0.95), COL_BORDER, 10, false))
	else:
		button.add_theme_stylebox_override("normal", _style_box(Color(0.025, 0.09, 0.17, 0.96), COL_BORDER, 10, false))
		button.add_theme_stylebox_override("hover", _style_box(Color(0.04, 0.13, 0.23, 0.98), Color(0.28, 0.66, 1.0, 0.88), 10, false))
		button.add_theme_stylebox_override("pressed", _style_box(Color(0.025, 0.075, 0.14, 1.0), COL_PRIMARY, 10, false))

	button.add_theme_stylebox_override("focus", _style_box(Color(0.0, 0.0, 0.0, 0.0), Color(0.55, 0.82, 1.0, 0.9), 10, false))
	return button
