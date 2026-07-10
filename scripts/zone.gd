extends Node3D

## The Reach — the open patrol zone (Cosmodrome-scale). Five named lore regions,
## each with its own terrain, landmarks, power band, and enemy roster; a spawner
## that populates regions near the player; and an activity director that rotates
## Warband Assaults and the Bone-Titan (who always wakes in the Foothills).
## Region entry shows a Destiny-style discovery banner.

const MAP_HALF := 170.0
const TOTAL_ENEMY_CAP := 28
const ACTIVE_REGION_DIST := 130.0
const EVENT_POWER_BONUS := 6
const EVENT_EXTRA_ENEMIES := 6

enum Phase { AMBIENT, EVENT, BOSS }

var hud: HUD
var player: Player
var regions: Array[ZoneRegion] = []

var _phase := Phase.AMBIENT
var _phase_timer := 25.0
var _event_kills := 0
var _event_target := 0
var _event_time := 0.0
var _event_region_id := ""
var _cycle := 0
var _current_region_id := ""

const TITAN_SPAWN := Vector3(-100, 6, -125)

func _ready() -> void:
	_setup_regions()
	_build_environment()
	_build_terrain()
	_build_landmarks()
	_spawn_player()
	_add_ui()
	_scatter_chests()
	_scatter_relics()
	_scatter_resources()
	_spawn_return_pad()
	_start_spawner()
	hud.set_objective("Patrol the Reach — the wilds stir…   ·   waystone pad at the south road")

# =====================================================================
# Regions
# =====================================================================

func _setup_regions() -> void:
	regions = [
		_mk_region("plains", "The Olive Plains", "Contested fields of the poleis",
			Rect2(-170, 40, 340, 130), 8, 14, 7, 0.06, Color("55603a"), [
				{"kind": Enemy.Kind.GRUNT, "name": "Levy Spearman", "color": Color("8a6a3a"), "weight": 50.0},
				{"kind": Enemy.Kind.ARCHER, "name": "Peltast", "color": Color("6a7048"), "weight": 25.0},
				{"kind": Enemy.Kind.BRUTE, "name": "Warband Champion", "color": Color("6e3b2b"), "weight": 15.0},
				{"kind": Enemy.Kind.BEAST, "name": "Plains Wolf", "color": Color("7d7160"), "weight": 10.0},
			]),
		_mk_region("wood", "The Hollow Wood", "The Father's hair grows wild",
			Rect2(-170, -90, 140, 130), 12, 18, 7, 0.08, Color("32402c"), [
				{"kind": Enemy.Kind.BEAST, "name": "Timber Wolf", "color": Color("6b6258"), "weight": 40.0},
				{"kind": Enemy.Kind.BEAST, "name": "Wild Boar", "color": Color("4e3d2e"), "weight": 25.0},
				{"kind": Enemy.Kind.ARCHER, "name": "Feral Hunter", "color": Color("56643e"), "weight": 20.0},
				{"kind": Enemy.Kind.GRUNT, "name": "Outlaw", "color": Color("77543a"), "weight": 15.0},
			]),
		_mk_region("road", "The Broken Road", "The old road to Kaethon",
			Rect2(-30, -90, 200, 130), 14, 20, 8, 0.12, Color("5b5648"), [
				{"kind": Enemy.Kind.GRUNT, "name": "Sellsword", "color": Color("7a5c40"), "weight": 35.0},
				{"kind": Enemy.Kind.ARCHER, "name": "Mercenary Crossbowman", "color": Color("5d5a52"), "weight": 25.0},
				{"kind": Enemy.Kind.BRUTE, "name": "Iron Mercenary", "color": Color("5a4a44"), "weight": 25.0},
				{"kind": Enemy.Kind.BEAST, "name": "War-Hound", "color": Color("4a4038"), "weight": 15.0},
			]),
		_mk_region("barrow", "The Barrowlands", "Where the Palefathers dig",
			Rect2(-30, -170, 200, 80), 18, 26, 8, 0.12, Color("3d4038"), [
				{"kind": Enemy.Kind.GRUNT, "name": "Draugr", "color": Color("b8b4a4"), "weight": 45.0},
				{"kind": Enemy.Kind.BRUTE, "name": "Barrow-Wight", "color": Color("8f9a8a"), "weight": 25.0},
				{"kind": Enemy.Kind.ARCHER, "name": "Bone Archer", "color": Color("c4bfa8"), "weight": 20.0},
				{"kind": Enemy.Kind.GRUNT, "name": "Palefather Acolyte", "color": Color("3f3a45"), "weight": 10.0},
			]),
		_mk_region("foothills", "The Bonereach Foothills", "The bones of the world",
			Rect2(-170, -170, 140, 80), 24, 32, 7, 0.15, Color("56504a"), [
				{"kind": Enemy.Kind.GRUNT, "name": "Ironblood Veteran", "color": Color("715048"), "weight": 30.0},
				{"kind": Enemy.Kind.BRUTE, "name": "Stone-Sworn Brute", "color": Color("6f6a5f"), "weight": 30.0},
				{"kind": Enemy.Kind.ARCHER, "name": "Highland Marksman", "color": Color("5c6152"), "weight": 20.0},
				{"kind": Enemy.Kind.BEAST, "name": "Cave-Lion", "color": Color("a98d5f"), "weight": 20.0},
			]),
	]

