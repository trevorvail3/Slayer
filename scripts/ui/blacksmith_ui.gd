class_name BlacksmithUI
extends Control

## Bruna's forge. Pick any owned item, then spend resources to Upgrade its Power
## or Reforge (re-roll) its affixes. Close with Esc. Mirrors InventoryUI layout.

const STATS := ["might", "vigor", "fortitude", "swiftness", "ferocity"]

var _list: VBoxContainer
var _detail: VBoxContainer
var _cost_note: Label
var _selected: ItemData
var _locked := {}          # affix index -> bool (preserved across reforge)
var _focus_stat := ""      # "" = no focus; else guarantee this stat on reforge

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
	UITheme.style_title(title, 26)
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

## Base emberdust to re-roll, plus one godshard per locked affix and one for a
## focus — locking/focusing is the god-roll targeting, so it costs the premium mat.
func _reforge_cost() -> Dictionary:
	var c := {"emberdust": 4 + int(_selected.power / 6.0)}
	var shards := _locked_indices().size() + (1 if _focus_stat != "" else 0)
	if shards > 0:
		c["godshard"] = shards
	return c

func _cost_text(cost: Dictionary) -> String:
	var parts := []
	for k in cost:
		parts.append("%d %s" % [int(cost[k]), String(k).capitalize()])
	return ", ".join(parts)

func _locked_indices() -> Array:
	var arr := []
	if _selected == null:
		return arr
	for i in _selected.affixes.size():
		if _locked.get(i, false):
			arr.append(i)
	return arr

func _quality_stars(q: float) -> String:
	if q >= 0.85:
		return "★★★"
	if q >= 0.6:
		return "★★"
	if q >= 0.3:
		return "★"
	return "·"

func _quality_color(q: float) -> Color:
	return Color("9a9a9a").lerp(Color("ffd24a"), q)

func _toggle_lock(pressed: bool, idx: int) -> void:
	_locked[idx] = pressed
	_refresh_detail()

func _cycle_focus() -> void:
	var opts := [""]
	opts.append_array(STATS)
	var idx: int = opts.find(_focus_stat)
	_focus_stat = opts[(idx + 1) % opts.size()]
	_refresh_detail()

func _refresh() -> void:
	if _list == null:
		return
	_cost_note.text = "Gold %d    Iron %d    Emberdust %d    Godshard %d" % [
		GameState.gold, GameState.resources.get("iron", 0),
		GameState.resources.get("emberdust", 0), GameState.resources.get("godshard", 0)]

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
	_locked.clear()
	_focus_stat = ""
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

	if LootManager.is_god_roll(_selected):
		var banner := Label.new()
		banner.text = "★  GOD ROLL  ★"
		banner.add_theme_font_size_override("font_size", 20)
		banner.add_theme_color_override("font_color", Color("ffd24a"))
		banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_detail.add_child(banner)

	var up := Button.new()
	var ucost := _upgrade_cost(_selected)
	up.text = "Upgrade  (+5 Power)   —   %d Iron, %d Gold" % [ucost["iron"], ucost["gold"]]
	up.disabled = not GameState.can_afford(ucost)
	up.pressed.connect(_do_upgrade)
	_detail.add_child(up)

	# --- Reforge (god-roll chase): lock keepers, focus a stat, re-roll the rest ---
	var rhead := Label.new()
	rhead.text = "\nREFORGE   —   lock keepers, focus a stat, re-roll the rest"
	rhead.add_theme_font_size_override("font_size", 16)
	rhead.add_theme_color_override("font_color", Color("d9b13b"))
	_detail.add_child(rhead)

	for i in _selected.affixes.size():
		var a: Affix = _selected.affixes[i]
		var q := LootManager.affix_quality(a.value, _selected.power)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var al := Label.new()
		al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		al.text = "%s  %s" % [_quality_stars(q), a.describe()]
		al.add_theme_color_override("font_color", _quality_color(q))
		row.add_child(al)
		var cb := CheckBox.new()
		cb.text = "Lock"
		cb.set_pressed_no_signal(bool(_locked.get(i, false)))
		cb.toggled.connect(_toggle_lock.bind(i))
		row.add_child(cb)
		_detail.add_child(row)

	var focus := Button.new()
	focus.text = "Focus: %s" % ("None" if _focus_stat == "" else _focus_stat.capitalize())
	focus.pressed.connect(_cycle_focus)
	_detail.add_child(focus)

	var rcost := _reforge_cost()
	var rf := Button.new()
	rf.text = "Reforge   —   %s" % _cost_text(rcost)
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
		LootManager.reforge(_selected, _locked_indices(), _focus_stat)
		_focus_stat = ""   # focus is a one-shot guarantee; locks persist for chaining
		GameState.equipment_changed.emit()
		GameState.backpack_changed.emit()
		_refresh_detail()
