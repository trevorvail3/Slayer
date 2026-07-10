class_name AssetLoader
extends RefCounted

## Optional-asset loader for the art pipeline (v0.9 art scaffolding).
##
## The whole point: every method is a safe no-op that returns null / false when
## the file isn't there. The game keeps running on its procedural primitives
## until real assets are dropped into `assets/`. Drop a .glb / .png / .hdr in
## (while Godot is CLOSED, then reopen so it imports), and the callers below
## pick it up automatically — no code change needed.
##
## Conventions (see docs/Art Pipeline.md):
##   assets/models/    *.glb / *.gltf   — meshes, optionally rigged + animated
##   assets/textures/  *.png / *.jpg    — ground/prop textures
##   assets/skies/     *.hdr/.exr/.png  — equirectangular (panorama) sky photos

static var _scene_cache := {}
static var _tex_cache := {}

## True if an imported resource actually exists at this res:// path.
static func exists(path: String) -> bool:
	return path != "" and ResourceLoader.exists(path)

## First path in the list that exists, or "" if none do. Lets callers accept
## several file extensions (e.g. a sky dropped as .hdr OR .exr OR .png).
static func first_existing(paths: Array) -> String:
	for p in paths:
		if exists(String(p)):
			return String(p)
	return ""

## Load a .glb/.gltf/.tscn and return a FRESH instance, or null if absent.
## Caller falls back to its procedural build when this returns null.
static func instance_model(path: String) -> Node3D:
	if not exists(path):
		return null
	var ps: PackedScene = _scene_cache.get(path, null)
	if ps == null:
		var res := load(path)
		if res is PackedScene:
			ps = res
			_scene_cache[path] = ps
		else:
			return null
	return ps.instantiate() as Node3D

## Load a Texture2D (PNG/JPG/HDR/EXR...), cached, or null if absent.
static func load_texture(path: String) -> Texture2D:
	if not exists(path):
		return null
	var t: Texture2D = _tex_cache.get(path, null)
	if t == null:
		var res := load(path)
		if res is Texture2D:
			t = res
			_tex_cache[path] = t
	return t

## Build a panorama Sky from an equirectangular image, or null if absent.
static func load_panorama_sky(path: String) -> Sky:
	var tex := load_texture(path)
	if tex == null:
		return null
	var mat := PanoramaSkyMaterial.new()
	mat.panorama = tex
	var sky := Sky.new()
	sky.sky_material = mat
	return sky

## Paint an existing ground box (a StaticBody3D from `_static_box`) with a tiling
## texture. No-op if the body has no mesh or the texture is absent (keeps color).
## `units_per_tile` = how many world units one texture repeat covers.
static func apply_ground_texture(body: Node, path: String, units_per_tile := 6.0) -> bool:
	# Accept whatever extension the artist shipped (Poly Haven diffuse is often
	# .jpg; we asked for .png) so the drop-in "just works" either way.
	var resolved := path
	if not exists(resolved):
		var base := path.get_basename()
		resolved = first_existing([base + ".png", base + ".jpg", base + ".jpeg", base + ".webp"])
	var tex := load_texture(resolved)
	if body == null or tex == null:
		return false
	var mi := _first_mesh(body)
	if mi == null:
		return false
	var mat := mi.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mi.material_override = mat
	mat.albedo_texture = tex
	mat.albedo_color = Color.WHITE   # else the flat ground tint multiplies the texture
	var sz := Vector3.ONE
	if mi.mesh is BoxMesh:
		sz = (mi.mesh as BoxMesh).size
	var per: float = maxf(0.001, units_per_tile)
	mat.uv1_scale = Vector3(sz.x / per, sz.z / per, 1.0)
	return true

## Find the first AnimationPlayer inside a loaded model (searches all
## descendants regardless of ownership), or null.
static func find_anim_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	for child in root.find_children("*", "AnimationPlayer", true, false):
		return child as AnimationPlayer
	return null

## Play the first animation whose name contains (case-insensitive) any of the
## candidate words — so callers can ask for ["walk", "run"] and get whatever the
## artist named it. Returns true if something matched and is now playing.
static func play_anim(ap: AnimationPlayer, candidates: Array, loop := true) -> bool:
	if ap == null:
		return false
	var list := ap.get_animation_list()
	for want in candidates:
		var w := String(want).to_lower()
		for have in list:
			if String(have).to_lower().find(w) != -1:
				if ap.current_animation != String(have):
					ap.play(String(have))
				return true
	return false

## Combined bounding box of every MeshInstance3D under `root`, in root-local
## space. Lets us auto-size an arbitrary downloaded model without magic numbers.
static func combined_aabb(root: Node3D) -> AABB:
	var acc := AABB()
	var has := false
	var inv := root.global_transform.affine_inverse()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box: AABB = (inv * mi.global_transform) * mi.mesh.get_aabb()
		if not has:
			acc = box
			has = true
		else:
			acc = acc.merge(box)
	return acc

## Uniformly scale a freshly-instanced model so its LONGEST dimension is
## `target_max` units, then seat it so its lowest point rests at y = 0. Works for
## any model regardless of the units it was authored in. Call before parenting
## transforms are set (expects the instance already in the tree).
static func fit_to_size(inst: Node3D, target_max: float) -> void:
	if inst == null:
		return
	var box := combined_aabb(inst)
	var dim: float = maxf(box.size.x, maxf(box.size.y, box.size.z))
	if dim <= 0.0001:
		return
	var sc := target_max / dim
	inst.scale = Vector3(sc, sc, sc)
	inst.position.y = -box.position.y * sc

## Force every animation on this player to loop (imported glTF clips often
## default to play-once, which looks like a freeze for walk/run/idle).
static func set_all_loop(ap: AnimationPlayer) -> void:
	if ap == null:
		return
	for anim_name in ap.get_animation_list():
		var a := ap.get_animation(anim_name)
		if a:
			a.loop_mode = Animation.LOOP_LINEAR

## Turn a region/display name into a texture filename slug, e.g.
## "The Olive Plains" -> "olive_plains" (drops a leading "the ").
static func slugify(display_name: String) -> String:
	var s := display_name.strip_edges().to_lower()
	if s.begins_with("the "):
		s = s.substr(4)
	var out := ""
	for i in s.length():
		var c := s[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
		elif out.length() > 0 and not out.ends_with("_"):
			out += "_"
	return out.trim_suffix("_")

static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
	return null