func _mk_region(id: String, disp: String, sub: String, rect: Rect2, pmin: int, pmax: int,
		cap: int, elite: float, ground: Color, table: Array) -> ZoneRegion:
	var r := ZoneRegion.new()
	r.id = id
	r.display_name = disp
	r.subtitle = sub
	r.rect = rect
	r.power_min = pmin
	r.power_max = pmax
	r.max_enemies = cap
	r.elite_chance = elite
	r.ground_color = ground
	r.enemy_table = table
	return r

func _region_at(pos: Vector3) -> ZoneRegion:
	for r in regions:
		if r.contains(pos):
			return r
	return null

func _region_by_id(id: String) -> ZoneRegion:
	for r in regions:
		if r.id == id:
			return r
	return null

# =====================================================================
# Director (events + world boss) & region discovery
# =====================================================================

func _process(delta: float) -> void:
	_check_region_banner()
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
				var r := _region_by_id(_event_region_id)
				var where := r.display_name if r else "the Reach"
				hud.set_objective("⚔ WARBAND ASSAULT — %s — slay %d/%d   (%s)" % [where, _event_kills, _event_target, _fmt(_event_time)])
		Phase.BOSS:
			pass   # resolved by the Titan's died signal

func _check_region_banner() -> void:
	if player == null or hud == null:
		return
	var r := _region_at(player.global_position)
	if r and r.id != _current_region_id:
		_current_region_id = r.id
		hud.show_region(r.display_name, r.subtitle)

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
	_event_time = 50.0
	var r := _region_at(player.global_position) if player else null
	_event_region_id = r.id if r else "plains"
	var where := r.display_name if r else "the Olive Plains"
	hud.set_objective("⚔ WARBAND ASSAULT — a host descends on %s!" % where)

func _end_event(success: bool) -> void:
	_phase = Phase.AMBIENT
	_event_region_id = ""
	_phase_timer = 30.0
	if success:
		_spawn_reward_chest(player.global_position, 2, 2, 24)
		hud.set_objective("★ Warband broken — spoils dropped near you!")
	else:
		hud.set_objective("The host melts away… patrol on.")

func _begin_boss() -> void:
	_phase = Phase.BOSS
	var boss := Enemy.new()
	boss.is_boss = true
	boss.world_boss = true
	boss.power = 36
	boss.display_name = "The Bone-Titan"
	boss.died.connect(_on_boss_died)
	boss.position = TITAN_SPAWN
	add_child(boss)
	hud.set_objective("⚠ THE BONE-TITAN WAKES in the Bonereach Foothills — head north-west!")

func _on_boss_died(enemy: Enemy) -> void:
	_phase = Phase.AMBIENT
	_phase_timer = 35.0
	_spawn_reward_chest(enemy.global_position, 3, 2, 30)
	GameState.add_relic()   # a shard of the Father, freed
	hud.set_objective("★ THE BONE-TITAN FALLS — claim the spoils in the Foothills!")

func _spawn_reward_chest(near: Vector3, min_rarity: int, rolls: int, power: int) -> void:
	var chest := Chest.new()
	chest.min_rarity_index = min_rarity
	chest.rolls = rolls
	chest.power = power
	add_child(chest)
	var pos := near + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	pos.y = 0.0
	chest.position = pos

func _fmt(t: float) -> String:
	var s := int(max(0.0, t))
	return "%d:%02d" % [s / 60, s % 60]

# =====================================================================
# Spawner — populates regions near the player
# =====================================================================

func _start_spawner() -> void:
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_tick_spawn)
	add_child(timer)
	_tick_spawn()

