class_name Enemy
extends CharacterBody3D

## A foe of the Reach. Four archetypes:
##  - GRUNT: balanced melee (levies, draugr, sellswords...)
##  - BRUTE: slow, huge HP, heavy hits, resists knockback (champions, wights)
##  - ARCHER: keeps distance and fires projectiles (peltasts, bone archers)
##  - BEAST: fast quadruped that lunges (wolves, boars, cave-lions)
## Spawners can reskin any archetype (display_name + custom_color) and roll ELITES
## (◆ named, bigger, tougher, guaranteed loot). Enemies WANDER near their spawn
## until the player enters aggro range or damages them, then chase; they leash
## back if the player escapes. Telegraphed wind-ups, stagger/parry, knockback,
## bleed, procedural rig animation, and a death topple.

signal died(enemy: Enemy)

enum Kind { GRUNT, BRUTE, ARCHER, BEAST }

@export var kind: Kind = Kind.GRUNT
@export var power := 10
@export var is_boss := false
@export var world_boss := false
@export var elite := false
@export var display_name := ""
@export var custom_color := Color(0, 0, 0, 0)   # alpha 0 = use archetype default

var region_id := ""   # set by the zone spawner; used for per-region population caps

const GRAVITY := 20.0
const CONTACT_RANGE := 2.0
const ARCHER_KEEP_DIST := 9.0
const ARCHER_MAX_RANGE := 18.0
const KNOCKBACK_DECAY := 22.0
const DEAGGRO_MULT := 2.0
const WANDER_SPEED_FRAC := 0.35

## Optional downloaded model per archetype: beasts try the Fox first and fall
## back to the procedural box-rig if the file isn't present. Auto-fitted in code.
const BEAST_MODEL_PATH := "res://assets/models/Fox.glb"
## If a loaded creature faces away from where it's moving, flip this to PI.
const MODEL_FACE_YAW := 0.0

var health: int
var max_health: int
var loot_table: LootTable

# Per-archetype config (filled by _configure).
var move_speed := 3.0
var contact_damage := 15
var windup_time := 0.45
var attack_cooldown := 1.4
var knockback_force := 7.0
var knockback_resist := 0.0     # 0 = full knockback, 1 = immune
var is_ranged := false
var body_scale := 1.0
var base_color := Color("8a6a3a")
var aggro_range := 22.0
var drop_chance := 0.12         # most kills drop nothing — loot is scarce

var _mat: StandardMaterial3D
var _bar: HealthBar3D
var _body: Node3D
var _head: MeshInstance3D
var _l_arm: Node3D
var _r_arm: Node3D
var _l_leg: Node3D
var _r_leg: Node3D
var _legs: Array = []           # beast legs: [fl, fr, bl, br]
var _model: Node3D              # loaded .glb creature (null = using box-rig)
var _anim: AnimationPlayer      # its AnimationPlayer, if any
var _use_model := false
var _anim_t := 0.0
var _walk_phase := 0.0
var _attack_cd := 0.0
var _windup_t := 0.0
var _stagger_t := 0.0
var _knockback := Vector3.ZERO
var _bleed_ticks := 0
var _bleed_dmg := 0
var _bleed_timer := 0.0
var _dead := false
var _aggro := false
var _home := Vector3.ZERO
var _wander_target := Vector3.ZERO
var _wander_wait := 0.0

const WINDUP_COLOR := Color("e6b422")
const STAGGER_COLOR := Color("3f6fb0")
const FLASH_COLOR := Color.WHITE

func _ready() -> void:
	add_to_group("enemy")
	_configure()
	health = max_health
	_build()
	_home = global_position
	_wander_target = _home

