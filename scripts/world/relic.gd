class_name Relic
extends Area3D

## A world collectible. Walk into it to recover it: grants a little gold + iron,
## bumps the persistent relic count, and pops a toast. Spins and bobs to draw the eye.

var _mesh: MeshInstance3D
var _t := 0.0

func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.5, 0.5, 0.5)
	_mesh.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("46e0d0")
	mat.emission_enabled = true
	mat.emission = Color("46e0d0")
	mat.emission_energy_multiplier = 1.4
	_mesh.material_override = mat
	_mesh.rotation_degrees = Vector3(45, 0, 45)
	add_child(_mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.2
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	if _mesh:
		_mesh.rotate_y(delta * 1.5)
		_mesh.position.y = 0.9 + sin(_t * 2.0) * 0.2

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	GameState.add_gold(randi_range(15, 30))
	GameState.add_resource("iron", randi_range(1, 3))
	GameState.add_relic()
	queue_free()
