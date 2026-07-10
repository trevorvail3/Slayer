class_name UITheme
extends RefCounted

## Shared, code-built Theme + palette so every screen reads as one set:
## "Destiny dark-glass + bronze" — dark translucent panels, aged-bronze trim that
## lights to gold on focus, warm parchment text. Cached; assign to a Control.theme.
## Scripts also read the color constants below so HUD/menus stay consistent.

# --- Palette (scripts reference these directly) ---
const BG_DEEP := Color(0.035, 0.04, 0.055, 1.0)     # behind everything
const PANEL := Color(0.07, 0.08, 0.10, 0.90)        # glass panel fill
const PANEL_SOLID := Color(0.06, 0.065, 0.085, 0.97)
const PANEL_INNER := Color(0.10, 0.11, 0.135, 0.92) # buttons / inset rows
const BRONZE := Color("7a5f36")                     # resting trim
const BRONZE_LIT := Color("caa24c")                 # hover/active trim
const GOLD := Color("f0c860")                       # accent / headings
const TEXT := Color("e8dcc0")                       # primary text
const TEXT_DIM := Color("9a927e")                   # secondary text
const DANGER := Color("d0574a")
const HEALTH := Color("d0574a")
const STAMINA := Color("d9b13b")
const SUPER := Color("ffcf6a")

static var _theme: Theme

static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 16

	# Panels (menu backgrounds / cards)
	var panel := _glass(PANEL, BRONZE, 2, 8, 14)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	# Buttons — dark glass that lights to gold on hover/focus
	var btn := _glass(PANEL_INNER, BRONZE, 1, 5, 9)
	t.set_stylebox("normal", "Button", btn)
	var btn_hover := _glass(Color(0.15, 0.15, 0.16, 0.95), BRONZE_LIT, 1, 5, 9)
	t.set_stylebox("hover", "Button", btn_hover)
	var btn_focus := _glass(Color(0.13, 0.13, 0.15, 0.95), BRONZE_LIT, 2, 5, 9)
	t.set_stylebox("focus", "Button", btn_focus)
	var btn_pressed := _glass(Color(0.20, 0.17, 0.10, 0.98), GOLD, 1, 5, 9)
	t.set_stylebox("pressed", "Button", btn_pressed)
	var btn_disabled := _glass(Color(0.09, 0.09, 0.10, 0.6), Color("3a352a"), 1, 5, 9)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("6f6858"))

	# Labels / checkboxes
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", GOLD)

	# Progress bars
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.02, 0.02, 0.03, 0.9)
	bar_bg.set_border_width_all(1)
	bar_bg.border_color = Color(0, 0, 0, 0.6)
	bar_bg.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", bar_bg)

	_theme = t
	return t

## A reusable dark-glass StyleBoxFlat with a bronze border.
static func _glass(fill: Color, border: Color, border_w: int, radius: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_border_width_all(border_w)
	s.border_color = border
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s

## Convenience for scripts that want a glass panel background node.
static func glass_panel(fill := PANEL, border := BRONZE) -> StyleBoxFlat:
	return _glass(fill, border, 2, 8, 14)

## A colored fill stylebox for a ProgressBar (health/stamina/super, etc.).
static func bar_fill(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(3)
	return s
