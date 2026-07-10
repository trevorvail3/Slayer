class_name LootDrop
extends Area3D

## The physical pickup an enemy leaves behind: a glowing cube tinted by rarity,
## bobbing and spinning. Walk into it to add the item to your backpack.

var item: ItemData
var _mesh: MeshInstance3D
var _t := 0.0

func _init(p_item: ItemData = null) -> void:
	item = p_item

func _ready() -> void:
	var col_color := item.display_color() if item else Color.WHITE

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col_color
	mat.emission_enabled = true
	mat.emission = col_color
	mat.emission_energy_multiplier = 0.8
	_mesh.material_override = mat
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
		_mesh.rotate_y(delta * 2.0)
		_mesh.position.y = 0.5 + sin(_t * 2.5) * 0.15

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameState.add_to_backpack(item)
		queue_free()