func _tick_spawn() -> void:
	if player == null:
		return
	var all := get_tree().get_nodes_in_group("enemy")
	var total := all.size()
	if total >= TOTAL_ENEMY_CAP:
		return
	for r in regions:
		if r.distance_to(player.global_position) > ACTIVE_REGION_DIST:
			continue
		var count := 0
		for n in all:
			var e := n as Enemy
			if e and e.region_id == r.id:
				count += 1
		var cap := r.max_enemies
		if _phase == Phase.EVENT and r.id == _event_region_id:
			cap += EVENT_EXTRA_ENEMIES
		while count < cap and total < TOTAL_ENEMY_CAP:
			_spawn_enemy_in(r)
			count += 1
			total += 1

func _spawn_enemy_in(r: ZoneRegion) -> void:
	var entry := r.pick_enemy()
	var e := Enemy.new()
	e.kind = int(entry["kind"]) as Enemy.Kind
	e.display_name = String(entry["name"])
	e.custom_color = entry["color"] as Color
	e.power = r.roll_power() + (EVENT_POWER_BONUS if _phase == Phase.EVENT and r.id == _event_region_id else 0)
	e.elite = randf() < r.elite_chance
	e.region_id = r.id
	e.died.connect(_on_enemy_died)
	var pos := r.random_point()
	for i in 8:
		if player == null:
			break
		if Vector2(pos.x - player.position.x, pos.z - player.position.z).length() > 18.0:
			break
		pos = r.random_point()
	e.position = pos
	add_child(e)

func _on_enemy_died(_enemy: Enemy) -> void:
	if _phase == Phase.EVENT:
		_event_kills += 1
		if _event_kills >= _event_target:
			_end_event(true)

# =====================================================================
# Environment & terrain
# =====================================================================

func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -46, 0)
	light.light_energy = 1.15
	light.light_color = Color("ffe0c0")
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 120.0
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
	env.fog_density = 0.0035
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_terrain() -> void:
	# One ground plate per region (they tile the map exactly), plus perimeter walls.
	for r in regions:
		var size := Vector3(r.rect.size.x, 1.0, r.rect.size.y)
		var center := r.center() + Vector3(0, -0.5, 0)
		_static_box(center, size, r.ground_color)

	var wall_c := Color("4b4b52")
	_static_box(Vector3(0, 4, -MAP_HALF), Vector3(MAP_HALF * 2, 8, 2), wall_c)
	_static_box(Vector3(0, 4, MAP_HALF), Vector3(MAP_HALF * 2, 8, 2), wall_c)
	_static_box(Vector3(-MAP_HALF, 4, 0), Vector3(2, 8, MAP_HALF * 2), wall_c)
	_static_box(Vector3(MAP_HALF, 4, 0), Vector3(2, 8, MAP_HALF * 2), wall_c)

# =====================================================================
# Landmarks
# =====================================================================

func _build_landmarks() -> void:
	_landmarks_plains()
	_landmarks_wood()
	_landmarks_road()
	_landmarks_barrow()
	_landmarks_foothills()

func _landmarks_plains() -> void:
	# Scattered olive trees, cover rocks, a ruined watchtower, and two warband camps.
	var trees := [Vector3(-120, 0, 120), Vector3(-70, 0, 90), Vector3(-20, 0, 130), Vector3(30, 0, 70),
		Vector3(80, 0, 110), Vector3(130, 0, 80), Vector3(-140, 0, 60), Vector3(100, 0, 150),
		Vector3(-40, 0, 60), Vector3(60, 0, 140), Vector3(150, 0, 120), Vector3(-100, 0, 150)]
	for p in trees:
		_tree(p, Color("4c5a33"))
	for p in [Vector3(-90, 0, 110), Vector3(40, 0, 100), Vector3(120, 0, 60), Vector3(-30, 0, 90), Vector3(90, 0, 75)]:
		var s := 2.0 + fmod(absf(p.x + p.z), 3.0)
		_static_box(p + Vector3(0, s * 0.5, 0), Vector3(s, s, s), Color("6a6252"))
	_watchtower(Vector3(0, 0, 55))
	_camp(Vector3(-110, 0, 75))
	_camp(Vector3(110, 0, 130))

func _landmarks_wood() -> void:
	# Dense forest: many trees, fallen logs, a mossy shrine stone.
	var rng := RandomNumberGenerator.new()
	rng.seed = 733   # deterministic layout
	for i in 52:
		var x := rng.randf_range(-165.0, -38.0)
		var z := rng.randf_range(-85.0, 35.0)
		_tree(Vector3(x, 0, z), Color("2c4426"), rng.randf_range(2.6, 4.2))
	for p in [Vector3(-140, 0, 0), Vector3(-80, 0, -50), Vector3(-60, 0, 20)]:
		var log := _static_box(p + Vector3(0, 0.45, 0), Vector3(5.5, 0.9, 0.9), Color("4a3420"))
		log.rotation_degrees.y = fmod(absf(p.x * 7.0), 180.0)
	_static_box(Vector3(-100, 1.0, -20), Vector3(2.0, 2.0, 2.0), Color("5e6a58"))   # shrine stone

