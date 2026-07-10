class_name HitBurst
extends GPUParticles3D

## A one-shot particle burst (hit sparks / death puff). Emits once, then frees.

func play(color: Color, count: int = 12, scl: float = 1.0) -> void:
	amount = maxi(2, count)
	lifetime = 0.5
	one_shot = true
	explosiveness = 1.0
	local_coords = false

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 100.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0 * scl
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.4
	pm.scale_max = 1.0
	pm.color = color
	process_material = pm

	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12) * scl
	var dm := StandardMaterial3D.new()
	dm.albedo_color = color
	dm.emission_enabled = true
	dm.emission = color
	dm.emission_energy_multiplier = 2.0
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = dm
	draw_pass_1 = quad

	emitting = true
	get_tree().create_timer(lifetime + 0.3).timeout.connect(queue_free)
