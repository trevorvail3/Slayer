class_name Enemy
extends CharacterBody3D

## Placeholder monster with combat rhythm: chases, telegraphs a wind-up before it
## strikes, can be staggered (and parried), takes knockback, and drops rolled loot
## on death. Its `power` scales the loot it drops.

signal died

@export var max_health := 60
@export var power := 10

const MOVE_SPEED := 3.0
const GRAVITY := 20.0
const CONTACT_RANGE := 2.0
const CONTACT_COOLDOWN := 1.4
const WINDUP_TIME := 0.45
const KNOCKBACK_FORCE := 7.0
const KNOCKBACK_DECAY := 22.0

const BASE_COLOR := Color("8d3b3b")
const WINDUP_COLOR := Color("e6b422")
const STAGGER_COLOR := Color("3f6fb0")
const FLASH_COLOR := Color.WHITE

var health: int
var loot_table: LootTable
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _attack_cd := 0.0
var _windup_t := 0.0
var _stagger_t := 0.0
var _knockback := Vector3.ZERO

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	_build()

func _build() -> void:
	_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 2.2
	capsule.radius = 0.6
	_mesh.mesh = capsule
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = BASE_COLOR
	_mesh.material_override = _mat
	_mesh.position = Vector3(0, 1.3, 0)
	add_child(_mesh)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 2.2
	shape.radius = 0.6
	col.shape = shape
	col.position = Vector3(0, 1.3, 0)
	add_child(col)

func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# Knockback overrides everything until it decays.
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
			_set_color(BASE_COLOR)
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		move_and_slide()
		return

	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()

	# Winding up to strike.
	if _windup_t > 0.0:
		_windup_t -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if _windup_t <= 0.0:
			_set_color(BASE_COLOR)
			if dist <= CONTACT_RANGE + 0.6 and player.has_method("take_damage"):
				player.call("take_damage", 5 + power, self)
			_attack_cd = CONTACT_COOLDOWN
		move_and_slide()
		return

	if dist > CONTACT_RANGE:
		var d := to_p.normalized()
		velocity.x = d.x * MOVE_SPEED
		velocity.z = d.z * MOVE_SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_windup_t = WINDUP_TIME
			_set_color(WINDUP_COLOR)

	move_and_slide()

# --- Damage / reactions ---

func take_damage(amount: int, is_crit: bool = false, source_pos: Vector3 = Vector3.ZERO) -> void:
	health -= amount
	Combat.spawn_damage_number(global_position + Vector3(0, 2.5, 0), amount, is_crit)
	_flash()

	if source_pos != Vector3.ZERO:
		var kb := global_position - source_pos
		kb.y = 0.0
		if kb.length() > 0.01:
			_knockback = kb.normalized() * KNOCKBACK_FORCE

	if health <= 0:
		die()

## Called on a parry (or heavy hit): freeze and turn vulnerable for `duration`.
func stagger(duration: float) -> void:
	_windup_t = 0.0
	_stagger_t = maxf(_stagger_t, duration)
	_set_color(STAGGER_COLOR)

func _flash() -> void:
	if _mat == null:
		return
	_mat.albedo_color = FLASH_COLOR
	get_tree().create_timer(0.08).timeout.connect(_unflash)

func _unflash() -> void:
	if not is_instance_valid(self) or _mat == null:
		return
	# Don't stomp a state color that's still active.
	if _stagger_t > 0.0:
		_set_color(STAGGER_COLOR)
	elif _windup_t > 0.0:
		_set_color(WINDUP_COLOR)
	else:
		_set_color(BASE_COLOR)

func _set_color(c: Color) -> void:
	if _mat:
		_mat.albedo_color = c

func die() -> void:
	var item := LootManager.roll_item(power, loot_table)
	var drop := LootDrop.new(item)
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector3(0, 0.5, 0)
	died.emit()
	queue_free()
