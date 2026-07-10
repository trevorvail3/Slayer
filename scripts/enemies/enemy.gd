class_name Enemy
extends CharacterBody3D

## Placeholder monster: a red capsule that chases the player, deals contact
## damage, and drops a rolled item on death. Its `power` scales the loot it drops.

signal died

@export var max_health := 60
@export var power := 10

const MOVE_SPEED := 3.0
const GRAVITY := 20.0
const CONTACT_RANGE := 1.8
const CONTACT_COOLDOWN := 1.2

var health: int
var loot_table: LootTable
var _mesh: MeshInstance3D
var _attack_cd := 0.0

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
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8d3b3b")
	_mesh.material_override = mat
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

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var to_p: Vector3 = player.global_position - global_position
		to_p.y = 0.0
		var dist := to_p.length()
		if dist > CONTACT_RANGE:
			var d := to_p.normalized()
			velocity.x = d.x * MOVE_SPEED
			velocity.z = d.z * MOVE_SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if _attack_cd <= 0.0 and player.has_method("take_damage"):
				player.call("take_damage", 5 + power)
				_attack_cd = CONTACT_COOLDOWN

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	_flash()
	if health <= 0:
		die()

func _flash() -> void:
	if _mesh and _mesh.material_override:
		(_mesh.material_override as StandardMaterial3D).albedo_color = Color.WHITE
		get_tree().create_timer(0.08).timeout.connect(_unflash)

func _unflash() -> void:
	if is_instance_valid(_mesh) and _mesh.material_override:
		(_mesh.material_override as StandardMaterial3D).albedo_color = Color("8d3b3b")

func die() -> void:
	var item := LootManager.roll_item(power, loot_table)
	var drop := LootDrop.new(item)
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector3(0, 0.5, 0)
	died.emit()
	queue_free()
