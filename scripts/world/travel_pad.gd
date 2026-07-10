class_name TravelPad
extends Area3D

## A glowing pad. Walk in to travel. `to_zone` chooses direction (town <-> wilds).
## One-shot per scene load so re-entry can't double-fire during the transition.

@export var to_zone := true

var _used := false

func _ready() -> void:
	var color := Color("6ad0ff") if to_zone else Color("ffcf6a")

	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 2.0
	dm.bottom_radius = 2.0
	dm.height = 0.2
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = color
	dmat.emission_enabled = true
	dmat.emission = color
	dmat.emission_energy_multiplier = 1.3
	disc.material_override = dmat
	disc.position.y = 0.1
	add_child(disc)

	var beam := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 1.7
	bm.bottom_radius = 1.7
	bm.height = 6.0
	beam.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(color.r, color.g, color.b, 0.22)
	bmat.emission_enabled = true
	bmat.emission = color
	bmat.emission_energy_multiplier = 0.5
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = bmat
	beam.position.y = 3.0
	add_child(beam)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.0
	shape.height = 3.0
	col.shape = shape
	col.position.y = 1.5
	add_child(col)

	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.font_size = 40
	label.outline_size = 10
	label.position.y = 3.4
	label.text = "TO THE WILDS" if to_zone else "RETURN TO TOWN"
	add_child(label)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	if to_zone:
		Game.goto_zone()
	else:
		Game.goto_hub()
