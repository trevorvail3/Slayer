class_name Player
extends CharacterBody3D

## First-person slayer. The equipped weapon's TYPE drives the whole moveset
## (view model, swing/aim animation, damage/pace/reach, and signature trait) via
## WeaponDefs — Destiny-model, any class any weapon. Plus shield block/parry,
## stamina, and camera juice carried over from earlier milestones.

const MOUSE_SENS := 0.0025
const GRAVITY := 20.0
const JUMP_VELOCITY := 5.0

const STAMINA_REGEN := 35.0        # per second, when not blocking
const BLOCK_REDUCTION := 0.7
const PARRY_WINDOW := 0.25
const PARRY_STAGGER := 1.3

const SHIELD_HIDDEN_POS := Vector3(-0.55, -0.85, -0.5)
const SHIELD_BLOCK_POS := Vector3(-0.28, -0.22, -0.42)

var camera: Camera3D
var attack_ray: RayCast3D
var weapon: Node3D
var shield: Node3D

var health: int = 100
var stamina: float = 100.0
var blocking: bool = false

var super_energy := 0.0     # 0..100, charged by dealing damage (Ferocity scales gain)
var move_cd := 0.0          # movement-ability cooldown remaining
var ability_cd := 0.0       # class-ability cooldown remaining

var _pitch := 0.0
var _kick := 0.0
var _can_attack := true
var _parry_timer := 0.0
var _charging := false
var _charge_t := 0.0
var _invuln_timer := 0.0
var _dash_timer := 0.0
var _dash_vel := Vector3.ZERO
var _blade_left := 0
var _meteor_left := 0
var _swing_tween: Tween
var _shield_tween: Tween

func _ready() -> void:
	add_to_group("player")
	_build()
	_refresh_weapon()
	health = PlayerStats.max_health()
	stamina = PlayerStats.max_stamina()
	GameState.equipment_changed.connect(_on_equipment_changed)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.4
	col.shape = shape
	add_child(col)

	camera = Camera3D.new()
	camera.position = Vector3(0, 0.7, 0)
	add_child(camera)

	attack_ray = RayCast3D.new()
	attack_ray.target_position = Vector3(0, 0, -3.2)
	attack_ray.collision_mask = 0xFFFFFFFF
	attack_ray.add_exception(self)
	camera.add_child(attack_ray)

	shield = _make_shield()
	shield.position = SHIELD_HIDDEN_POS
	camera.add_child(shield)

# --- Weapon view models (rebuilt when the equipped weapon changes) ---

func _weapon_type() -> int:
	var w := GameState.equipped.get(ItemData.Slot.WEAPON) as ItemData
	if w == null or w.weapon_type == ItemData.WeaponType.NONE:
		return ItemData.WeaponType.SWORD
	return w.weapon_type

func _weapon_params() -> Dictionary:
	return WeaponDefs.get_def(_weapon_type())

func _refresh_weapon() -> void:
	if weapon and is_instance_valid(weapon):
		weapon.queue_free()
	var p := _weapon_params()
	weapon = _build_weapon_model(_weapon_type(), p["color"])
	weapon.position = p["rest_pos"]
	weapon.rotation_degrees = p["rest_rot"]
	camera.add_child(weapon)

