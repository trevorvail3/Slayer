class_name HUD
extends CanvasLayer

## Heads-up display: crosshair, Power Level, a health bar, and a loot toast that
## pops when you pick something up.

var power_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var block_label: Label
var toast: Label
var objective_label: Label
var resource_label: Label
var _toast_timer := 0.0

func _ready() -> void:
	_build()
	GameState.equipment_changed.connect(_refresh)
	GameState.loot_acquired.connect(_on_loot)
	GameState.resources_changed.connect(_refresh_resources)
	_refresh()
	_refresh_resources()

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 28)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position -= Vector2(8, 18)
	root.add_child(cross)

	power_label = Label.new()
	power_label.position = Vector2(20, 18)
	power_label.add_theme_font_size_override("font_size", 24)
	root.add_child(power_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(20, 56)
	health_bar.custom_minimum_size = Vector2(240, 22)
	health_bar.size = Vector2(240, 22)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	root.add_child(health_bar)

	stamina_bar = ProgressBar.new()
	stamina_bar.position = Vector2(20, 84)
	stamina_bar.custom_minimum_size = Vector2(180, 12)
	stamina_bar.size = Vector2(180, 12)
	stamina_bar.max_value = 100
	stamina_bar.value = 100
	stamina_bar.show_percentage = false
	var stam_fill := StyleBoxFlat.new()
	stam_fill.bg_color = Color("d9b13b")
	stamina_bar.add_theme_stylebox_override("fill", stam_fill)
	root.add_child(stamina_bar)

	block_label = Label.new()
	block_label.position = Vector2(20, 100)
	block_label.add_theme_font_size_override("font_size", 18)
	block_label.add_theme_color_override("font_color", Color("7fb0ff"))
	block_label.text = ""
	root.add_child(block_label)

	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.position -= Vector2(180, 90)
	toast.add_theme_font_size_override("font_size", 22)
	root.add_child(toast)

	objective_label = Label.new()
	objective_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective_label.position += Vector2(-180, 20)
	objective_label.add_theme_font_size_override("font_size", 22)
	objective_label.add_theme_color_override("font_color", Color("e6c86a"))
	objective_label.text = ""
	root.add_child(objective_label)

	resource_label = Label.new()
	resource_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	resource_label.position = Vector2(-430, 18)
	resource_label.add_theme_font_size_override("font_size", 18)
	resource_label.add_theme_color_override("font_color", Color("e6d29a"))
	resource_label.text = ""
	root.add_child(resource_label)

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
		resource_label.text = "Gold %d    Wood %d    Stone %d    Iron %d" % [
			GameState.gold, GameState.resources.get("wood", 0),
			GameState.resources.get("stone", 0), GameState.resources.get("iron", 0)]

func _refresh() -> void:
	power_label.text = "POWER  %d" % GameState.gear_score()

func _on_loot(item: ItemData) -> void:
	toast.text = "%s  %s  (Pow %d)" % [item.rarity.name, item.name, item.power]
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
		stamina_bar.max_value = PlayerStats.max_stamina()
		stamina_bar.value = p.stamina
		block_label.text = "◤ BLOCKING" if p.blocking else ""
