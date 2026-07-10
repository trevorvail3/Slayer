class_name Caltrops
extends Area3D

## Stalker class ability: a ground zone that ticks damage to enemies standing in it.

const RADIUS := 3.0
const TICK := 0.5

var damage := 8
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
	mat.albedo_color = Color(0.4, 0.85, 0.4, 0.35)
	mat.emission_enabled = true
	mat.emission = Color("6ad06a")
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
			if b.is_in_group("enemy") and b.has_method("take_damage"):
				b.call("take_damage", damage, false, Vector3.ZERO)
