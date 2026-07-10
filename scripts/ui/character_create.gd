class_name CharacterCreateUI
extends Control

## Destiny-style character creation: pick your Order (class) before the world
## begins. Emits `chosen(kind)` when the player confirms, `cancelled` on Back.

signal chosen(kind: int)
signal cancelled

const ORDERS := [ClassDefs.Kind.WARDEN, ClassDefs.Kind.STALKER, ClassDefs.Kind.RUNECASTER]

var _selected: int = ClassDefs.Kind.WARDEN
var _row: HBoxContainer
var _begin_btn: Button

func _ready() -> void:
	_build()

func _build() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 56)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	var title := Label.new()
	title.text = "CHOOSE YOUR ORDER"
	UITheme.style_title(title, 34)
	col.add_child(title)

	var sub := Label.new()
	sub.text = "Vael's Mark takes to each path differently. This choice shapes your abilities."
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	col.add_child(sub)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 22)
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_row)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	col.add_child(footer)
	var back := Button.new()
	back.text = "‹ Back"
	back.pressed.connect(_on_back)
	footer.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_begin_btn = Button.new()
	_begin_btn.custom_minimum_size = Vector2(260, 0)
	_begin_btn.pressed.connect(_on_begin)
	footer.add_child(_begin_btn)

	_refresh()

func _refresh() -> void:
	if _row == null:
		return
	for c in _row.get_children():
		c.queue_free()
	for k in ORDERS:
		_row.add_child(_class_card(k))
	var d := ClassDefs.get_def(_selected)
	_begin_btn.text = "Begin as %s  ›" % d["name"]

func _class_card(k: int) -> Control:
	var d := ClassDefs.get_def(k)
	var chosen_now := k == _selected
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fill: Color = UITheme.PANEL_SOLID if chosen_now else UITheme.PANEL
	var border: Color = UITheme.GOLD if chosen_now else UITheme.BRONZE
	card.add_theme_stylebox_override("panel", UITheme.glass_panel(fill, border))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)

	var name_lbl := Label.new()
	name_lbl.text = String(d["name"]).to_upper()
	UITheme.style_title(name_lbl, 26, d["color"])
	v.add_child(name_lbl)

	var blurb := Label.new()
	blurb.text = String(d["blurb"])
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(300, 0)
	blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blurb.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.add_child(blurb)

	var kit := Label.new()
	kit.text = "Move:  %s\nAbility:  %s\nSuper:  %s" % [d["move_name"], d["ability_name"], d["super_name"]]
	v.add_child(kit)

	var pick := Button.new()
	pick.text = "✓ Selected" if chosen_now else "Select"
	pick.disabled = chosen_now
	pick.pressed.connect(_select.bind(k))
	v.add_child(pick)
	return card

func _select(k: int) -> void:
	_selected = k
	_refresh()

func _on_begin() -> void:
	chosen.emit(_selected)

func _on_back() -> void:
	cancelled.emit()
