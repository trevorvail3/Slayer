class_name HealthBar3D
extends Node3D

## A tiny billboarded health bar that floats above an enemy. Centered fill that
## shrinks as health drops. Unshaded + billboard so it always faces the camera
## and stays readable regardless of scene lighting.

const WIDTH := 1.3
const HEIGHT := 0.16

var _fill: MeshInstance3D
var _fill_mesh: QuadMesh

func _ready() -> void:
	# Background (slightly larger, dark).
	var bg := MeshInstance3D.new()
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(WIDTH + 0.06, HEIGHT + 0.05)
	bg.mesh = bg_mesh
	bg.material_override = _billboard_mat(Color(0, 0, 0, 0.65))
	add_child(bg)

	# Foreground fill.
	_fill = MeshInstance3D.new()
	_fill_mesh = QuadMesh.new()
	_fill_mesh.size = Vector2(WIDTH, HEIGHT)
	_fill.mesh = _fill_mesh
	_fill.material_override = _billboard_mat(Color(0.85, 0.2, 0.2))
	_fill.position.z = 0.01
	add_child(_fill)

func _billboard_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	return mat

func set_ratio(r: float) -> void:
	r = clampf(r, 0.0, 1.0)
	if _fill_mesh:
		_fill_mesh.size = Vector2(maxf(0.001, WIDTH * r), HEIGHT)
