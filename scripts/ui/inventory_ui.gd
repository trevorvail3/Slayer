class_name InventoryUI
extends Control

## Full-screen inventory (toggle with Tab or I). Left column = equipped gear +
## live stats; right column = backpack. Click a backpack item to equip it and
## watch Power update instantly.

var equipped_box: VBoxContainer
var backpack_box: VBoxContainer
var stats_label: Label

func _ready() -> void:
	_build()
	visible = false
	GameState.equipment_changed.connect(_refresh)
	GameState.backpack_changed.connect(_refresh)

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 48)
	add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	margin.add_child(columns)

	# Left: equipped + stats
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(420, 0)
	var left_title := Label.new()
	left_title.text = "EQUIPPED"
	left_title.add_theme_font_size_override("font_size", 26)
	left.add_child(left_title)
	equipped_box = VBoxContainer.new()
	left.add_child(equipped_box)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 18)
	left.add_child(stats_label)
	columns.add_child(left)

	# Right: backpack (scrollable)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right_title := Label.new()
	right_title.text = "BACKPACK  —  click to equip"
	right_title.add_theme_font_size_override("font_size", 26)
	right.add_child(right_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	backpack_box = VBoxContainer.new()
	backpack_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(backpack_box)
	right.add_child(scroll)
	columns.add_child(right)

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
		var label := Label.new()
		var it: ItemData = GameState.equipped.get(slot)
		var slot_name := String(ItemData.Slot.keys()[slot]).capitalize()
		if it:
			label.text = "%s: [%s] %s%s  ·  Pow %d" % [slot_name, it.rarity.name, it.name, _wtype_suffix(it), it.power]
			label.add_theme_color_override("font_color", it.display_color())
		else:
			label.text = "%s: (empty)" % slot_name
		equipped_box.add_child(label)

	stats_label.text = "\nPOWER LEVEL:  %d\n\nMight %d    Vigor %d    Fortitude %d\nSwiftness %d    Ferocity %d" % [
		GameState.gear_score(),
		GameState.total_stat("might"),
		GameState.total_stat("vigor"),
		GameState.total_stat("fortitude"),
		GameState.total_stat("swiftness"),
		GameState.total_stat("ferocity"),
	]

	for item in GameState.backpack:
		var b := Button.new()
		var affix_txt := ""
		for a in item.affixes:
			affix_txt += "  " + a.describe()
		b.text = "[%s] %s%s  ·  Pow %d %s" % [item.rarity.name, item.name, _wtype_suffix(item), item.power, affix_txt]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", item.display_color())
		b.pressed.connect(_on_equip_pressed.bind(item))
		backpack_box.add_child(b)

func _wtype_suffix(item: ItemData) -> String:
	if item.slot == ItemData.Slot.WEAPON and item.weapon_type != ItemData.WeaponType.NONE:
		return "  (%s)" % item.weapon_type_name()
	return ""

func _on_equip_pressed(item: ItemData) -> void:
	GameState.equip(item)
