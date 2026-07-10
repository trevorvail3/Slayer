extends Node3D

## Main — builds the v0.3 "Slice Zone" and runs the activity loop:
## input map, lighting, a larger arena with cover + ramps, mixed-archetype enemy
## spawns, loot chests, and the Warlord objective (cull the horde -> boss -> clear).

const ARENA_HALF := 40.0
const MAX_ENEMIES := 6
const KILLS_FOR_BOSS := 10

var hud: HUD
var player: Player

var _kills := 0
var _boss_spawned := false
var _boss_active := false
var _zone_cleared := false

func _ready() -> void:
	_setup_input()
	_build_environment()
	_build_arena()
	_spawn_player()
	_add_ui()
	_spawn_chests()
	_start_spawner()
	_update_objective()

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
	env.fog_enabled = true
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_arena() -> void:
	# Ground + boundary walls.
	_static_box(Vector3(0, -0.5, 0), Vector3(ARENA_HALF * 2, 1, ARENA_HALF * 2), Color("39412f"))
	_static_box(Vector3(0, 3, -ARENA_HALF), Vector3(ARENA_HALF * 2, 6, 1), Color("4b4b52"))
	_static_box(Vector3(0, 3, ARENA_HALF), Vector3(ARENA_HALF * 2, 6, 1), Color("4b4b52"))
	_static_box(Vector3(-ARENA_HALF, 3, 0), Vector3(1, 6, ARENA_HALF * 2), Color("4b4b52"))
	_static_box(Vector3(ARENA_HALF, 3, 0), Vector3(1, 6, ARENA_HALF * 2), Color("4b4b52"))

	# Scattered rock cover (deterministic-ish layout via fixed offsets).
	var rocks := [
		Vector3(10, 0, -8), Vector3(-14, 0, 6), Vector3(6, 0, 16), Vector3(-8, 0, -18),
		Vector3(20, 0, 4), Vector3(-22, 0, -10), Vector3(2, 0, -26), Vector3(-4, 0, 24),
		Vector3(26, 0, -20), Vector3(-28, 0, 18),
	]
	for p in rocks:
		var s := 2.0 + fmod(absf(p.x + p.z), 3.0)
		_static_box(p + Vector3(0, s * 0.5, 0), Vector3(s, s, s), Color("5a5348"))

	# A couple of low platforms with ramps for verticality.
	_platform(Vector3(-16, 0, -16), 8.0, 2.0)
	_platform(Vector3(18, 0, 18), 9.0, 3.0)

func _platform(center: Vector3, size: float, height: float) -> void:
	_static_box(center + Vector3(0, height * 0.5, 0), Vector3(size, height, size), Color("6b6252"))
	# Ramp up to it.
	var ramp := _static_box(center + Vector3(0, height * 0.5, size * 0.5 + 2.0), Vector3(size * 0.6, 0.4, 5.0), Color("6b6252"))
	ramp.rotation_degrees = Vector3(-atan2(height, 5.0) * 180.0 / PI, 0, 0)

func _static_box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
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
	return body

func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector3(0, 2, 12)
	add_child(player)

func _add_ui() -> void:
	hud = HUD.new()
	add_child(hud)
	var inv_layer := CanvasLayer.new()
	inv_layer.layer = 2
	inv_layer.add_child(InventoryUI.new())
	add_child(inv_layer)

func _spawn_chests() -> void:
	# All on open ground so loot is never gated behind terrain.
	for p in [Vector3(-12, 0, -6), Vector3(24, 0, -18), Vector3(-26, 0, 20)]:
		var chest := Chest.new()
		chest.power = 18
		add_child(chest)
		chest.position = p

# --- Enemy spawner + objective ---

func _start_spawner() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.5
	timer.autostart = true
	timer.timeout.connect(_tick_spawn)
	add_child(timer)
	_tick_spawn()

func _tick_spawn() -> void:
	if _boss_active or _zone_cleared:
		return
	var count := get_tree().get_nodes_in_group("enemy").size()
	while count < MAX_ENEMIES:
		_spawn_enemy()
		count += 1

func _spawn_enemy() -> void:
	var e := Enemy.new()
	e.kind = _random_kind()
	e.power = 8 + randi() % 12
	e.died.connect(_on_enemy_died)
	var pos := _random_ground_pos(6.0)
	e.position = pos
	add_child(e)

func _random_kind() -> Enemy.Kind:
	var r := randf()
	if r < 0.60:
		return Enemy.Kind.GRUNT
	elif r < 0.82:
		return Enemy.Kind.ARCHER
	else:
		return Enemy.Kind.BRUTE

func _random_ground_pos(min_from_player: float) -> Vector3:
	for i in 12:
		var x := randf_range(-ARENA_HALF + 4.0, ARENA_HALF - 4.0)
		var z := randf_range(-ARENA_HALF + 4.0, ARENA_HALF - 4.0)
		var p := Vector3(x, 3.0, z)
		if player == null or Vector2(x - player.position.x, z - player.position.z).length() > min_from_player:
			return p
	return Vector3(randf_range(-10, 10), 3.0, randf_range(-10, 10))

func _on_enemy_died(_enemy: Enemy) -> void:
	if _zone_cleared:
		return
	_kills += 1
	if not _boss_spawned and _kills >= KILLS_FOR_BOSS:
		_spawn_boss()
	_update_objective()

func _spawn_boss() -> void:
	_boss_spawned = true
	_boss_active = true
	var boss := Enemy.new()
	boss.kind = Enemy.Kind.BRUTE
	boss.is_boss = true
	boss.power = 28
	boss.died.connect(_on_boss_died)
	boss.position = Vector3(0, 4, -ARENA_HALF + 8.0)
	add_child(boss)
	_update_objective()

func _on_boss_died(_enemy: Enemy) -> void:
	_boss_active = false
	_zone_cleared = true
	_update_objective()

func _update_objective() -> void:
	if hud == null:
		return
	if _zone_cleared:
		hud.set_objective("★ ZONE CLEARED — the Warlord has fallen! ★")
	elif _boss_active:
		hud.set_objective("⚔ SLAY THE WARLORD ⚔")
	else:
		hud.set_objective("Cull the horde:  %d / %d" % [mini(_kills, KILLS_FOR_BOSS), KILLS_FOR_BOSS])
