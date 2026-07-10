extends Node3D

## Main — builds the v0.1 test arena and wires up the loop:
## input map, lighting, floor + walls, player, HUD, inventory, and a spawner
## that keeps the arena stocked with monsters to slay.

const ARENA_HALF := 20.0
const MAX_ENEMIES := 4

var player: Player

func _ready() -> void:
	_setup_input()
	_build_environment()
	_build_arena()
	_spawn_player()
	_add_ui()
	_start_spawner()

# --- Input map (built in code so project.godot stays minimal & robust) ---

func _setup_input() -> void:
	_bind_key("move_forward", KEY_W)
	_bind_key("move_back", KEY_S)
	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("jump", KEY_SPACE)
	_bind_key("toggle_inventory", KEY_TAB)
	_bind_key("toggle_inventory", KEY_I)
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

# --- World ---

func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -40, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_arena() -> void:
	_static_box(Vector3(0, -0.5, 0), Vector3(ARENA_HALF * 2, 1, ARENA_HALF * 2), Color("3a3a44"))
	_static_box(Vector3(0, 2, -ARENA_HALF), Vector3(ARENA_HALF * 2, 4, 1), Color("55555f"))
	_static_box(Vector3(0, 2, ARENA_HALF), Vector3(ARENA_HALF * 2, 4, 1), Color("55555f"))
	_static_box(Vector3(-ARENA_HALF, 2, 0), Vector3(1, 4, ARENA_HALF * 2), Color("55555f"))
	_static_box(Vector3(ARENA_HALF, 2, 0), Vector3(1, 4, ARENA_HALF * 2), Color("55555f"))

func _static_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	body.position = pos
	add_child(body)

func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector3(0, 2, 8)
	add_child(player)

func _add_ui() -> void:
	add_child(HUD.new())
	var inv_layer := CanvasLayer.new()
	inv_layer.layer = 2
	inv_layer.add_child(InventoryUI.new())
	add_child(inv_layer)

# --- Enemy spawner ---

func _start_spawner() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_tick_spawn)
	add_child(timer)
	_tick_spawn()

func _tick_spawn() -> void:
	var count := get_tree().get_nodes_in_group("enemy").size()
	while count < MAX_ENEMIES:
		_spawn_enemy()
		count += 1

func _spawn_enemy() -> void:
	var e := Enemy.new()
	e.power = 8 + randi() % 12
	e.max_health = 40 + e.power * 3
	var x := randf_range(-ARENA_HALF + 3.0, ARENA_HALF - 3.0)
	var z := randf_range(-ARENA_HALF + 3.0, ARENA_HALF - 3.0)
	e.position = Vector3(x, 2.0, z)
	add_child(e)