func _configure() -> void:
	match kind:
		Kind.BRUTE:
			max_health = 80 + power * 6
			move_speed = 2.0
			contact_damage = 12 + power * 2
			windup_time = 0.6
			attack_cooldown = 1.8
			knockback_resist = 0.6
			base_color = Color("6e3b2b")   # iron-blooded champion
			body_scale = 1.5
			aggro_range = 20.0
		Kind.ARCHER:
			max_health = 22 + power * 2
			move_speed = 3.2
			contact_damage = 6 + power
			windup_time = 0.5
			attack_cooldown = 2.0
			is_ranged = true
			base_color = Color("6a7048")   # olive-cloaked skirmisher
			body_scale = 0.95
			aggro_range = 26.0
		Kind.BEAST:
			max_health = 18 + power * 2
			move_speed = 5.0
			contact_damage = 4 + power
			windup_time = 0.28
			attack_cooldown = 1.1
			knockback_force = 8.0
			base_color = Color("7d7160")
			body_scale = 0.9
			aggro_range = 30.0
		_:
			max_health = 30 + power * 3
			move_speed = 3.0
			contact_damage = 5 + power
			base_color = Color("8a6a3a")   # bronze-and-leather levy
			aggro_range = 22.0

	if is_boss:
		max_health = 600 + power * 12
		contact_damage = 20 + power * 2
		move_speed = 2.4
		windup_time = 0.7
		attack_cooldown = 1.6
		knockback_resist = 0.9
		body_scale = 2.3
		base_color = Color("b89040")   # a bronze-crowned war-king
		aggro_range = 60.0

	if world_boss:
		max_health = 1600 + power * 20
		contact_damage = 26 + power * 2
		move_speed = 2.2
		knockback_resist = 0.95
		body_scale = 3.2
		base_color = Color("cfc8b0")   # the Bone-Titan: pale stone and marrow
		aggro_range = 70.0

	if elite and not (is_boss or world_boss):
		max_health = int(max_health * 2.2)
		contact_damage = int(contact_damage * 1.4)
		body_scale *= 1.25
		move_speed *= 1.05

	if custom_color.a > 0.0:
		base_color = custom_color

# --- Rig construction ---

func _build() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = base_color
	_mat.roughness = 0.85
	_mat.rim_enabled = true
	_mat.rim = 0.5
	_mat.next_pass = Toon.outline(0.03 * body_scale)

	_body = Node3D.new()
	add_child(_body)
	if kind == Kind.BEAST:
		if not _build_beast_model(body_scale):
			_build_beast(body_scale)
	else:
		_build_humanoid(body_scale)

	var h := (1.5 if kind == Kind.BEAST else 2.2) * body_scale
	var r := (0.5 if kind == Kind.BEAST else 0.6) * body_scale
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = h
	shape.radius = r
	col.shape = shape
	col.position = Vector3(0, h * 0.5, 0)
	add_child(col)

	var bar_y := (1.6 if kind == Kind.BEAST else 2.45) * body_scale
	_bar = HealthBar3D.new()
	_bar.position = Vector3(0, bar_y + 0.2, 0)
	if is_boss or world_boss:
		_bar.scale = Vector3(2.2, 2.2, 1.0)
	add_child(_bar)
	_bar.set_ratio(1.0)

	if elite or is_boss or world_boss:
		_add_name_label(bar_y)

func _build_humanoid(s: float) -> void:
	_body.add_child(_part(Vector3(0.62, 0.78, 0.36) * s, Vector3(0, 1.35, 0) * s))   # torso
	_body.add_child(_part(Vector3(0.72, 0.20, 0.42) * s, Vector3(0, 1.74, 0) * s))   # shoulders
	_head = _part(Vector3(0.34, 0.34, 0.34) * s, Vector3(0, 1.98, 0) * s)
	_body.add_child(_head)
	_l_arm = _limb(Vector3(-0.45, 1.66, 0) * s, Vector3(0.18, 0.74, 0.18) * s)
	_r_arm = _limb(Vector3(0.45, 1.66, 0) * s, Vector3(0.18, 0.74, 0.18) * s)
	_body.add_child(_l_arm)
	_body.add_child(_r_arm)
	_l_leg = _limb(Vector3(-0.19, 1.0, 0) * s, Vector3(0.24, 1.0, 0.24) * s)
	_r_leg = _limb(Vector3(0.19, 1.0, 0) * s, Vector3(0.24, 1.0, 0.24) * s)
	_body.add_child(_l_leg)
	_body.add_child(_r_leg)
	_add_prop(s)

