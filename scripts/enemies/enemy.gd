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

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _bar: HealthBar3D
var _attack_cd := 0.0
var _windup_t := 0.0
var _stagger_t := 0.0
var _knockback := Vector3.ZERO

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

func _build() -> void:
	var h := 2.2 * body_scale
	var r := 0.6 * body_scale

	_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = h
	capsule.radius = r
	_mesh.mesh = capsule
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = base_color
	_mesh.material_override = _mat
	_mesh.position = Vector3(0, h * 0.5, 0)
	add_child(_mesh)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = h
	shape.radius = r
	col.shape = shape
	col.position = Vector3(0, h * 0.5, 0)
	add_child(col)

	_bar = HealthBar3D.new()
	_bar.position = Vector3(0, h + 0.4, 0)
	if is_boss:
		_bar.scale = Vector3(2.2, 2.2, 1.0)
	add_child(_bar)
	_bar.set_ratio(1.0)

func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)

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
	health -= amount
	Combat.spawn_damage_number(global_position + Vector3(0, 2.5 * body_scale, 0), amount, is_crit)
	if _bar:
		_bar.set_ratio(float(health) / float(max_health))
	_flash()

	if source_pos != Vector3.ZERO and knockback_resist < 1.0:
		var kb := global_position - source_pos
		kb.y = 0.0
		if kb.length() > 0.01:
			_knockback = kb.normalized() * knockback_force * (1.0 - knockback_resist)

	if health <= 0:
		die()

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
	var rolls := 3 if is_boss else 1
	var min_rarity := 3 if is_boss else 0    # Legendary+ from the boss
	for i in rolls:
		var item := LootManager.roll_item(power + (10 if is_boss else 0), loot_table, min_rarity)
		var drop := LootDrop.new(item)
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0))
	died.emit(self)
	queue_free()
