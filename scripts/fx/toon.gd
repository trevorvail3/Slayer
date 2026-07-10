class_name Toon
extends RefCounted

## Cheap cartoon outline via the inverted-hull technique: a back-face-only, unshaded,
## grown copy of the mesh rendered as a second pass. No custom shader — just a
## StandardMaterial3D set as `next_pass`. Assign the result to a material's next_pass.

static func outline(thickness: float = 0.03, color: Color = Color(0.05, 0.04, 0.03)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.albedo_color = color
	m.grow = true
	m.grow_amount = thickness
	return m
