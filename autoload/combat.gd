extends Node

## Combat — shared "juice" used across the game: hit-stop (brief slow-mo on
## impact) and floating damage numbers. Kept as an autoload so the player,
## enemies, and future abilities all feed the same feedback layer.

var _hitstop_depth := 0

## Brief global slow-mo on a solid hit. Uses an unscaled timer so the freeze
## duration is real-time even while Engine.time_scale is lowered.
func hitstop(duration := 0.06, scale := 0.06) -> void:
	_hitstop_depth += 1
	Engine.time_scale = scale
	# create_timer(sec, process_always, process_in_physics, ignore_time_scale)
	await get_tree().create_timer(duration, true, false, true).timeout
	_hitstop_depth -= 1
	if _hitstop_depth <= 0:
		_hitstop_depth = 0
		Engine.time_scale = 1.0

## Spawn a floating damage number in the current scene at a world position.
func spawn_damage_number(world_pos: Vector3, amount: int, is_crit: bool) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var dn := DamageNumber.new()
	scene.add_child(dn)
	dn.global_position = world_pos
	dn.play(amount, is_crit)
