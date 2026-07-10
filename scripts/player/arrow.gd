class_name Arrow
extends Area3D

## Player projectile for bows/crossbows. Flies straight, damages the first enemy
## it hits (with a crit roll), and is stopped by walls/terrain. Ignores the player.

var _vel := Vector3.ZERO
var _dmg := 0
var _crit_chance := 0.0
var _life := 3.0

func setup(dir: Vector3, speed: float, dmg: int, crit_chance: float) -> void:
	_vel = dir * speed
	_dmg = dmg
	_crit_chance = crit_chance
	look_at_from_position(global_position, global_position + dir, Vector3.UP)

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.05, 0.05, 0.7)
	mesh.mesh = shaft
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("f0e6c0")
	mat.emission_enabled = true
	mat.emission = Color("ffe08a")
	mat.emission_energy_multiplier = 0.8
	mesh.material_override = mat
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.12
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += _vel * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		var crit := randf() < _crit_chance
		var d := _dmg
		if crit:
			d = int(d * 2.0)
		body.call("take_damage", d, crit, global_position)
		Combat.hitstop(0.05, 0.08)
	queue_free()
