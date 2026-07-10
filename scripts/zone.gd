extends Node3D

## Zone — the living "Slice Zone". Ambient enemies always roam; an activity
## DIRECTOR rotates through Public Events (Blood Surge) and a World Boss (The
## Colossus), with Relics to collect. Input lives in the Game autoload.

const ARENA_HALF := 40.0

enum Phase { AMBIENT, EVENT, BOSS }

var hud: HUD
var player: Player

var _phase := Phase.AMBIENT
var _phase_timer := 20.0
var _max_enemies := 6
var _power_bonus := 0
var _event_kills := 0
var _event_target := 0
var _event_time := 0.0
var _cycle := 0
var _boss: Enemy = null

func _ready() -> void:
	_build_environment()
	_build_arena()
	_spawn_player()
	_add_ui()
	_spawn_chests()
	_scatter_relics()
	_spawn_return_pad()
	_start_spawner()
	hud.set_objective("Patrol the wilds — an event stirs soon…   ·   pad north returns to town")

# --- Activity director ---

func _process(delta: float) -> void:
	match _phase:
		Phase.AMBIENT:
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_begin_next_activity()
		Phase.EVENT:
			_event_time -= delta
			if _event_time <= 0.0:
				_end_event(false)
			else:
				hud.set_objective("⚔ WARBAND ASSAULT — slay %d/%d   (%s)" % [_event_kills, _event_target, _fmt(_event_time)])
		Phase.BOSS:
			pass   # transition handled by the boss's died signal

func _begin_next_activity() -> void:
	_cycle += 1
	if _cycle % 3 == 0:
		_begin_boss()
	else:
		_begin_event()

func _begin_event() -> void:
	_phase = Phase.EVENT
	_event_kills = 0
	_event_target = 12
	_event_time = 45.0
	_max_enemies = 10
	_power_bonus = 6
	hud.set_objective("⚔ WARBAND ASSAULT — a host descends! Hold the ground!")

func _end_event(success: bool) -> void:
	_phase = Phase.AMBIENT
	_max_enemies = 6
	_power_bonus = 0
	_phase_timer = 25.0
	if success:
		_spawn_reward_chest()
		hud.set_objective("★ Warband broken — spoils dropped near you!")
	else:
		hud.set_objective("The host melts away… ready yourself for the next.")

func _begin_boss() -> void:
	_phase = Phase.BOSS
	_max_enemies = 3
	_power_bonus = 0
	_boss = Enemy.new()
	_boss.is_boss = true
	_boss.world_boss = true
	_boss.power = 34
	_boss.died.connect(_on_boss_died)
	_boss.position = Vector3(0, 5, -ARENA_HALF + 10.0)
	add_child(_boss)
	hud.set_objective("⚠ THE BONE-TITAN WAKES — a bone of the Father walks!")

func _on_boss_died(_enemy: Enemy) -> void:
	_boss = null
	_phase = Phase.AMBIENT
	_max_enemies = 6
	_phase_timer = 30.0
	_spawn_reward_chest()
	GameState.add_relic()   # bonus relic for the kill
	hud.set_objective("★ THE BONE-TITAN FALLS — claim the spoils!")

func _spawn_reward_chest() -> void:
	var chest := Chest.new()
	chest.power = 26
	chest.min_rarity_index = 3   # Legendary+
	chest.rolls = 2
	add_child(chest)
	var pos := player.global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	pos.y = 0.0
	chest.position = pos

func _fmt(t: float) -> String:
	var s := int(max(0.0, t))
	return "%d:%02d" % [s / 60, s % 60]

# --- Spawner ---

func _start_spawner() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.5
	timer.autostart = true
	timer.timeout.connect(_tick_spawn)
	add_child(timer)
	_tick_spawn()

func _tick_spawn() -> void:
	var count := get_tree().get_nodes_in_group("enemy").size()
	while count < _max_enemies:
		_spawn_enemy()
		count += 1

