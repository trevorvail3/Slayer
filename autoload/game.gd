extends Node

## Game — global manager. Owns the input map (so every scene shares it), travels
## between the Hub and the Zone, loads the save on boot, and exposes a `menu_open`
## flag so world interactions pause while a full-screen menu is up.

const HUB_SCENE := "res://scenes/hub.tscn"
const ZONE_SCENE := "res://scenes/zone.tscn"

var menu_open := false

func _ready() -> void:
	_setup_input()
	if SaveManager.has_save():
		SaveManager.load_game()

func goto_hub() -> void:
	SaveManager.save_game()
	menu_open = false
	get_tree().change_scene_to_file(HUB_SCENE)

func goto_zone() -> void:
	SaveManager.save_game()
	menu_open = false
	get_tree().change_scene_to_file(ZONE_SCENE)

# --- Input map (code-driven so project.godot stays minimal & robust) ---

func _setup_input() -> void:
	_bind_key("move_forward", KEY_W)
	_bind_key("move_back", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("jump", KEY_SPACE)
	_bind_key("toggle_inventory", KEY_TAB)
	_bind_key("toggle_inventory", KEY_I)
	_bind_key("interact", KEY_E)
	_bind_key("dodge", KEY_SHIFT)
	_bind_key("class_ability", KEY_Q)
	_bind_key("super", KEY_F)
	_bind_mouse("attack", MOUSE_BUTTON_LEFT)
	_bind_mouse("block", MOUSE_BUTTON_RIGHT)

func _ensure_action(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_add_event(action, event)

func _bind_key(action: String, keycode: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	_ensure_action(action, e)

func _bind_mouse(action: String, button: MouseButton) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	_ensure_action(action, e)
