class_name ClassShrine
extends Area3D

## A town shrine. Press [E] nearby to open the class-select screen (on_use is set
## by the hub). Purely a hub interactable — no combat.

var on_use: Callable = Callable()

var _player_near := false

func _ready() -> void:
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.8
	bm.bottom_radius = 1.0
	bm.height = 1.4
	base.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("5a4a6a")
	mat.emission_enabled = true
	mat.emission = Color("b060ff")
	mat.emission_energy_multiplier = 0.4
	base.material_override = mat
	base.position.y = 0.7
	add_child(base)

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 3.0
	shape.height = 3.0
	col.shape = shape
	col.position.y = 1.5
	add_child(col)

	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.outline_size = 8
	label.pixel_size = 0.006
	label.position.y = 2.2
	label.text = "SHRINE OF PATHS\nChoose Class [E]"
	label.modulate = Color("d8c8ff")
	add_child(label)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(b: Node) -> void:
	if b.is_in_group("player"):
		_player_near = true

func _on_body_exited(b: Node) -> void:
	if b.is_in_group("player"):
		_player_near = false

func _process(_delta: float) -> void:
	if not _player_near or Game.menu_open:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if Input.is_action_just_pressed("interact") and on_use.is_valid():
		on_use.call()
