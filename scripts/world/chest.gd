class_name Chest
extends Area3D

## A world loot chest. Slowly spins to catch the eye; walk into it to pop it open
## and spray out guaranteed Rare+ loot (reuses LootManager + LootDrop).

@export var min_rarity_index := 2   # Rare or better
@export var rolls := 2
@export var power := 20

var _opened := false
var _mesh: MeshInstance3D

func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.7, 0.7)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c9a24a")
	mat.emission_enabled = true
	mat.emission = Color("c9a24a")
	mat.emission_energy_multiplier = 0.5
	_mesh.material_override = mat
	_mesh.position.y = 0.35
	add_child(_mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.6, 1.8)
	col.shape = shape
	col.position.y = 0.7
	add_child(col)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _opened and _mesh:
		_mesh.rotate_y(delta * 0.6)

func _on_body_entered(body: Node) -> void:
	if _opened or not body.is_in_group("player"):
		return
	_opened = true
	for i in rolls:
		var item := LootManager.roll_item(power, null, min_rarity_index)
		var drop := LootDrop.new(item)
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 0.7, randf_range(-1.0, 1.0))

	var t := create_tween()
	t.tween_property(_mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.1)
	t.tween_property(_mesh, "scale", Vector3(0.01, 0.01, 0.01), 0.22)
	t.tween_callback(queue_free)
