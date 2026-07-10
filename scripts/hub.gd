extends Node3D

## Hub — the safe town you rebuild. No combat. Gather from resource nodes, press
## [E] at ruined plots to raise buildings (each unlocks an NPC/vendor), use the
## Blacksmith and Vault, and step on the pad to travel to the wilds.

const GROUND_HALF := 30.0

var hud: HUD
var player: Player
var blacksmith_ui: BlacksmithUI
var vault_ui: VaultUI
var class_ui: ClassSelectUI

func _ready() -> void:
	_build_environment()
	_build_ground()
	_add_ui()
	_spawn_player()
	_build_town()
	_spawn_class_shrine()
	_scatter_resources()
	_spawn_travel_pad()
	GameState.town_changed.connect(_update_guidance)
	_update_guidance()

func _spawn_class_shrine() -> void:
	var shrine := ClassShrine.new()
	shrine.on_use = func(): class_ui.open()
	add_child(shrine)
	shrine.position = Vector3(7, 0, 3)   # clear of the monument and build plots

func _build_environment() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.3
	light.shadow_enabled = true
	add_child(light)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var skymat := ProceduralSkyMaterial.new()
	skymat.sky_top_color = Color("3a6bb0")
	skymat.sky_horizon_color = Color("cfc0a0")
	skymat.ground_horizon_color = Color("6a6250")
	sky.sky_material = skymat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.1
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_ground() -> void:
	_static_box(Vector3(0, -0.5, 0), Vector3(GROUND_HALF * 2, 1, GROUND_HALF * 2), Color("4a6b3a"))
	# Plaza stone tile in the middle.
	_static_box(Vector3(0, 0.01, -2), Vector3(22, 0.1, 16), Color("7d7566"))
	# A little well/monument at town center.
	_static_box(Vector3(0, 0.5, 4), Vector3(2.4, 1.0, 2.4), Color("6a6a72"))
	# Perimeter fence hint (low walls) so the town feels bounded.
	_static_box(Vector3(0, 1, -GROUND_HALF), Vector3(GROUND_HALF * 2, 2, 0.6), Color("5a4a35"))
	_static_box(Vector3(0, 1, GROUND_HALF), Vector3(GROUND_HALF * 2, 2, 0.6), Color("5a4a35"))
	_static_box(Vector3(-GROUND_HALF, 1, 0), Vector3(0.6, 2, GROUND_HALF * 2), Color("5a4a35"))
	_static_box(Vector3(GROUND_HALF, 1, 0), Vector3(0.6, 2, GROUND_HALF * 2), Color("5a4a35"))

func _static_box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body

func _add_ui() -> void:
	hud = HUD.new()
	add_child(hud)
	var layer := CanvasLayer.new()
	layer.layer = 2
	layer.add_child(InventoryUI.new())
	blacksmith_ui = BlacksmithUI.new()
	layer.add_child(blacksmith_ui)
	vault_ui = VaultUI.new()
	layer.add_child(vault_ui)
	class_ui = ClassSelectUI.new()
	layer.add_child(class_ui)
	add_child(layer)

func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector3(0, 2, 10)
	add_child(player)

func _build_town() -> void:
	_add_build_site("waypoint", Vector3(-10, 0, -6), func(): hud.notify("The waystone hums. Safe roads, slayer.", Color("9fd0ff")))
	_add_build_site("blacksmith", Vector3(-4, 0, -9), func(): blacksmith_ui.open())
	_add_build_site("vault", Vector3(4, 0, -9), func(): vault_ui.open())
	_add_build_site("tavern", Vector3(10, 0, -6), func(): hud.notify("Sella: \"Bounties are coming soon, slayer.\"", Color("e6c86a")))

func _add_build_site(id: String, pos: Vector3, use_callable: Callable) -> void:
	var def: Dictionary = Catalog.buildings[id]
	var site := BuildSite.new()
	site.building_id = id
	site.display_name = def["name"]
	site.npc_name = def["npc"]
	site.blurb = def.get("blurb", "")
	site.cost = def["cost"]
	site.on_use = use_callable
	add_child(site)
	site.position = pos

func _scatter_resources() -> void:
	var trees := [Vector3(-20, 0, 8), Vector3(-24, 0, -2), Vector3(-18, 0, -14), Vector3(22, 0, 10), Vector3(18, 0, -16), Vector3(24, 0, 2), Vector3(-14, 0, 16), Vector3(14, 0, 18)]
	for p in trees:
		_add_node(ResourceNode.Kind.TREE, p)
	var rocks := [Vector3(-26, 0, 14), Vector3(26, 0, -10), Vector3(-22, 0, 20), Vector3(20, 0, 22)]
	for p in rocks:
		_add_node(ResourceNode.Kind.ROCK, p)
	var ores := [Vector3(-28, 0, -12), Vector3(28, 0, 16), Vector3(-16, 0, 22)]
	for p in ores:
		_add_node(ResourceNode.Kind.ORE, p)

func _add_node(kind: ResourceNode.Kind, pos: Vector3) -> void:
	var node := ResourceNode.new()
	node.kind = kind
	add_child(node)
	node.position = pos

func _spawn_travel_pad() -> void:
	var pad := TravelPad.new()
	pad.to_zone = true
	add_child(pad)
	pad.position = Vector3(0, 0, -22)   # the town gate, north end

func _update_guidance() -> void:
	if hud == null:
		return
	var tier := GameState.town_tier()
	if tier == 0:
		hud.set_objective("Rebuild the town — chop trees & mine rock, then press [E] at a ruin")
	else:
		hud.set_objective("Bastion — Tier %d   ·   gate north → the wilds" % tier)
