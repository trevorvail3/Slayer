class_name UITheme
extends RefCounted

## A shared, code-built Theme so every menu reads as one bronze-age set: parchment
## text, aged-bronze buttons, dark panels. Cached; assign to a Control's `theme`.

static var _theme: Theme

static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18

	# Panels (menu backgrounds)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.06, 0.05, 0.04, 0.94)
	panel.set_border_width_all(2)
	panel.border_color = Color("6a5a3a")
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(12)
	t.set_stylebox("panel", "PanelContainer", panel)

	# Buttons
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color("2a2620")
	btn.set_border_width_all(1)
	btn.border_color = Color("6a5a3a")
	btn.set_corner_radius_all(4)
	btn.set_content_margin_all(7)
	t.set_stylebox("normal", "Button", btn)
	var btn_hover := btn.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color("3a342a")
	btn_hover.border_color = Color("c9a24a")
	t.set_stylebox("hover", "Button", btn_hover)
	var btn_pressed := btn.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color("4a4030")
	t.set_stylebox("pressed", "Button", btn_pressed)
	var btn_disabled := btn.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = Color(0.15, 0.14, 0.12, 0.7)
	btn_disabled.border_color = Color("40382a")
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_color("font_color", "Button", Color("e8dcc0"))
	t.set_color("font_hover_color", "Button", Color("ffe8b0"))
	t.set_color("font_disabled_color", "Button", Color("7a7060"))

	# Labels
	t.set_color("font_color", "Label", Color("e8dcc0"))

	# Progress bars (fill/background)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.09, 0.08, 0.85)
	bar_bg.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", bar_bg)

	_theme = t
	return t
