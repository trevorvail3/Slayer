class_name Barricade
extends StaticBody3D

## Warden class ability: a solid temporary wall that blocks enemies and projectiles.
## Sinks into the ground and despawns after its lifetime.

const LIFETIME := 10.0

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.2, 2.2, 0.4)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("6a7a9a")
	mat.emission_enabled = true
	mat.emission = Color("6a9aff")
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	mesh.position.y = 1.1
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.2, 2.2, 0.4)
	col.shape = shape
	col.position.y = 1.1
	add_child(col)

	get_tree().create_timer(LIFETIME).timeout.connect(_expire)

func _expire() -> void:
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 2.6, 0.4)
	t.tween_callback(queue_free)