func _build_weapon_model(t: int, color: Color) -> Node3D:
	var root := Node3D.new()
	match t:
		ItemData.WeaponType.GREATSWORD:
			root.add_child(_box(Vector3(0.16, 0.04, 1.35), Vector3(0, 0, -0.70), color))
			root.add_child(_box(Vector3(0.46, 0.09, 0.09), Vector3(0, 0, 0.02), Color("8a8f99")))
			root.add_child(_box(Vector3(0.06, 0.06, 0.34), Vector3(0, 0, 0.20), Color("4a3420")))
			root.add_child(_box(Vector3(0.13, 0.13, 0.08), Vector3(0, 0, 0.40), Color("8a8f99")))
		ItemData.WeaponType.BATTLEAXE:
			root.add_child(_box(Vector3(0.06, 0.06, 1.0), Vector3(0, 0, -0.42), Color("4a3420")))
			root.add_child(_box(Vector3(0.30, 0.05, 0.34), Vector3(0.14, 0, -0.85), color))
			root.add_child(_box(Vector3(0.10, 0.05, 0.20), Vector3(-0.10, 0, -0.85), Color("9aa0ab")))
		ItemData.WeaponType.SPEAR:
			root.add_child(_box(Vector3(0.045, 0.045, 1.7), Vector3(0, 0, -0.75), Color("6a4a2a")))
			root.add_child(_box(Vector3(0.10, 0.04, 0.32), Vector3(0, 0, -1.70), color))
		ItemData.WeaponType.BOW:
			root.add_child(_box(Vector3(0.05, 0.5, 0.05), Vector3(0, 0.28, 0), color))
			root.add_child(_box(Vector3(0.05, 0.5, 0.05), Vector3(0, -0.28, 0), color))
			root.add_child(_box(Vector3(0.05, 0.18, 0.06), Vector3(0.02, 0, 0), Color("3a2a1a")))
			var bstring := _box(Vector3(0.012, 1.05, 0.012), Vector3(-0.08, 0, 0), Color("e8e8e8"))
			bstring.name = "String"
			root.add_child(bstring)
		ItemData.WeaponType.CROSSBOW:
			root.add_child(_box(Vector3(0.06, 0.06, 0.70), Vector3(0, 0, -0.20), Color("4a3420")))
			root.add_child(_box(Vector3(0.70, 0.05, 0.05), Vector3(0, 0, -0.45), color))
			root.add_child(_box(Vector3(0.03, 0.03, 0.5), Vector3(0, 0.05, -0.5), Color("d0d0d0")))
		_:  # SWORD
			root.add_child(_box(Vector3(0.11, 0.03, 0.95), Vector3(0, 0, -0.50), color))
			root.add_child(_box(Vector3(0.34, 0.07, 0.07), Vector3(0, 0, 0.02), Color("9aa0ab")))
			root.add_child(_box(Vector3(0.05, 0.05, 0.24), Vector3(0, 0, 0.16), Color("5a3a22")))
			root.add_child(_box(Vector3(0.10, 0.10, 0.07), Vector3(0, 0, 0.30), Color("c9a24a")))
	return root

func _make_shield() -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(0.5, 0.62, 0.06), Vector3(0, 0, 0), Color("5a4632")))
	root.add_child(_box(Vector3(0.12, 0.12, 0.04), Vector3(0, 0, -0.05), Color("c9ccd6")))
	root.rotation_degrees = Vector3(0, 12, 0)
	return root

func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	m.material_override = mat
	m.position = pos
	return m

func _on_equipment_changed() -> void:
	health = PlayerStats.max_health()
	stamina = PlayerStats.max_stamina()
	_refresh_weapon()

# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.4, 1.4)
	elif event.is_action_pressed("attack"):
		_on_attack_down()
	elif event.is_action_released("attack"):
		_on_attack_up()
	elif event.is_action_pressed("block"):
		_set_block(true)
	elif event.is_action_released("block"):
		_set_block(false)
	elif event.is_action_pressed("dodge"):
		_movement_ability()
	elif event.is_action_pressed("class_ability"):
		_class_ability()
	elif event.is_action_pressed("super"):
		_activate_super()

# --- Frame updates ---

