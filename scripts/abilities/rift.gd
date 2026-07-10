class_name Rift
extends Area3D

## Runecaster class ability: a zone that heals the player while they stand in it.

const RADIUS := 2.6
const TICK := 0.5

var heal_amount := 6
var _dur := 8.0
var _tick_t := 0.0

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.1
	mesh.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.4, 1.0, 0.35)
	mat.emission_enabled = true
	mat.emission = Color("b060ff")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	mesh.position.y = 0.06
	add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = 2.5
	col.shape = shape
	col.position.y = 1.0
	add_child(col)

func _process(delta: float) -> void:
	_dur -= delta
	if _dur <= 0.0:
		queue_free()
		return
	_tick_t -= delta
	if _tick_t <= 0.0:
		_tick_t = TICK
		for b in get_overlapping_bodies():
			if b.is_in_group("player") and b.has_method("heal"):
				b.call("heal", heal_amount)
