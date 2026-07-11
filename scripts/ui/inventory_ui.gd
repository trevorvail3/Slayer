class_name InventoryUI
extends Control

## Full-screen inventory (toggle with Tab or I). Left column = equipped gear +
## live stats; right column = backpack. Click a backpack item to equip it, or
## Salvage it for materials. Rarity-tinted rows via UIWidgets.

var equipped_box: VBoxContainer
var backpack_box: VBoxContainer
var stats_label: Label

func _ready() -> void:
	_build()
	visible = false
	GameState.equipment_changed.connect(_refresh)
	GameState.backpack_changed.connect(_refresh)
	GameState.resources_changed.connect(_refresh)

func _build() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.035, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 44)
	add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(columns)

	# Left column: equipped + stats
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 16)
	left.custom_minimum_size = Vector2(470, 0)
	columns.add_child(left)

	var eq := UIWidgets.section("EQUIPPED")
	equipped_box = VBoxContainer.new()
	equipped_box.add_theme_constant_override("separation", 6)
	eq["body"].add_child(equipped_box)
	left.add_child(eq["panel"])

	var st := UIWidgets.section("STATS")
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 17)
	st["body"].add_child(stats_label)
	left.add_child(st["panel"])

	# Right column: backpack
	var bp := UIWidgets.section("BACKPACK   —   click to equip  ·  Salvage for materials")
	bp["panel"].size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(bp["panel"])

	var salvage_all := Button.new()
	salvage_all.text = "Salvage all Common / Uncommon"
	salvage_all.pressed.connect(_on_salvage_all_pressed)
	bp["body"].add_child(salvage_all)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	backpack_box = VBoxContainer.new()
	backpack_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backpack_box.add_theme_constant_override("separation", 6)
	scroll.add_child(backpack_box)
	bp["body"].add_child(scroll)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	visible = not visible
	Game.menu_open = visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
	if visible:
		_refresh()

func _refresh() -> void:
	if equipped_box == null:
		return
	for c in equipped_box.get_children():
		c.queue_free()
	for c in backpack_box.get_children():
		c.queue_free()

	for slot in ItemData.Slot.values():
		var slot_name := String(ItemData.Slot.keys()[slot]).capitalize()
		var it: ItemData = GameState.equipped.get(slot)
		if it:
			equipped_box.add_child(UIWidgets.item_display(it, "%s:   " % slot_name))
		else:
			var e := Label.new()
			e.text = "%s:   (empty)" % slot_name
			e.add_theme_color_override("font_color", UITheme.TEXT_DIM)
			equipped_box.add_child(e)

	stats_label.text = "POWER LEVEL   %d\n\nMight %d     Vigor %d     Fortitude %d\nSwiftness %d     Ferocity %d\n\nEmberdust %d     Godshard %d" % [
		GameState.gear_score(),
		GameState.total_stat("might"),
		GameState.total_stat("vigor"),
		GameState.total_stat("fortitude"),
		GameState.total_stat("swiftness"),
		GameState.total_stat("ferocity"),
		GameState.resources.get("emberdust", 0),
		GameState.resources.get("godshard", 0),
	]

	for item in GameState.backpack:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		var b := UIWidgets.item_button(item)
		b.pressed.connect(_on_equip_pressed.bind(item))
		row.add_child(b)
		var sv := Button.new()
		var y := GameState.salvage_yield(item)
		sv.text = "Salvage (+%d)" % int(y.get("emberdust", 0))
		sv.tooltip_text = "Break down for %d Emberdust%s" % [
			int(y.get("emberdust", 0)),
			("" if int(y.get("godshard", 0)) == 0 else ", %d Godshard" % int(y.get("godshard", 0)))]
		sv.pressed.connect(_on_salvage_pressed.bind(item))
		row.add_child(sv)
		backpack_box.add_child(row)

func _on_equip_pressed(item: ItemData) -> void:
	GameState.equip(item)

func _on_salvage_pressed(item: ItemData) -> void:
	GameState.salvage(item)

func _on_salvage_all_pressed() -> void:
	GameState.salvage_all_trash()