func _process(delta: float) -> void:
	_kick = lerpf(_kick, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	if camera:
		camera.rotation.x = _pitch + _kick

	if _parry_timer > 0.0:
		_parry_timer -= delta

	if _charging:
		_charge_t = minf(1.0, _charge_t + delta)
		_set_bow_draw(clampf(_charge_t / 0.9, 0.0, 1.0))

	if not blocking:
		stamina = minf(PlayerStats.max_stamina(), stamina + STAMINA_REGEN * delta)

	move_cd = maxf(0.0, move_cd - delta)
	ability_cd = maxf(0.0, ability_cd - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	# Passive Super trickle (Ferocity scales it a little).
	_gain_super(2.5 * delta)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	var input_dir := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("move_forward"):
			input_dir.y -= 1.0
		if Input.is_action_pressed("move_back"):
			input_dir.y += 1.0
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1.0
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var speed := PlayerStats.move_speed() * (0.4 if blocking else 1.0)
	var dir := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	# A dash/dodge burst overrides normal horizontal movement while it lasts.
	if _dash_timer > 0.0:
		velocity.x = _dash_vel.x
		velocity.z = _dash_vel.z

	move_and_slide()

# --- Attacking ---

func _on_attack_down() -> void:
	if blocking or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var p := _weapon_params()
	if not _can_attack or stamina < float(p["stamina"]):
		return
	if p["ranged"] and p["charge"]:
		_charging = true
		_charge_t = 0.0
	elif p["ranged"]:
		_fire_projectile(p, 1.0)
		_after_attack(p)
	else:
		_melee_swing(p)
		_after_attack(p)

func _on_attack_up() -> void:
	if not _charging:
		return
	_charging = false
	var p := _weapon_params()
	_set_bow_draw(0.0)
	if stamina < float(p["stamina"]):
		return
	var frac := clampf(_charge_t / 0.9, 0.35, 1.0)
	_fire_projectile(p, frac)
	_after_attack(p)

func _after_attack(p: Dictionary) -> void:
	_can_attack = false
	stamina -= float(p["stamina"])
	get_tree().create_timer(float(p["cooldown"])).timeout.connect(func(): _can_attack = true)

func _set_bow_draw(frac: float) -> void:
	if weapon == null:
		return
	var s := weapon.get_node_or_null("String")
	if s:
		(s as Node3D).position.z = 0.18 * frac   # pull the string toward the archer

# Melee: swing the view model, then land the hit at the strike moment.
func _melee_swing(p: Dictionary) -> void:
	if _swing_tween and _swing_tween.is_valid():
		_swing_tween.kill()
	var rest_rot: Vector3 = p["rest_rot"]
	var rest_pos: Vector3 = p["rest_pos"]
	weapon.rotation_degrees = rest_rot
	weapon.position = rest_pos
	_swing_tween = create_tween()

	if p["anim"] == "thrust":
		var fwd := rest_pos + Vector3(0, 0, -0.45)
		_swing_tween.tween_property(weapon, "position", fwd, float(p["windup"]) + 0.06) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_swing_tween.tween_callback(_melee_hit.bind(p))
		_swing_tween.tween_property(weapon, "position", rest_pos, 0.18).set_trans(Tween.TRANS_QUAD)
	else:
		var windup: Vector3 = p["windup_rot"]
		var strike: Vector3 = p["strike_rot"]
		_swing_tween.tween_property(weapon, "rotation_degrees", windup, maxf(0.06, float(p["windup"]) * 0.6)) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_swing_tween.tween_property(weapon, "rotation_degrees", strike, float(p["windup"])) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_swing_tween.tween_callback(_melee_hit.bind(p))
		_swing_tween.tween_property(weapon, "rotation_degrees", rest_rot, 0.20) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _melee_hit(p: Dictionary) -> void:
	var dmg := int(PlayerStats.attack_damage() * float(p["dmg_mult"]))
	var is_crit := randf() < PlayerStats.crit_chance()
	if is_crit:
		dmg = int(dmg * PlayerStats.crit_multiplier())
	if p["sweep"]:
		_sweep_hit(dmg, is_crit, p)
	else:
		_ray_hit(dmg, is_crit, p)

func _ray_hit(dmg: int, is_crit: bool, p: Dictionary) -> void:
	attack_ray.target_position = Vector3(0, 0, -float(p["range"]))
	attack_ray.force_raycast_update()
	if not attack_ray.is_colliding():
		return
	var target := attack_ray.get_collider() as Node
	if target == null or not target.has_method("take_damage"):
		return
	if not (target.is_in_group("enemy") or target.is_in_group("gatherable")):
		return
	target.call("take_damage", dmg, is_crit, global_position)
	if p["bleed"] and target.is_in_group("enemy") and target.has_method("apply_bleed"):
		target.call("apply_bleed", maxi(1, int(dmg * 0.15)), 4)
	if target.is_in_group("enemy"):
		_gain_super(9.0 if is_crit else 6.0)
	Combat.hitstop(0.07, 0.06)
	_kick += 0.05

func _sweep_hit(dmg: int, is_crit: bool, p: Dictionary) -> void:
	var origin := camera.global_position
	var fwd := -camera.global_transform.basis.z
	var reach: float = float(p["range"]) + 0.6
	var hit := false
	for e in get_tree().get_nodes_in_group("enemy"):
		var n := e as Node3D
		if n == null:
			continue
		var to: Vector3 = (n.global_position + Vector3(0, 1.0, 0)) - origin
		if to.length() > reach:
			continue
		if fwd.dot(to.normalized()) < 0.35:      # ~70-degree frontal arc
			continue
		n.call("take_damage", dmg, is_crit, global_position)
		_gain_super(5.0)
		hit = true
	for g in get_tree().get_nodes_in_group("gatherable"):
		var gn := g as Node3D
		if gn == null:
			continue
		var tg: Vector3 = (gn.global_position + Vector3(0, 1.0, 0)) - origin
		if tg.length() <= reach and fwd.dot(tg.normalized()) >= 0.5 and gn.has_method("take_damage"):
			gn.call("take_damage", dmg, is_crit, global_position)
			hit = true
			break
	if hit:
		Combat.hitstop(0.09, 0.06)
		_kick += 0.06

func _fire_projectile(p: Dictionary, charge_frac: float) -> void:
	var dmg := int(PlayerStats.attack_damage() * float(p["dmg_mult"]) * charge_frac)
	var dir := -camera.global_transform.basis.z
	var arrow := Arrow.new()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = camera.global_position + dir * 0.6
	var crit := PlayerStats.crit_chance() + (0.15 if charge_frac >= 0.95 else 0.0)
	arrow.setup(dir, 45.0, dmg, crit)
	_gain_super(6.0)
	_kick += 0.05
	if weapon:
		var rest: Vector3 = p["rest_pos"]
		weapon.position = rest + Vector3(0, 0, 0.12)
		var t := create_tween()
		t.tween_property(weapon, "position", rest, 0.12)

# --- Class abilities & Super (driven by GameState.player_class) ---

func _gain_super(amount: float) -> void:
	var mult := 1.0 + GameState.total_stat("ferocity") * 0.03
	super_energy = minf(100.0, super_energy + amount * mult)

func _facing_flat() -> Vector3:
	var f := -camera.global_transform.basis.z
	f.y = 0.0
	return f.normalized()

func _movement_ability() -> void:
	if move_cd > 0.0 or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var d := ClassDefs.get_def(GameState.player_class)
	move_cd = float(d["move_cd"])
	match GameState.player_class:
		ClassDefs.Kind.STALKER:
			var dir := transform.basis * Vector3(_move_input().x, 0.0, _move_input().y)
			if dir.length() < 0.1:
				dir = -_facing_flat()   # dodge backward if standing still
			_dash_vel = dir.normalized() * 12.0
			_dash_timer = 0.22
			_invuln_timer = 0.45
		ClassDefs.Kind.RUNECASTER:
			_blink(8.0)
		_:  # WARDEN shoulder dash
			_dash_vel = _facing_flat() * 13.0
			_dash_timer = 0.24

func _move_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_forward"): v.y -= 1.0
	if Input.is_action_pressed("move_back"): v.y += 1.0
	if Input.is_action_pressed("move_left"): v.x -= 1.0
	if Input.is_action_pressed("move_right"): v.x += 1.0
	return v

func _blink(dist: float) -> void:
	var fwd := _facing_flat()
	var from := global_position + Vector3(0, 1.0, 0)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + fwd * dist)
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	var travel := dist
	if hit:
		travel = maxf(0.5, from.distance_to(hit.position) - 1.0)
	global_position += fwd * travel

func _class_ability() -> void:
	if ability_cd > 0.0 or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var d := ClassDefs.get_def(GameState.player_class)
	ability_cd = float(d["ability_cd"])
	var ground := global_position + _facing_flat() * 2.5
	ground.y = 0.0
	match GameState.player_class:
		ClassDefs.Kind.STALKER:
			var c := Caltrops.new()
			c.damage = int(6 + GameState.gear_score() * 0.3)
			get_tree().current_scene.add_child(c)
			c.global_position = ground
		ClassDefs.Kind.RUNECASTER:
			var r := Rift.new()
			r.heal_amount = int(PlayerStats.max_health() * 0.04)
			get_tree().current_scene.add_child(r)
			r.global_position = ground
		_:  # WARDEN barricade
			var b := Barricade.new()
			get_tree().current_scene.add_child(b)
			b.global_position = ground
			b.rotation.y = rotation.y

func _activate_super() -> void:
	if super_energy < 100.0 or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	super_energy = 0.0
	match GameState.player_class:
		ClassDefs.Kind.STALKER:
			_blade_left = 8
			_blade_tick()
		ClassDefs.Kind.RUNECASTER:
			_meteor_left = 6
			_meteor_tick()
		_:
			_super_ground_slam()

func _super_ground_slam() -> void:
	var burst := SuperBurst.new()
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position
	burst.play(8.0, Color("6a9aff"))
	_aoe_damage(global_position, 8.0, int(PlayerStats.attack_damage() * 4.0), true)
	Combat.hitstop(0.12, 0.05)
	_kick += 0.2

func _blade_tick() -> void:
	if _blade_left <= 0:
		return
	_blade_left -= 1
	var burst := SuperBurst.new()
	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position + _facing_flat() * 1.5 + Vector3(0, 1.0, 0)
	burst.play(3.0, Color("6ad06a"))
	_aoe_damage(global_position, 6.0, int(PlayerStats.attack_damage() * 1.1), false)
	_kick += 0.06
	get_tree().create_timer(0.16).timeout.connect(_blade_tick)

func _meteor_tick() -> void:
	if _meteor_left <= 0:
		return
	_meteor_left -= 1
	var center := _pick_meteor_target()
	var burst := SuperBurst.new()
	get_tree().current_scene.add_child(burst)
	burst.global_position = center
	burst.play(4.0, Color("b060ff"))
	_aoe_damage(center, 4.0, int(PlayerStats.attack_damage() * 2.2), true)
	get_tree().create_timer(0.32).timeout.connect(_meteor_tick)

func _pick_meteor_target() -> Vector3:
	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		var e := enemies[randi() % enemies.size()] as Node3D
		if e:
			return e.global_position
	return global_position + _facing_flat() * randf_range(4.0, 8.0) + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))