func _build_beast(s: float) -> void:
	# Quadruped: long body along +Z (facing direction), head at the front.
	_body.add_child(_part(Vector3(0.5, 0.5, 1.1) * s, Vector3(0, 0.75, 0) * s))      # torso
	_head = _part(Vector3(0.3, 0.3, 0.4) * s, Vector3(0, 0.9, 0.7) * s)
	_body.add_child(_head)
	_body.add_child(_part(Vector3(0.09, 0.09, 0.45) * s, Vector3(0, 0.85, -0.7) * s)) # tail
	_legs = [
		_limb(Vector3(-0.2, 0.75, 0.4) * s, Vector3(0.13, 0.7, 0.13) * s),   # front-left
		_limb(Vector3(0.2, 0.75, 0.4) * s, Vector3(0.13, 0.7, 0.13) * s),    # front-right
		_limb(Vector3(-0.2, 0.75, -0.4) * s, Vector3(0.13, 0.7, 0.13) * s),  # back-left
		_limb(Vector3(0.2, 0.75, -0.4) * s, Vector3(0.13, 0.7, 0.13) * s),   # back-right
	]
	for l in _legs:
		_body.add_child(l)

## Try to build the beast from a real downloaded model (auto-fitted + animated).
## Returns false if no model file is present, so the caller falls back to boxes.
func _build_beast_model(s: float) -> bool:
	var inst := AssetLoader.instance_model(BEAST_MODEL_PATH)
	if inst == null:
		return false
	_body.add_child(inst)
	AssetLoader.fit_to_size(inst, 2.4 * s)   # longest dimension ~ beast length
	inst.rotation.y = MODEL_FACE_YAW
	_model = inst
	_anim = AssetLoader.find_anim_player(inst)
	AssetLoader.set_all_loop(_anim)
	AssetLoader.play_anim(_anim, ["survey", "idle"])
	_use_model = true
	return true