func _landmarks_road() -> void:
	# The paved old road with a broken colonnade and aqueduct arches.
	_static_box(Vector3(70, 0.05, -25), Vector3(180, 0.12, 10), Color("6c6656"))   # road bed
	for i in 8:
		var x := -20.0 + i * 24.0
		var h1 := 4.0 + fmod(float(i) * 2.7, 3.0)
		var h2 := 2.0 + fmod(float(i) * 1.9, 4.0)
		_static_box(Vector3(x, h1 * 0.5, -33), Vector3(1.4, h1, 1.4), Color("7d7566"))
		_static_box(Vector3(x, h2 * 0.5, -17), Vector3(1.4, h2, 1.4), Color("7d7566"))
	# Aqueduct: post + post + lintel, twice.
	for base_x in [30.0, 120.0]:
		_static_box(Vector3(base_x, 3.0, 15), Vector3(2, 6, 2), Color("7d7566"))
		_static_box(Vector3(base_x + 12, 3.0, 15), Vector3(2, 6, 2), Color("7d7566"))
		_static_box(Vector3(base_x + 6, 6.5, 15), Vector3(16, 1.2, 2.4), Color("7d7566"))
	for p in [Vector3(10, 0, -50), Vector3(90, 0, 5), Vector3(150, 0, -60)]:
		_camp(p)
	_ruin(Vector3(60, 0, -70))

func _landmarks_barrow() -> void:
	# Burial mounds, standing stones, and the Palefathers' altar.
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	for i in 13:
		var x := rng.randf_range(-22.0, 162.0)
		var z := rng.randf_range(-162.0, -98.0)
		var s := rng.randf_range(4.0, 7.0)
		_static_box(Vector3(x, 0.7, z), Vector3(s, 1.4, s * 0.75), Color("46503f"))
	for i in 9:
		var x := rng.randf_range(-20.0, 160.0)
		var z := rng.randf_range(-160.0, -100.0)
		var stone := _static_box(Vector3(x, 1.6, z), Vector3(0.8, 3.2, 0.6), Color("b8b4a4"))
		stone.rotation_degrees = Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 180), rng.randf_range(-8, 8))
	# The Ossuary altar — dark stone, cold candle-light.
	_static_box(Vector3(70, 0.8, -130), Vector3(4, 1.6, 3), Color("2e2a33"))
	_add_light(Vector3(70, 3.0, -130), Color("9ab0c8"), 4.0, 14.0)

