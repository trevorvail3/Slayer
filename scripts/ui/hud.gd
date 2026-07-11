class_name HUD
extends CanvasLayer

## Heads-up display, Destiny-style clustered layout:
##  - bottom-left:   vitals (class · POWER, health, stamina)
##  - bottom-center: super meter + ability chips (Move / Ability / Super)
##  - top-center:    objective line + big region-discovery banner
##  - top-right:     currencies & materials (glass panel)
##  - center:        crosshair; a transient loot/notify toast lower-center
## Public API used by hub/zone: notify(), set_objective(), show_region().

var power_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var block_label: Label
var class_label: Label
var super_bar: ProgressBar
var objective_label: Label
var resource_label: Label
var region_box: VBoxContainer
var region_title: Label
var region_sub: Label
var toast: Label

var _hp_label: Label
var _move_chip: Dictionary
var _abil_chip: Dictionary
var _super_chip: Dictionary
var _region_tween: Tween
var _toast_timer := 0.0

func _ready() -> void:
	_build()
	GameState.equipment_changed.connect(_refresh)
	GameState.loot_acquired.connect(_on_loot)
	GameState.resources_changed.connect(_refresh_resources)
	GameState.relic_found.connect(_on_relic)
	_refresh()
	_refresh_resources()

func _on_relic(total: int) -> void:
	notify("Relic recovered!   (%d found)" % total, Color("46e0d0"))

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)

	_build_crosshair(root)
	_build_vitals(root)
	_build_abilities(root)
	_build_top(root)
	_build_resources(root)
	_build_toast(root)

func _build_crosshair(root: Control) -> void:
	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 22)
	cross.modulate = Color(1, 1, 1, 0.55)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-7, -16)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cross)

func _build_vitals(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 22)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var top := HBoxContainer.new()
	v.add_child(top)
	class_label = Label.new()
	UITheme.style_title(class_label, 18, Color("cfc0ff"))
	top.add_child(class_label)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.custom_minimum_size = Vector2(40, 0)
	top.add_child(sp)
	power_label = Label.new()
	UITheme.style_title(power_label, 20, UITheme.GOLD)
	top.add_child(power_label)

	health_bar = _bar(v, Vector2(320, 20), UITheme.HEALTH)
	_hp_label = Label.new()
	_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 13)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline(_hp_label, 3)
	health_bar.add_child(_hp_label)

	stamina_bar = _bar(v, Vector2(320, 8), UITheme.STAMINA)

	block_label = Label.new()
	block_label.text = "◤ BLOCKING"
	block_label.add_theme_font_size_override("font_size", 15)
	block_label.add_theme_color_override("font_color", Color("9fd0ff"))
	block_label.visible = false
	v.add_child(block_label)