func _spawn_enemy() -> void:
	var e := Enemy.new()
	e.kind = _random_kind()
	e.power = 8 + randi() % 12 + _power_bonus
	e.died.connect(_on_enemy_died)
	e.position = _random_ground_pos(6.0)
	add_child(e)

func _on_enemy_died(_enemy: Enemy) -> void:
	if _phase == Phase.EVENT:
		_event_kills += 1
		if _event_kills >= _event_target:
			_end_event(true)

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
		if player == null or Vector2(x - player.position.x, z - player.position.z).length() > min_from_player:
			return Vector3(x, 3.0, z)
	return Vector3(randf_range(-10, 10), 3.0, randf_range(-10, 10))

# --- Collectibles ---

func _scatter_relics() -> void:
	for p in [Vector3(-18, 0.9, 10), Vector3(22, 0.9, -6), Vector3(-8, 0.9, -24),
			Vector3(30, 0.9, 20), Vector3(-30, 0.9, -16), Vector3(4, 0.9, 28)]:
		var relic := Relic.new()
		add_child(relic)
		relic.position = p

# --- World ---

func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -46, 0)
	light.light_energy = 1.15
	light.light_color = Color("ffe0c0")   # warm key against a cool sky
	light.shadow_enabled = true
	add_child(light)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var skymat := ProceduralSkyMaterial.new()
	skymat.sky_top_color = Color("2a3452")
	skymat.sky_horizon_color = Color("7a6660")
	skymat.ground_horizon_color = Color("3a322e")
	skymat.ground_bottom_color = Color("241f1d")
	sky.sky_material = skymat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.15
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.18
	env.adjustment_contrast = 1.08
	env.fog_enabled = true
	env.fog_light_color = Color("6b5a58")
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_arena() -> void:
	_static_box(Vector3(0, -0.5, 0), Vector3(ARENA_HALF * 2, 1, ARENA_HALF * 2), Color("39412f"))
	_static_box(Vector3(0, 3, -ARENA_HALF), Vector3(ARENA_HALF * 2, 6, 1), Color("4b4b52"))
	_static_box(Vector3(0, 3, ARENA_HALF), Vector3(ARENA_HALF * 2, 6, 1), Color("4b4b52"))
	_static_box(Vector3(-ARENA_HALF, 3, 0), Vector3(1, 6, ARENA_HALF * 2), Color("4b4b52"))
	_static_box(Vector3(ARENA_HALF, 3, 0), Vector3(1, 6, ARENA_HALF * 2), Color("4b4b52"))

	var rocks := [
		Vector3(10, 0, -8), Vector3(-14, 0, 6), Vector3(6, 0, 16), Vector3(-8, 0, -18),
		Vector3(20, 0, 4), Vector3(-22, 0, -10), Vector3(2, 0, -26), Vector3(-4, 0, 24),
		Vector3(26, 0, -20), Vector3(-28, 0, 18),
	]
	for p in rocks:
		var s := 2.0 + fmod(absf(p.x + p.z), 3.0)
		_static_box(p + Vector3(0, s * 0.5, 0), Vector3(s, s, s), Color("5a5348"))

	_platform(Vector3(-16, 0, -16), 8.0, 2.0)
	_platform(Vector3(18, 0, 18), 9.0, 3.0)

func _platform(center: Vector3, size: float, height: float) -> void:
	_static_box(center + Vector3(0, height * 0.5, 0), Vector3(size, height, size), Color("6b6252"))
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
	for p in [Vector3(-12, 0, -6), Vector3(24, 0, -18), Vector3(-26, 0, 20)]:
		var chest := Chest.new()
		chest.power = 18
		add_child(chest)
		chest.position = p

func _spawn_return_pad() -> void:
	var pad := TravelPad.new()
	pad.to_zone = false
	add_child(pad)
	pad.position = Vector3(0, 0, 32)
