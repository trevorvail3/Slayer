class_name ResourceNode
extends StaticBody3D

## A gatherable node (tree/rock/ore). You mine it by hitting it with your weapon
## (reuses the combat take_damage path); each hit is one progress. On depletion it
## grants resources to GameState, vanishes, and respawns after a delay.

enum Kind { TREE, ROCK, ORE }

@export var kind: Kind = Kind.TREE

const RESPAWN := 14.0

var _type := "wood"
var _max := 3
var _hp := 3
var _yield_min := 3
var _yield_max := 5
var _depleted := false

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _extra: MeshInstance3D          # canopy for trees
var _bar: HealthBar3D
var _base_color := Color.WHITE
var _height := 2.4

func _ready() -> void:
	add_to_group("gatherable")
	_configure()
	_build()

func _configure() -> void:
	match kind:
		Kind.ROCK:
			_type = "stone"; _max = 4; _yield_min = 2; _yield_max = 4; _height = 1.2
		Kind.ORE:
			_type = "iron"; _max = 5; _yield_min = 1; _yield_max = 3; _height = 1.2
		_:
			_type = "wood"; _max = 3; _yield_min = 3; _yield_max = 5; _height = 2.4
	_hp = _max

func _build() -> void:
	_mesh = MeshInstance3D.new()
	match kind:
		Kind.TREE:
			var trunk := CylinderMesh.new()
			trunk.top_radius = 0.32
			trunk.bottom_radius = 0.42
			trunk.height = _height
			_mesh.mesh = trunk
			_base_color = Color("5a3a22")
		Kind.ROCK:
			var b := BoxMesh.new()
			b.size = Vector3(1.4, _height, 1.4)
			_mesh.mesh = b
			_base_color = Color("8a8f99")
		Kind.ORE:
			var b2 := BoxMesh.new()
			b2.size = Vector3(1.3, _height, 1.3)
			_mesh.mesh = b2
			_base_color = Color("b7a35a")
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mesh.material_override = _mat
	_mesh.position.y = _height * 0.5
	add_child(_mesh)

	if kind == Kind.TREE:
		_extra = MeshInstance3D.new()
		var canopy := SphereMesh.new()
		canopy.radius = 1.1
		canopy.height = 2.2
		_extra.mesh = canopy
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color("2f6d3a")
		_extra.material_override = cm
		_extra.position.y = _height + 0.6
		add_child(_extra)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.3, _height, 1.3)
	col.shape = shape
	col.position.y = _height * 0.5
	add_child(col)

	_bar = HealthBar3D.new()
	_bar.position.y = _height + (1.4 if kind == Kind.TREE else 0.6)
	add_child(_bar)
	_bar.visible = false

func take_damage(_amount: int, _is_crit: bool = false, _source_pos: Vector3 = Vector3.ZERO) -> void:
	if _depleted:
		return
	_hp -= 1
	_bar.visible = true
	_bar.set_ratio(float(_hp) / float(_max))
	_flash()
	if _hp <= 0:
		_deplete()

func _deplete() -> void:
	_depleted = true
	var amount := randi_range(_yield_min, _yield_max)
	GameState.add_resource(_type, amount)
	visible = false
	set_deferred("collision_layer", 0)   # let the attack ray pass through while gone
	get_tree().create_timer(RESPAWN).timeout.connect(_respawn)

func _respawn() -> void:
	_hp = _max
	_depleted = false
	visible = true
	_bar.visible = false
	_set_color(_base_color)
	set_deferred("collision_layer", 1)

func _flash() -> void:
	_set_color(Color.WHITE)
	get_tree().create_timer(0.06).timeout.connect(_unflash)

func _unflash() -> void:
	if not _depleted:
		_set_color(_base_color)

func _set_color(c: Color) -> void:
	if _mat:
		_mat.albedo_color = c
