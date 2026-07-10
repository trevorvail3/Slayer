class_name ClassSelectUI
extends Control

## Choose your class at the Shrine of Paths. Shows the three classes with their
## kit; picking one updates GameState and saves. Close with Esc.

func _ready() -> void:
	_build()
	visible = false
	GameState.class_changed.connect(_refresh)

func open() -> void:
	visible = true
	Game.menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()

func close() -> void:
	visible = false
	Game.menu_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

var _row: HBoxContainer

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.05, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 56)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)

	var title := Label.new()
	title.text = "SHRINE OF PATHS  —  choose your class   (Esc to leave)"
	title.add_theme_font_size_override("font_size", 28)
	col.add_child(title)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 24)
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_row)

func _refresh() -> void:
	if _row == null:
		return
	for c in _row.get_children():
		c.queue_free()
	for k in [ClassDefs.Kind.WARDEN, ClassDefs.Kind.STALKER, ClassDefs.Kind.RUNECASTER]:
		_row.add_child(_class_card(k))

func _class_card(k: int) -> Control:
	var d := ClassDefs.get_def(k)
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 10)

	var name_lbl := Label.new()
	var current := " ✓ (current)" if GameState.player_class == k else ""
	name_lbl.text = String(d["name"]) + current
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", d["color"])
	panel.add_child(name_lbl)

	var blurb := Label.new()
	blurb.text = String(d["blurb"])
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.custom_minimum_size = Vector2(320, 0)
	panel.add_child(blurb)

	var kit := Label.new()
	kit.text = "\nMove:  %s\nAbility:  %s\nSuper:  %s" % [d["move_name"], d["ability_name"], d["super_name"]]
	panel.add_child(kit)

	var btn := Button.new()
	btn.text = "Become %s" % d["name"]
	btn.pressed.connect(_choose.bind(k))
	panel.add_child(btn)
	return panel

func _choose(k: int) -> void:
	GameState.set_class(k)
	SaveManager.save_game()
	close()