func _aoe_damage(center: Vector3, radius: float, dmg: int, knock_from_center: bool) -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		var n := e as Node3D
		if n == null:
			continue
		if n.global_position.distance_to(center) <= radius and n.has_method("take_damage"):
			var src := center if knock_from_center else global_position
			n.call("take_damage", dmg, true, src)

func heal(amount: int) -> void:
	health = mini(PlayerStats.max_health(), health + amount)

# --- Blocking / parrying ---

func _set_block(on: bool) -> void:
	if on and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	blocking = on
	if on:
		_parry_timer = PARRY_WINDOW
	_animate_shield(on)

func _animate_shield(up: bool) -> void:
	if _shield_tween and _shield_tween.is_valid():
		_shield_tween.kill()
	_shield_tween = create_tween()
	var target_pos := SHIELD_BLOCK_POS if up else SHIELD_HIDDEN_POS
	_shield_tween.tween_property(shield, "position", target_pos, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# --- Taking damage ---

func take_damage(amount: int, attacker: Node = null) -> void:
	if _invuln_timer > 0.0:
		return   # Stalker dodge i-frames
	if blocking:
		if _parry_timer > 0.0 and attacker and attacker.has_method("stagger"):
			attacker.call("stagger", PARRY_STAGGER)
			Combat.hitstop(0.11, 0.05)
			_kick += 0.10
			return
		amount = int(amount * (1.0 - BLOCK_REDUCTION))

	var reduced := int(amount * (1.0 - PlayerStats.damage_reduction()))
	health -= maxi(1, reduced)
	_kick += 0.05
	if health <= 0:
		health = PlayerStats.max_health()
		stamina = PlayerStats.max_stamina()
		global_position = Vector3(0, 2, 8)
