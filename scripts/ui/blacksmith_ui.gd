class_name BlacksmithUI
extends Control

## Bruna's forge. Pick any owned item, then spend resources to Upgrade its Power
## or Reforge (re-roll) its affixes. Close with Esc. Mirrors InventoryUI layout.

var _list: VBoxContainer
var _detail: VBoxContainer
var _cost_note: Label
var _selected: ItemData

func _ready() -> void:
	_build()
	visible = false
	GameState.equipment_changed.connect(_refresh)
	GameState.backpack_changed.connect(_refresh)
	GameState.resources_changed.connect(_refresh)

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

func _build() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.02, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 48)
	add_child(margin)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)
	margin.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "THE FORGE  —  Bruna Ironhand   (Esc to leave)"
	title.add_theme_font_size_override("font_size", 26)
	left.add_child(title)
	_cost_note = Label.new()
	_cost_note.add_theme_font_size_override("font_size", 18)
	_cost_note.add_theme_color_override("font_color", Color("d9b13b"))
	left.add_child(_cost_note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	left.add_child(scroll)
	cols.add_child(left)

	_detail = VBoxContainer.new()
	_detail.custom_minimum_size = Vector2(420, 0)
	cols.add_child(_detail)

func _all_items() -> Array:
	var arr := []
	for slot in GameState.equipped:
		arr.append(GameState.equipped[slot])
	arr.append_array(GameState.backpack)
	return arr

func _upgrade_cost(item: ItemData) -> Dictionary:
	return {"iron": 1 + int(item.power / 6.0), "gold": 8 + item.power * 2}

func _reforge_cost() -> Dictionary:
	return {"wood": 5, "iron": 2}

func _refresh() -> void:
	if _list == null:
		return
	_cost_note.text = "Gold %d    Wood %d    Stone %d    Iron %d" % [
		GameState.gold, GameState.resources.get("wood", 0),
		GameState.resources.get("stone", 0), GameState.resources.get("iron", 0)]

	for c in _list.get_children():
		c.queue_free()
	var items := _all_items()
	if not items.has(_selected):
		_selected = null
	for item in items:
		var b := Button.new()
		b.text = "[%s] %s  ·  Pow %d" % [item.rarity.name, item.name, item.power]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", item.display_color())
		b.pressed.connect(_select.bind(item))
		_list.add_child(b)

	_refresh_detail()

func _select(item: ItemData) -> void:
	_selected = item
	_refresh_detail()

func _refresh_detail() -> void:
	for c in _detail.get_children():
		c.queue_free()
	if _selected == null:
		var hint := Label.new()
		hint.text = "\nSelect an item to upgrade or reforge."
		_detail.add_child(hint)
		return

	var head := Label.new()
	head.text = "%s\n[%s] Power %d" % [_selected.name, _selected.rarity.name, _selected.power]
	head.add_theme_font_size_override("font_size", 22)
	head.add_theme_color_override("font_color", _selected.display_color())
	_detail.add_child(head)

	var affix_lbl := Label.new()
	var at := ""
	for a in _selected.affixes:
		at += a.describe() + "\n"
	affix_lbl.text = "\n" + at
	_detail.add_child(affix_lbl)

	var ucost := _upgrade_cost(_selected)
	var up := Button.new()
	up.text = "Upgrade  (+5 Power)   —   %d Iron, %d Gold" % [ucost["iron"], ucost["gold"]]
	up.disabled = not GameState.can_afford(ucost)
	up.pressed.connect(_do_upgrade)
	_detail.add_child(up)

	var rcost := _reforge_cost()
	var rf := Button.new()
	rf.text = "Reforge affixes   —   %d Wood, %d Iron" % [rcost["wood"], rcost["iron"]]
	rf.disabled = not GameState.can_afford(rcost)
	rf.pressed.connect(_do_reforge)
	_detail.add_child(rf)

func _do_upgrade() -> void:
	if _selected == null:
		return
	if GameState.spend(_upgrade_cost(_selected)):
		_selected.power += 5
		GameState.equipment_changed.emit()
		GameState.backpack_changed.emit()

func _do_reforge() -> void:
	if _selected == null:
		return
	if GameState.spend(_reforge_cost()):
		LootManager.reroll_affixes(_selected)
		GameState.equipment_changed.emit()
		GameState.backpack_changed.emit()
