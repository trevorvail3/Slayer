class_name VaultUI
extends Control

## Keeper Aldous's vault. Move items between your Backpack and the Vault (stash)
## to free up space. Close with Esc.

var _backpack_box: VBoxContainer
var _stash_box: VBoxContainer

func _ready() -> void:
	_build()
	visible = false
	GameState.backpack_changed.connect(_refresh)
	GameState.equipment_changed.connect(_refresh)

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
	bg.color = Color(0.02, 0.03, 0.05, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 48)
	add_child(margin)

	var root := VBoxContainer.new()
	margin.add_child(root)
	var title := Label.new()
	title.text = "THE VAULT  —  Keeper Aldous   (Esc to leave)"
	UITheme.style_title(title, 26)
	root.add_child(title)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	_backpack_box = _make_column(cols, "BACKPACK  →  store")
	_stash_box = _make_column(cols, "VAULT  →  withdraw")

func _make_column(parent: HBoxContainer, heading: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := Label.new()
	h.text = heading
	h.add_theme_font_size_override("font_size", 22)
	col.add_child(h)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	col.add_child(scroll)
	parent.add_child(col)
	return box

func _refresh() -> void:
	if _backpack_box == null:
		return
	for c in _backpack_box.get_children():
		c.queue_free()
	for c in _stash_box.get_children():
		c.queue_free()

	for item in GameState.backpack:
		_backpack_box.add_child(_item_button(item, true))
	for item in GameState.stash:
		_stash_box.add_child(_item_button(item, false))

func _item_button(item: ItemData, in_backpack: bool) -> Button:
	var b := Button.new()
	b.text = "[%s] %s  ·  Pow %d" % [item.rarity.name, item.name, item.power]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_color_override("font_color", item.display_color())
	if in_backpack:
		b.pressed.connect(_store.bind(item))
	else:
		b.pressed.connect(_withdraw.bind(item))
	return b

func _store(item: ItemData) -> void:
	GameState.move_to_stash(item)
	_refresh()

func _withdraw(item: ItemData) -> void:
	GameState.move_from_stash(item)
	_refresh()
