class_name Player
extends CharacterBody3D

## First-person slayer. Builds its own camera, weapon/shield view models and
## attack ray in code. Weighty melee (swing animation + hit-stop + knockback),
## right-click shield block with a parry window, and a stamina economy.

const MOUSE_SENS := 0.0025
const GRAVITY := 20.0
const JUMP_VELOCITY := 5.0
const ATTACK_RANGE := 3.2

const ATTACK_COOLDOWN := 0.5
const SWING_STAMINA := 18.0
const STAMINA_REGEN := 35.0        # per second, when not blocking
const BLOCK_REDUCTION := 0.7       # 70% less damage while blocking
const PARRY_WINDOW := 0.25         # seconds after raising block that a hit parries
const PARRY_STAGGER := 1.3         # seconds the enemy is staggered on parry

# View-model poses (local to the camera).
const WEAPON_REST_POS := Vector3(0.36, -0.30, -0.55)
const WEAPON_REST_ROT := Vector3(6, -4, 4)
const WEAPON_WINDUP_ROT := Vector3(-45, 35, 45)
const WEAPON_STRIKE_ROT := Vector3(35, -35, -55)
const SHIELD_HIDDEN_POS := Vector3(-0.55, -0.75, -0.5)
const SHIELD_BLOCK_POS := Vector3(-0.28, -0.22, -0.42)

var camera: Camera3D
var attack_ray: RayCast3D
var weapon: Node3D
var shield: Node3D

var health: int = 100
var stamina: float = 100.0
var blocking: bool = false

var _pitch := 0.0
var _kick := 0.0          # vertical camera-kick offset, decays to 0
var _can_attack := true
var _parry_timer := 0.0
var _swing_tween: Tween
var _shield_tween: Tween

func _ready() -> void:
	add_to_group("player")
	_build()
	health = PlayerStats.max_health()
	stamina = PlayerStats.max_stamina()
	GameState.equipment_changed.connect(_on_equipment_changed)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.4
	col.shape = shape
	add_child(col)

	camera = Camera3D.new()
	camera.position = Vector3(0, 0.7, 0)
	add_child(camera)

	attack_ray = RayCast3D.new()
	attack_ray.target_position = Vector3(0, 0, -ATTACK_RANGE)
	attack_ray.collision_mask = 0xFFFFFFFF
	attack_ray.add_exception(self)
	camera.add_child(attack_ray)

	weapon = _make_weapon()
	weapon.position = WEAPON_REST_POS
	weapon.rotation_degrees = WEAPON_REST_ROT
	camera.add_child(weapon)

	shield = _make_shield()
	shield.position = SHIELD_HIDDEN_POS
	camera.add_child(shield)

func _make_weapon() -> Node3D:
	var root := Node3D.new()
	# Blade
	root.add_child(_box(Vector3(0.06, 0.06, 1.0), Vector3(0, 0, -0.5), Color("c9ccd6")))
	# Cross-guard
	root.add_child(_box(Vector3(0.30, 0.06, 0.06), Vector3(0, 0, 0.02), Color("8a8f99")))
	# Handle
	root.add_child(_box(Vector3(0.05, 0.05, 0.22), Vector3(0, 0, 0.15), Color("5a3a22")))
	# Pommel
	root.add_child(_box(Vector3(0.09, 0.09, 0.06), Vector3(0, 0, 0.28), Color("8a8f99")))
	return root

func _make_shield() -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(0.5, 0.62, 0.06), Vector3(0, 0, 0), Color("5a4632")))
	root.add_child(_box(Vector3(0.12, 0.12, 0.04), Vector3(0, 0, -0.05), Color("c9ccd6")))  # boss
	root.rotation_degrees = Vector3(0, 12, 0)
	return root

func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	return m

func _on_equipment_changed() -> void:
	health = PlayerStats.max_health()
	stamina = PlayerStats.max_stamina()

# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.4, 1.4)
	elif event.is_action_pressed("attack"):
		_attack()
	elif event.is_action_pressed("block"):
		_set_block(true)
	elif event.is_action_released("block"):
		_set_block(false)

# --- Frame updates ---

func _process(delta: float) -> void:
	# Camera kick decays back to neutral; pitch + kick applied here only.
	_kick = lerpf(_kick, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	if camera:
		camera.rotation.x = _pitch + _kick

	if _parry_timer > 0.0:
		_parry_timer -= delta

	if not blocking:
		stamina = minf(PlayerStats.max_stamina(), stamina + STAMINA_REGEN * delta)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	# Explicit per-frame input read -> no residual velocity, no phantom drift.
	var input_dir := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("move_forward"):
			input_dir.y -= 1.0
		if Input.is_action_pressed("move_back"):
			input_dir.y += 1.0
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1.0
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var speed := PlayerStats.move_speed() * (0.4 if blocking else 1.0)
	var dir := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	move_and_slide()

# --- Attacking ---

func _attack() -> void:
	if not _can_attack or blocking:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if stamina < SWING_STAMINA:
		return

	_can_attack = false
	stamina -= SWING_STAMINA
	_animate_swing()
	get_tree().create_timer(ATTACK_COOLDOWN).timeout.connect(func(): _can_attack = true)

func _animate_swing() -> void:
	if _swing_tween and _swing_tween.is_valid():
		_swing_tween.kill()
	weapon.rotation_degrees = WEAPON_REST_ROT
	_swing_tween = create_tween()
	_swing_tween.tween_property(weapon, "rotation_degrees", WEAPON_WINDUP_ROT, 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_property(weapon, "rotation_degrees", WEAPON_STRIKE_ROT, 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing_tween.tween_callback(_do_hit)
	_swing_tween.tween_property(weapon, "rotation_degrees", WEAPON_REST_ROT, 0.20) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _do_hit() -> void:
	attack_ray.force_raycast_update()
	if not attack_ray.is_colliding():
		return
	var target := attack_ray.get_collider() as Node
	if not (target and target.is_in_group("enemy") and target.has_method("take_damage")):
		return

	var dmg := PlayerStats.attack_damage()
	var is_crit := randf() < PlayerStats.crit_chance()
	if is_crit:
		dmg = int(dmg * PlayerStats.crit_multiplier())
	target.call("take_damage", dmg, is_crit, global_position)
	Combat.hitstop(0.07, 0.06)
	_kick += 0.05

# --- Blocking / parrying ---

func _set_block(on: bool) -> void:
	if on and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	blocking = on
	if on:
		_parry_timer = PARRY_WINDOW
	_animate_shield(on)

func _animate_shield(up: bool) -> void:
	if _shield_tween and _shield_tween.is_valid():
		_shield_tween.kill()
	_shield_tween = create_tween()
	var target_pos := SHIELD_BLOCK_POS if up else SHIELD_HIDDEN_POS
	_shield_tween.tween_property(shield, "position", target_pos, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# --- Taking damage ---

func take_damage(amount: int, attacker: Node = null) -> void:
	if blocking:
		if _parry_timer > 0.0 and attacker and attacker.has_method("stagger"):
			# Perfect parry: fully negate, stagger the attacker, big feedback.
			attacker.call("stagger", PARRY_STAGGER)
			Combat.hitstop(0.11, 0.05)
			_kick += 0.10
			return
		amount = int(amount * (1.0 - BLOCK_REDUCTION))

	var reduced := int(amount * (1.0 - PlayerStats.damage_reduction()))
	health -= maxi(1, reduced)
	_kick += 0.05
	if health <= 0:
		# Simple respawn-in-place for now; death/revive arrives with a later milestone.
		health = PlayerStats.max_health()
		stamina = PlayerStats.max_stamina()
		global_position = Vector3(0, 2, 8)