func _bar(parent: Control, size: Vector2, fill: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = size
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("fill", UITheme.bar_fill(fill))
	parent.add_child(b)
	return b

func _build_abilities(root: Control) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 22)

	super_bar = ProgressBar.new()
	super_bar.custom_minimum_size = Vector2(380, 8)
	super_bar.max_value = 100
	super_bar.value = 0
	super_bar.show_percentage = false
	super_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	super_bar.add_theme_stylebox_override("fill", UITheme.bar_fill(UITheme.SUPER))
	col.add_child(super_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	_move_chip = _make_chip(row)
	_abil_chip = _make_chip(row)
	_super_chip = _make_chip(row)

func _make_chip(parent: Control) -> Dictionary:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(122, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var nm := Label.new()
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 15)
	v.add_child(nm)
	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.add_child(sub)
	return {"panel": p, "name": nm, "sub": sub}

func _build_top(root: Control) -> void:
	objective_label = Label.new()
	objective_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.offset_top = 22
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_label.add_theme_font_size_override("font_size", 20)
	objective_label.add_theme_color_override("font_color", UITheme.GOLD)
	_outline(objective_label, 4)
	root.add_child(objective_label)

	region_box = VBoxContainer.new()
	region_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	region_box.offset_top = 120
	region_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_box.modulate.a = 0.0
	region_title = Label.new()
	region_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(region_title, 46, UITheme.TEXT)
	_outline(region_title, 5)
	region_box.add_child(region_title)
	region_sub = Label.new()
	region_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_sub.add_theme_font_size_override("font_size", 18)
	region_sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_outline(region_sub, 3)
	region_box.add_child(region_sub)
	root.add_child(region_box)

func _build_resources(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	resource_label = Label.new()
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resource_label.add_theme_font_size_override("font_size", 15)
	resource_label.add_theme_color_override("font_color", Color("e6d29a"))
	resource_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(resource_label)

func _build_toast(root: Control) -> void:
	toast = Label.new()
	toast.anchor_left = 0.0
	toast.anchor_right = 1.0
	toast.anchor_top = 0.62
	toast.anchor_bottom = 0.62
	toast.grow_vertical = Control.GROW_DIRECTION_BOTH
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_font_size_override("font_size", 22)
	_outline(toast, 4)
	root.add_child(toast)

## Dark outline so HUD text stays legible over bright sky/terrain.
func _outline(label: Label, size: int) -> void:
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", size)

## Big fading "area discovered" banner.
func show_region(title: String, sub: String = "") -> void:
	if region_title == null:
		return
	region_title.text = title.to_upper()
	region_sub.text = sub
	if _region_tween and _region_tween.is_valid():
		_region_tween.kill()
	region_box.modulate.a = 0.0
	_region_tween = create_tween()
	_region_tween.tween_property(region_box, "modulate:a", 1.0, 0.45)
	_region_tween.tween_interval(2.4)
	_region_tween.tween_property(region_box, "modulate:a", 0.0, 0.9)

func set_objective(text: String) -> void:
	if objective_label:
		objective_label.text = text

## Generic transient message (reuses the loot toast slot).
func notify(text: String, color := Color(0.9, 0.9, 0.9)) -> void:
	if toast:
		toast.text = text
		toast.add_theme_color_override("font_color", color)
		_toast_timer = 3.0

func _refresh_resources() -> void:
	if resource_label:
		resource_label.text = "%d Gold\nWood %d   Stone %d   Iron %d\nEmber %d   Shard %d   Relics %d" % [
			GameState.gold, GameState.resources.get("wood", 0),
			GameState.resources.get("stone", 0), GameState.resources.get("iron", 0),
			GameState.resources.get("emberdust", 0), GameState.resources.get("godshard", 0),
			GameState.relics_found]

func _refresh() -> void:
	power_label.text = "POWER %d" % GameState.gear_score()

func _on_loot(item: ItemData) -> void:
	toast.text = "%s   %s   (Pow %d)" % [item.rarity.name, item.name, item.power]
	toast.add_theme_color_override("font_color", item.display_color())
	_toast_timer = 3.0

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast.text = ""

	var p := get_tree().get_first_node_in_group("player") as Player
	if p:
		health_bar.max_value = PlayerStats.max_health()
		health_bar.value = p.health
		_hp_label.text = "%d / %d" % [maxi(0, int(p.health)), int(PlayerStats.max_health())]
		stamina_bar.max_value = PlayerStats.max_stamina()
		stamina_bar.value = p.stamina
		block_label.visible = p.blocking
		_update_class_hud(p)

func _update_class_hud(p: Player) -> void:
	var d := ClassDefs.get_def(GameState.player_class)
	class_label.text = String(d["name"]).to_upper()
	super_bar.value = p.super_energy

	_set_chip(_move_chip, String(d["move_name"]), "Shift", p.move_cd, false)
	_set_chip(_abil_chip, String(d["ability_name"]), "Q", p.ability_cd, false)
	var super_ready := p.super_energy >= 100.0
	_set_chip(_super_chip, String(d["super_name"]), "F", 0.0, super_ready)
	_super_chip["sub"].text = "READY [F]" if super_ready else "%d%%" % int(p.super_energy)

## Update one ability chip: name, key/cooldown, and ready/on-cooldown styling.
func _set_chip(chip: Dictionary, name_text: String, key: String, cd: float, ready: bool) -> void:
	var nm: Label = chip["name"]
	var sub: Label = chip["sub"]
	var panel: PanelContainer = chip["panel"]
	nm.text = name_text
	if cd > 0.0:
		sub.text = "%ds" % ceili(cd)
		panel.modulate = Color(1, 1, 1, 0.45)
		nm.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	else:
		sub.text = "[%s]" % key
		panel.modulate = Color(1, 1, 1, 1)
		nm.add_theme_color_override("font_color", UITheme.GOLD if ready else UITheme.TEXT)
