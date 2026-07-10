class_name Player
extends CharacterBody3D

## First-person controller. Builds its own camera + attack ray in code so the
## scene stays a trivial script-only node. Left-click melee raycast; damage and
## survivability come from equipped gear via PlayerStats.

const SPEED := 6.0
const JUMP_VELOCITY := 5.0
const GRAVITY := 20.0
const MOUSE_SENS := 0.0025
const ATTACK_RANGE := 3.0
const ATTACK_COOLDOWN := 0.35

var camera: Camera3D
var attack_ray: RayCast3D
var health: int = 100
var _pitch := 0.0
var _can_attack := true

func _ready() -> void:
	add_to_group("player")
	_build()
	health = PlayerStats.max_health()
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

func _on_equipment_changed() -> void:
	# Keep health topped to the new max when gear changes (v0.1 convenience).
	health = PlayerStats.max_health()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.4, 1.4)
		camera.rotation.x = _pitch
	elif event.is_action_pressed("attack"):
		_attack()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _attack() -> void:
	if not _can_attack or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	_can_attack = false
	get_tree().create_timer(ATTACK_COOLDOWN).timeout.connect(func(): _can_attack = true)

	attack_ray.force_raycast_update()
	if attack_ray.is_colliding():
		var target := attack_ray.get_collider() as Node
		if target and target.is_in_group("enemy") and target.has_method("take_damage"):
			target.call("take_damage", PlayerStats.attack_damage())

func take_damage(amount: int) -> void:
	var reduced := int(amount * (1.0 - PlayerStats.damage_reduction()))
	health -= maxi(1, reduced)
	if health <= 0:
		# Simple respawn-in-place for v0.1; death/revive lands with combat in v0.2.
		health = PlayerStats.max_health()
		global_position = Vector3(0, 2, 8)
