class_name DamageNumber
extends Label3D

## Floating combat damage number. Billboards to the camera, floats up, fades out,
## then frees itself. Crits are bigger, gold, and punchier.

func play(amount: int, is_crit: bool) -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	shaded = false
	if is_crit:
		text = "%d!" % amount
		modulate = Color(1.0, 0.82, 0.2)
		font_size = 130
		outline_size = 24
	else:
		text = str(amount)
		modulate = Color(1, 1, 1)
		font_size = 90
		outline_size = 16

	var start_y := position.y
	# Slight horizontal scatter so stacked hits don't overlap perfectly.
	position.x += randf_range(-0.25, 0.25)

	var t := create_tween().set_parallel(true)
	t.tween_property(self, "position:y", start_y + 1.6, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(queue_free)
