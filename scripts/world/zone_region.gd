class_name ZoneRegion
extends RefCounted

## A named sub-region of the open zone (Destiny-style: "The Olive Plains", "The
## Barrowlands"...). Owns its rect on the XZ plane, its power band, its ground
## color, and a weighted enemy table the spawner draws from.
## Enemy table entries: { "kind": Enemy.Kind, "name": String, "color": Color, "weight": float }

var id := ""
var display_name := ""
var subtitle := ""
var rect := Rect2()          # x = world X, y = world Z (min corner) + size
var power_min := 8
var power_max := 14
var max_enemies := 6
var elite_chance := 0.06
var ground_color := Color("55603a")
var enemy_table: Array = []

func contains(pos: Vector3) -> bool:
	return rect.has_point(Vector2(pos.x, pos.z))

func center() -> Vector3:
	var c := rect.get_center()
	return Vector3(c.x, 0.0, c.y)

## Distance from a world position to this region (0 if inside).
func distance_to(pos: Vector3) -> float:
	var p := Vector2(pos.x, pos.z)
	var clamped := Vector2(
		clampf(p.x, rect.position.x, rect.end.x),
		clampf(p.y, rect.position.y, rect.end.y))
	return p.distance_to(clamped)

func random_point(margin := 6.0) -> Vector3:
	var x := randf_range(rect.position.x + margin, rect.end.x - margin)
	var z := randf_range(rect.position.y + margin, rect.end.y - margin)
	return Vector3(x, 3.0, z)

func roll_power() -> int:
	return randi_range(power_min, power_max)

## Weighted pick from the enemy table.
func pick_enemy() -> Dictionary:
	var total := 0.0
	for e in enemy_table:
		total += float(e["weight"])
	var r := randf() * total
	var acc := 0.0
	for e in enemy_table:
		acc += float(e["weight"])
		if r <= acc:
			return e
	return enemy_table[0]
