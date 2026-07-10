class_name Projectile
extends Area3D

## An enemy arrow/bolt. Flies straight, damages the player on contact, and is
## blocked by walls. Ignores enemies (no friendly fire, and won't self-destruct
## on the archer that fired it).

var _vel := Vector3.ZERO
var _damage := 0
var _life := 4.0

func setup(dir: Vector3, speed: float, damage: int) -> void:
	_vel = dir * speed
	_damage = damage

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.18
	s.height = 0.36
	mesh.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ff6a3d")
	mat.emission_enabled = true
	mat.emission = Color("ff6a3d")
	mat.emission_energy_multiplier = 1.5
	mesh.material_override = mat
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += _vel * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.call("take_damage", _damage, null)
	queue_free()
