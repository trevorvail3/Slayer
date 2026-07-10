class_name Enemy
extends CharacterBody3D

## Monster with combat rhythm and three archetypes:
##  - GRUNT: balanced melee chaser (the original).
##  - BRUTE: slow, huge HP, heavy hits, resists knockback. Set is_boss for the Warlord.
##  - ARCHER: keeps its distance and fires projectiles.
## Telegraphs a wind-up before attacking, can be staggered/parried, takes
## knockback, shows a floating health bar, and drops rolled loot on death.

signal died(enemy: Enemy)

enum Kind { GRUNT, BRUTE, ARCHER }

@export var kind: Kind = Kind.GRUNT
@export var power := 10
@export var is_boss := false
@export var world_boss := false

const GRAVITY := 20.0
const CONTACT_RANGE := 2.0
const ARCHER_KEEP_DIST := 9.0
const ARCHER_MAX_RANGE := 18.0
const KNOCKBACK_DECAY := 22.0

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
var base_color := Color("8d3b3b")

var _mat: StandardMaterial3D
var _bar: HealthBar3D
var _body: Node3D
var _head: MeshInstance3D
var _l_arm: Node3D
var _r_arm: Node3D
var _l_leg: Node3D
var _r_leg: Node3D
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

const WINDUP_COLOR := Color("e6b422")
const STAGGER_COLOR := Color("3f6fb0")
const FLASH_COLOR := Color.WHITE

func _ready() -> void:
	add_to_group("enemy")
	_configure()
	health = max_health
	_build()

func _configure() -> void:
	match kind:
		Kind.BRUTE:
			max_health = 80 + power * 6
			move_speed = 2.0
			contact_damage = 12 + power * 2
			windup_time = 0.6
			attack_cooldown = 1.8
			knockback_resist = 0.6
			base_color = Color("6e2b2b")
			body_scale = 1.5
		Kind.ARCHER:
			max_health = 22 + power * 2
			move_speed = 3.2
			contact_damage = 6 + power
			windup_time = 0.5
			attack_cooldown = 2.0
			is_ranged = true
			base_color = Color("2f7d8c")
			body_scale = 0.95
		_:
			max_health = 30 + power * 3
			move_speed = 3.0
			contact_damage = 5 + power
			base_color = Color("8d3b3b")

	if is_boss:
		max_health = 600 + power * 12
		contact_damage = 20 + power * 2
		move_speed = 2.4
		windup_time = 0.7
		attack_cooldown = 1.6
		knockback_resist = 0.9
		body_scale = 2.3
		base_color = Color("b8860b")

	if world_boss:
		max_health = 1600 + power * 20
		contact_damage = 26 + power * 2
		move_speed = 2.2
		knockback_resist = 0.95
		body_scale = 3.2
		base_color = Color("c0392b")

func _build() -> void:
	var s := body_scale

	# One shared material so a flash tints the whole body at once.
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = base_color
	_mat.roughness = 0.85
	_mat.rim_enabled = true
	_mat.rim = 0.5

	# Humanoid rig (visual only) parented to _body for facing + death topple.
	_body = Node3D.new()
	add_child(_body)
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

	var h := 2.2 * s
	var r := 0.6 * s
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = h
	shape.radius = r
	col.shape = shape
	col.position = Vector3(0, h * 0.5, 0)
	add_child(col)

	_bar = HealthBar3D.new()
	_bar.position = Vector3(0, 2.45 * s + 0.2, 0)
	if is_boss:
		_bar.scale = Vector3(2.2, 2.2, 1.0)
	add_child(_bar)
	_bar.set_ratio(1.0)

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
	prop.mesh = box
	prop.material_override = pmat
	prop.position = Vector3(0, -0.72 * s, -0.35 * s)   # in the right hand, pointing forward
	_r_arm.add_child(prop)

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

	if is_ranged:
		_ranged_ai(to_p, dist)
	else:
		_melee_ai(to_p, dist)

	move_and_slide()

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

# --- Damage / reactions ---

func take_damage(amount: int, is_crit: bool = false, source_pos: Vector3 = Vector3.ZERO) -> void:
	if _dead:
		return
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

func die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("enemy")               # stop counting toward spawns immediately
	set_deferred("collision_layer", 0)        # let the player walk through the corpse
	if _bar:
		_bar.visible = false
	Combat.spawn_hit(global_position + Vector3(0, 1.2 * body_scale, 0), base_color.lightened(0.25), 24, body_scale * 1.4)

	GameState.add_gold(randi_range(4, 8 + power) + (60 if is_boss else 0) + (150 if world_boss else 0))
	var rolls := 5 if world_boss else (3 if is_boss else 1)
	var min_rarity := 3 if is_boss else 0    # Legendary+ from any boss
	for i in rolls:
		var item := LootManager.roll_item(power + (10 if is_boss else 0), loot_table, min_rarity)
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

## Procedural rig animation: face the player, walk when moving, telegraph a
## wind-up with a raised arm, idle-sway otherwise.
func _animate_rig(delta: float) -> void:
	if _body == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var to := player.global_position - global_position
		if absf(to.x) + absf(to.z) > 0.01:
			_body.rotation.y = lerp_angle(_body.rotation.y, atan2(to.x, to.z), delta * 8.0)

	var hspeed := Vector2(velocity.x, velocity.z).length()
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