func _landmarks_foothills() -> void:
	# Rising plateaus, scree, and the great pale ribs of the Father.
	_plateau(Vector3(-120, 0, -110), 34.0, 4.0)
	_plateau(Vector3(-60, 0, -145), 26.0, 6.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 447
	for i in 8:
		var x := rng.randf_range(-160.0, -40.0)
		var z := rng.randf_range(-165.0, -95.0)
		var h := rng.randf_range(7.0, 14.0)
		var spike := _static_box(Vector3(x, h * 0.5, z), Vector3(1.6, h, 1.2), Color("cfc8b0"))
		spike.rotation_degrees = Vector3(rng.randf_range(-14, 14), rng.randf_range(0, 180), rng.randf_range(-14, 14))
	for i in 6:
		var x := rng.randf_range(-160.0, -40.0)
		var z := rng.randf_range(-165.0, -95.0)
		var s := rng.randf_range(2.0, 4.5)
		_static_box(Vector3(x, s * 0.5, z), Vector3(s, s, s), Color("5a5348"))

# --- Landmark helpers ---

func _tree(pos: Vector3, canopy_color: Color, height := 2.8) -> void:
	_static_box(pos + Vector3(0, height * 0.5, 0), Vector3(0.55, height, 0.55), Color("4a3420"))
	_deco_box(pos + Vector3(0, height + 0.9, 0), Vector3(2.4, 2.0, 2.4), canopy_color)

func _watchtower(pos: Vector3) -> void:
	_static_box(pos + Vector3(0, 2.0, 0), Vector3(6, 4, 6), Color("7d7566"))
	_static_box(pos + Vector3(0, 5.5, 0), Vector3(4.6, 3, 4.6), Color("736a5c"))
	_static_box(pos + Vector3(0, 8.0, 0), Vector3(3.4, 2, 3.4), Color("695f52"))

func _ruin(pos: Vector3) -> void:
	_static_box(pos + Vector3(-4, 1.2, 0), Vector3(1, 2.4, 9), Color("7d7566"))
	_static_box(pos + Vector3(4, 0.8, 0), Vector3(1, 1.6, 7), Color("7d7566"))
	_static_box(pos + Vector3(0, 1.0, -4.5), Vector3(7, 2.0, 1), Color("7d7566"))

func _camp(pos: Vector3) -> void:
	_static_box(pos + Vector3(1.6, 0.5, 0.4), Vector3(1, 1, 1), Color("6a4a2a"))
	_static_box(pos + Vector3(-1.4, 0.4, -0.8), Vector3(0.8, 0.8, 0.8), Color("6a4a2a"))
	_static_box(pos + Vector3(0.2, 0.6, -1.8), Vector3(1.2, 1.2, 1.2), Color("77543a"))
	var fire := _deco_box(pos + Vector3(0, 0.25, 0.8), Vector3(0.7, 0.5, 0.7), Color("ff8a3d"), true)
	fire.position.y = 0.25
	_add_light(pos + Vector3(0, 1.2, 0.8), Color("ffb066"), 2.2, 11.0)

func _plateau(center: Vector3, size: float, height: float) -> void:
	_static_box(center + Vector3(0, height * 0.5, 0), Vector3(size, height, size), Color("655d50"))
	var ramp := _static_box(center + Vector3(0, height * 0.5, size * 0.5 + 4.0), Vector3(size * 0.4, 0.5, 9.0), Color("655d50"))
	ramp.rotation_degrees = Vector3(-atan2(height, 9.0) * 180.0 / PI, 0, 0)

func _add_light(pos: Vector3, color: Color, energy: float, dist: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = dist
	l.shadow_enabled = false
	add_child(l)
	l.position = pos

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

## Visual-only box (no collision) — canopies, flames, dressing.
func _deco_box(pos: Vector3, size: Vector3, color: Color, emissive := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.4
	mesh.material_override = mat
	add_child(mesh)
	mesh.position = pos
	return mesh

# =====================================================================
# Player, UI, pickups
# =====================================================================

func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector3(0, 2, 150)
	add_child(player)

func _add_ui() -> void:
	hud = HUD.new()
	add_child(hud)
	var inv_layer := CanvasLayer.new()
	inv_layer.layer = 2
	inv_layer.add_child(InventoryUI.new())
	add_child(inv_layer)

func _scatter_chests() -> void:
	# One or two per region, powered to match its danger. All Uncommon+ (chests
	# are a find, not a faucet).
	var spots := [
		[Vector3(-60, 0, 120), 14], [Vector3(-110, 0, -35), 18], [Vector3(45, 0, -55), 20],
		[Vector3(135, 0, 25), 20], [Vector3(35, 0, -140), 24], [Vector3(140, 0, -120), 24],
		[Vector3(-120, 4.6, -110), 28], [Vector3(-45, 0, -100), 28],
	]
	for s in spots:
		var chest := Chest.new()
		chest.min_rarity_index = 1
		chest.rolls = 1
		chest.power = int(s[1])
		add_child(chest)
		chest.position = s[0] as Vector3

func _scatter_relics() -> void:
	for p in [Vector3(60, 0.9, 120), Vector3(-90, 0.9, 70), Vector3(-120, 0.9, 10),
			Vector3(-70, 0.9, -40), Vector3(60, 0.9, -20), Vector3(130, 0.9, -60),
			Vector3(60, 0.9, -120), Vector3(130, 0.9, -150), Vector3(-60, 6.9, -145),
			Vector3(-140, 0.9, -130)]:
		var relic := Relic.new()
		add_child(relic)
		relic.position = p

func _scatter_resources() -> void:
	# The wilds hold materials too — wood in the forest, stone/iron in the hills.
	for p in [Vector3(-55, 0, 0), Vector3(-120, 0, 25), Vector3(-150, 0, -60)]:
		_add_node(ResourceNode.Kind.TREE, p)
	for p in [Vector3(-70, 0, -120), Vector3(-140, 0, -100)]:
		_add_node(ResourceNode.Kind.ROCK, p)
	for p in [Vector3(-100, 0, -155), Vector3(-45, 0, -125), Vector3(100, 0, -110)]:
		_add_node(ResourceNode.Kind.ORE, p)

func _add_node(kind: ResourceNode.Kind, pos: Vector3) -> void:
	var node := ResourceNode.new()
	node.kind = kind
	add_child(node)
	node.position = pos

func _spawn_return_pad() -> void:
	var pad := TravelPad.new()
	pad.to_zone = false
	add_child(pad)
	pad.position = Vector3(0, 0, 160)