func _part(size: Vector3, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	m.material_override = _mat
	m.position = pos
	return m

## A limb: a pivot Node3D at the joint with a box hanging down, so rotating the
## pivot about X swings the limb from the shoulder/hip.
func _limb(joint: Vector3, size: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	m.material_override = _mat
	m.position = Vector3(0, -size.y * 0.5, 0)
	pivot.add_child(m)
	return pivot

func _add_prop(s: float) -> void:
	var prop := MeshInstance3D.new()
	var box := BoxMesh.new()
	var pmat := StandardMaterial3D.new()
	pmat.rim_enabled = true
	match kind:
		Kind.BRUTE:
			box.size = Vector3(0.18, 0.18, 0.95) * s
			pmat.albedo_color = Color("6a4a2a")
		Kind.ARCHER:
			box.size = Vector3(0.06, 0.95, 0.06) * s
			pmat.albedo_color = Color("8a5a32")
		_:
			box.size = Vector3(0.08, 0.08, 0.85) * s
			pmat.albedo_color = Color("cfd4de")
	pmat.next_pass = Toon.outline(0.02 * s)
	prop.mesh = box
	prop.material_override = pmat
	prop.position = Vector3(0, -0.72 * s, 0.30 * s)   # in the right hand
	_r_arm.add_child(prop)

func _add_name_label(bar_y: float) -> void:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.outline_size = 8
	label.pixel_size = 0.006
	label.position.y = bar_y + 0.65
	var enemy_name := display_name
	if enemy_name == "":
		enemy_name = "The Bone-Titan" if world_boss else "War-King"
	label.text = ("◆ " + enemy_name) if elite else enemy_name
	label.modulate = Color("ffcf6a") if elite else Color("ff8a6a")
	add_child(label)

# --- Simulation ---

func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_tick_bleed(delta)
	if _dead:
		return

	_anim_t += delta
	_animate_rig(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# Knockback overrides movement until it decays.
	if _knockback.length() > 0.2:
		velocity.x = _knockback.x
		velocity.z = _knockback.z
		_knockback = _knockback.move_toward(Vector3.ZERO, KNOCKBACK_DECAY * delta)
		move_and_slide()
		return

	# Staggered: frozen and vulnerable.
	if _stagger_t > 0.0:
		_stagger_t -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if _stagger_t <= 0.0:
			_set_color(base_color)
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		move_and_slide()
		return

	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()

	_update_aggro(dist)

	# Resolving a wind-up (fires or strikes at the end).
	if _windup_t > 0.0:
		_windup_t -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if _windup_t <= 0.0:
			_set_color(base_color)
			_resolve_attack(player, dist)
			_attack_cd = attack_cooldown
		move_and_slide()
		return

	if not _aggro:
		_wander(delta)
		move_and_slide()
		return

	if is_ranged:
		_ranged_ai(to_p, dist)
	else:
		_melee_ai(to_p, dist)

	move_and_slide()

func _update_aggro(dist: float) -> void:
	if not _aggro:
		if dist <= aggro_range:
			_aggro = true
	elif dist > aggro_range * DEAGGRO_MULT and not (is_boss or world_boss):
		_aggro = false

## Off-duty patrol: drift around the spawn point, pause, drift again.
func _wander(delta: float) -> void:
	_wander_wait -= delta
	var to_t := _wander_target - global_position
	to_t.y = 0.0
	if _wander_wait <= 0.0 or to_t.length() < 1.2:
		_wander_wait = randf_range(2.5, 5.0)
		if randf() < 0.35:
			_wander_target = global_position   # just stand a while
		else:
			var ang := randf() * TAU
			var r := randf_range(2.0, 9.0)
			_wander_target = _home + Vector3(cos(ang) * r, 0, sin(ang) * r)
		to_t = _wander_target - global_position
		to_t.y = 0.0
	if to_t.length() >= 1.2:
		var d := to_t.normalized()
		velocity.x = d.x * move_speed * WANDER_SPEED_FRAC
		velocity.z = d.z * move_speed * WANDER_SPEED_FRAC
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func _melee_ai(to_p: Vector3, dist: float) -> void:
	if dist > CONTACT_RANGE:
		var d := to_p.normalized()
		velocity.x = d.x * move_speed
		velocity.z = d.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_begin_windup()

func _ranged_ai(to_p: Vector3, dist: float) -> void:
	var d := to_p.normalized()
	if dist > ARCHER_KEEP_DIST + 1.5:
		velocity.x = d.x * move_speed
		velocity.z = d.z * move_speed
	elif dist < ARCHER_KEEP_DIST - 1.5:
		velocity.x = -d.x * move_speed
		velocity.z = -d.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if _attack_cd <= 0.0 and dist <= ARCHER_MAX_RANGE:
		_begin_windup()

func _begin_windup() -> void:
	_windup_t = windup_time
	_set_color(WINDUP_COLOR)

func _resolve_attack(player: Node3D, dist: float) -> void:
	if is_ranged:
		_fire_projectile(player)
	elif dist <= CONTACT_RANGE + 0.7 and player.has_method("take_damage"):
		player.call("take_damage", contact_damage, self)

func _fire_projectile(player: Node3D) -> void:
	var origin := global_position + Vector3(0, 1.5 * body_scale, 0)
	var target := player.global_position + Vector3(0, 1.0, 0)
	var dir := (target - origin).normalized()
	var proj := Projectile.new()
	get_parent().add_child(proj)
	proj.global_position = origin
	proj.setup(dir, 16.0, contact_damage)

# --- Rig animation ---

## Face the threat (or the walk direction when off-duty), walk when moving,
## telegraph wind-ups, idle-sway otherwise.
func _animate_rig(delta: float) -> void:
	if _body == null:
		return
	var face := Vector3.ZERO
	if _aggro:
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player:
			face = player.global_position - global_position
	elif Vector2(velocity.x, velocity.z).length() > 0.4:
		face = velocity
	if absf(face.x) + absf(face.z) > 0.01:
		_body.rotation.y = lerp_angle(_body.rotation.y, atan2(face.x, face.z), delta * 8.0)

	var hspeed := Vector2(velocity.x, velocity.z).length()
	if kind == Kind.BEAST:
		_animate_beast(delta, hspeed)
	else:
		_animate_humanoid(delta, hspeed)

func _animate_humanoid(delta: float, hspeed: float) -> void:
	if _windup_t > 0.0:
		_r_arm.rotation.x = lerp_angle(_r_arm.rotation.x, -2.3, delta * 12.0)
		_l_arm.rotation.x = lerp_angle(_l_arm.rotation.x, 0.5, delta * 10.0)
		_l_leg.rotation.x = lerp_angle(_l_leg.rotation.x, 0.0, delta * 8.0)
		_r_leg.rotation.x = lerp_angle(_r_leg.rotation.x, 0.0, delta * 8.0)
	elif hspeed > 0.6:
		_walk_phase += delta * (2.0 + hspeed)
		var sw := sin(_walk_phase) * 0.6
		_l_leg.rotation.x = sw
		_r_leg.rotation.x = -sw
		_l_arm.rotation.x = -sw * 0.7
		_r_arm.rotation.x = sw * 0.7
	else:
		var idle := sin(_anim_t * 1.6) * 0.06
		_l_leg.rotation.x = lerp_angle(_l_leg.rotation.x, 0.0, delta * 8.0)
		_r_leg.rotation.x = lerp_angle(_r_leg.rotation.x, 0.0, delta * 8.0)
		_l_arm.rotation.x = lerp_angle(_l_arm.rotation.x, idle, delta * 6.0)
		_r_arm.rotation.x = lerp_angle(_r_arm.rotation.x, -idle, delta * 6.0)

func _animate_beast(delta: float, hspeed: float) -> void:
	if _use_model:
		_animate_beast_model(hspeed)
		return
	if _legs.size() < 4:
		return
	if _windup_t > 0.0:
		# Crouch before the lunge.
		_body.rotation.x = lerp_angle(_body.rotation.x, -0.18, delta * 10.0)
		for l in _legs:
			(l as Node3D).rotation.x = lerp_angle((l as Node3D).rotation.x, 0.3, delta * 10.0)
	elif hspeed > 0.6:
		_body.rotation.x = lerp_angle(_body.rotation.x, 0.0, delta * 8.0)
		_walk_phase += delta * (4.0 + hspeed * 1.5)
		var sw := sin(_walk_phase) * 0.7
		(_legs[0] as Node3D).rotation.x = sw    # trot: diagonal pairs
		(_legs[3] as Node3D).rotation.x = sw
		(_legs[1] as Node3D).rotation.x = -sw
		(_legs[2] as Node3D).rotation.x = -sw
	else:
		_body.rotation.x = lerp_angle(_body.rotation.x, 0.0, delta * 8.0)
		var idle := sin(_anim_t * 1.4) * 0.05
		for i in _legs.size():
			var l := _legs[i] as Node3D
			l.rotation.x = lerp_angle(l.rotation.x, idle * (1 if i % 2 == 0 else -1), delta * 6.0)

## Drive the loaded creature's own clips from movement state.
func _animate_beast_model(hspeed: float) -> void:
	if _anim == null:
		return
	if _windup_t > 0.0:
		AssetLoader.play_anim(_anim, ["survey", "idle"])
	elif hspeed > 3.0:
		AssetLoader.play_anim(_anim, ["run", "gallop"])
	elif hspeed > 0.6:
		AssetLoader.play_anim(_anim, ["walk", "trot"])
	else:
		AssetLoader.play_anim(_anim, ["survey", "idle"])

# --- Damage / reactions ---

func take_damage(amount: int, is_crit: bool = false, source_pos: Vector3 = Vector3.ZERO) -> void:
	if _dead:
		return
	_aggro = true
	health -= amount
	Combat.spawn_damage_number(global_position + Vector3(0, 2.5 * body_scale, 0), amount, is_crit)
	if _bar:
		_bar.set_ratio(float(health) / float(max_health))
	_flash()
	Combat.spawn_hit(global_position + Vector3(0, 1.3 * body_scale, 0),
		Color("ffdd55") if is_crit else Color("ff6b6b"), 14 if is_crit else 8, body_scale)

	if source_pos != Vector3.ZERO and knockback_resist < 1.0:
		var kb := global_position - source_pos
		kb.y = 0.0
		if kb.length() > 0.01:
			_knockback = kb.normalized() * knockback_force * (1.0 - knockback_resist)

	if health <= 0:
		die()

## Battleaxe bleed: stack a damage-over-time that ticks twice a second.
func apply_bleed(dmg_per_tick: int, ticks: int) -> void:
	_bleed_dmg = maxi(_bleed_dmg, dmg_per_tick)
	_bleed_ticks = maxi(_bleed_ticks, ticks)

func _tick_bleed(delta: float) -> void:
	if _bleed_ticks <= 0:
		return
	_bleed_timer -= delta
	if _bleed_timer <= 0.0:
		_bleed_timer = 0.5
		_bleed_ticks -= 1
		take_damage(_bleed_dmg, false, Vector3.ZERO)

## Freeze and turn vulnerable for `duration` (parry / heavy hit). Bosses shrug
## off part of it via knockback_resist acting as stagger resist too.
func stagger(duration: float) -> void:
	_windup_t = 0.0
	var d := duration * (1.0 - knockback_resist * 0.5)
	_stagger_t = maxf(_stagger_t, d)
	_set_color(STAGGER_COLOR)

func _flash() -> void:
	if _mat == null:
		return
	_mat.albedo_color = FLASH_COLOR
	get_tree().create_timer(0.08).timeout.connect(_unflash)

func _unflash() -> void:
	if _mat == null:
		return
	if _stagger_t > 0.0:
		_set_color(STAGGER_COLOR)
	elif _windup_t > 0.0:
		_set_color(WINDUP_COLOR)
	else:
		_set_color(base_color)

func _set_color(c: Color) -> void:
	if _mat:
		_mat.albedo_color = c

# --- Death & spoils ---

func die() -> void:
	if _dead:
		return
	_dead = true
	if _anim:
		_anim.pause()                        # freeze the creature's clip mid-topple
	remove_from_group("enemy")               # stop counting toward spawns immediately
	set_deferred("collision_layer", 0)        # let the player walk through the corpse
	if _bar:
		_bar.visible = false
	Combat.spawn_hit(global_position + Vector3(0, 1.2 * body_scale, 0), base_color.lightened(0.25), 24, body_scale * 1.4)

	GameState.add_gold(randi_range(4, 8 + power) + (60 if is_boss else 0) + (150 if world_boss else 0))

	# Loot is scarce: trash mostly drops nothing; elites and bosses always pay.
	var chance := drop_chance
	var rolls := 1
	var min_rarity := 0
	if elite:
		chance = 1.0
		min_rarity = 1
	if is_boss or world_boss:
		chance = 1.0
		min_rarity = 3
		rolls = 5 if world_boss else 3
	if randf() < chance:
		for i in rolls:
			var item := LootManager.roll_item(power + (10 if (is_boss or world_boss) else 0), loot_table, min_rarity)
			var drop := LootDrop.new(item)
			get_parent().add_child(drop)
			drop.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0))
	died.emit(self)

	# Topple over, then free.
	if _body:
		var t := create_tween()
		t.tween_property(_body, "rotation:x", deg_to_rad(88), 0.35).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(_body, "position:y", -0.9 * body_scale, 0.5).set_delay(0.2)
		t.tween_callback(queue_free)
	else:
		queue_free()
