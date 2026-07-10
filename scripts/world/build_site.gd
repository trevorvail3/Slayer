class_name BuildSite
extends Area3D

## A rebuildable town plot. Shows rubble + a build prompt until you press [E]
## nearby with enough resources; then it becomes the finished building and its
## `on_use` callable (open a vendor, etc.) fires on subsequent interactions.

var building_id := ""
var display_name := ""
var npc_name := ""
var blurb := ""
var cost := {}
var on_use: Callable = Callable()

var _built := false
var _player_near := false
var _rubble: MeshInstance3D
var _structure: MeshInstance3D
var _label: Label3D

func _ready() -> void:
	_build_visuals()
	_built = GameState.is_built(building_id)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.resources_changed.connect(_refresh_label)
	_refresh_visual()

func _build_visuals() -> void:
	_rubble = MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(3.0, 0.6, 3.0)
	_rubble.mesh = rb
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("4a4038")
	_rubble.material_override = rm
	_rubble.position.y = 0.3
	add_child(_rubble)

	_structure = MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(3.2, 3.0, 3.2)
	_structure.mesh = sb
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color("8a7550")
	_structure.material_override = sm
	_structure.position.y = 1.5
	add_child(_structure)

	# Little roof cap so built structures read differently.
	var roof := MeshInstance3D.new()
	var rmesh := BoxMesh.new()
	rmesh.size = Vector3(3.6, 0.5, 3.6)
	roof.mesh = rmesh
	var roofmat := StandardMaterial3D.new()
	roofmat.albedo_color = Color("6a3b2a")
	roof.material_override = roofmat
	roof.position.y = 3.1
	_structure.add_child(roof)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.0, 3.0, 4.0)   # small enough that adjacent plots don't overlap
	col.shape = shape
	col.position.y = 1.5
	add_child(col)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = true
	_label.font_size = 44
	_label.outline_size = 10
	_label.position.y = 4.0
	add_child(_label)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_refresh_label()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_refresh_label()

func _process(_delta: float) -> void:
	if not _player_near or Game.menu_open:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if Input.is_action_just_pressed("interact"):
		if _built:
			if on_use.is_valid():
				on_use.call()
		elif GameState.spend(cost):
			_built = true
			GameState.set_town_built(building_id)
			_refresh_visual()
			_pop()

func _refresh_visual() -> void:
	_rubble.visible = not _built
	_structure.visible = _built
	_refresh_label()

func _refresh_label() -> void:
	if _built:
		_label.text = "%s\n%s" % [display_name, npc_name]
		_label.modulate = Color("e6d29a")
	else:
		var afford := GameState.can_afford(cost)
		var hint := "Build [E]" if _player_near else "Ruined"
		_label.text = "%s — %s\n%s" % [display_name, hint, _cost_text()]
		_label.modulate = Color("d8d8d8") if afford else Color("c98a8a")

func _cost_text() -> String:
	var parts: Array[String] = []
	for k in cost:
		parts.append("%d %s" % [int(cost[k]), String(k).capitalize()])
	return "  ".join(parts)

func _pop() -> void:
	_structure.scale = Vector3(0.6, 0.6, 0.6)
	var t := create_tween()
	t.tween_property(_structure, "scale", Vector3(1.08, 1.08, 1.08), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_structure, "scale", Vector3.ONE, 0.10)
