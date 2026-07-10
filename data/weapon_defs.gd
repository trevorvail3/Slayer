class_name WeaponDefs
extends RefCounted

## Central per-archetype behavior table (Destiny model: the equipped weapon's
## type drives the moveset). One dictionary per weapon type describing combat
## params, the swing animation, view-model color, and hold pose. Player reads
## this every attack via get_def(weapon_type).

## Fields:
##  ranged/charge/sweep/bleed : bools (behavior flags)
##  dmg_mult, cooldown, windup, range, stamina : numbers
##  anim : "slash" | "overhead" | "chop" | "thrust" | "aim"
##  color : view-model tint
##  rest_pos/rest_rot : where/how the weapon is held (local to camera)
##  windup_rot/strike_rot : euler poses for rotational swings

static func get_def(t: int) -> Dictionary:
	match t:
		ItemData.WeaponType.GREATSWORD:
			return {
				"ranged": false, "charge": false, "sweep": true, "bleed": false,
				"dmg_mult": 2.3, "cooldown": 0.95, "windup": 0.30, "range": 3.8, "stamina": 30.0,
				"anim": "overhead", "color": Color("aeb6c6"),
				"rest_pos": Vector3(0.30, -0.42, -0.60), "rest_rot": Vector3(48, 14, 6),
				"windup_rot": Vector3(-95, 10, 6), "strike_rot": Vector3(60, -6, -4),
			}
		ItemData.WeaponType.BATTLEAXE:
			return {
				"ranged": false, "charge": false, "sweep": false, "bleed": true,
				"dmg_mult": 1.6, "cooldown": 0.70, "windup": 0.20, "range": 3.2, "stamina": 22.0,
				"anim": "chop", "color": Color("b98c5a"),
				"rest_pos": Vector3(0.34, -0.40, -0.55), "rest_rot": Vector3(52, 20, 10),
				"windup_rot": Vector3(-80, 40, 30), "strike_rot": Vector3(55, -20, -20),
			}
		ItemData.WeaponType.SPEAR:
			return {
				"ranged": false, "charge": false, "sweep": false, "bleed": false,
				"dmg_mult": 1.15, "cooldown": 0.48, "windup": 0.10, "range": 5.0, "stamina": 14.0,
				"anim": "thrust", "color": Color("c9a24a"),
				"rest_pos": Vector3(0.32, -0.34, -0.62), "rest_rot": Vector3(8, 6, 2),
				"windup_rot": Vector3(8, 6, 2), "strike_rot": Vector3(8, 6, 2),
			}
		ItemData.WeaponType.BOW:
			return {
				"ranged": true, "charge": true, "sweep": false, "bleed": false,
				"dmg_mult": 1.5, "cooldown": 0.25, "windup": 0.0, "range": 60.0, "stamina": 12.0,
				"anim": "aim", "color": Color("8a5a32"),
				"rest_pos": Vector3(0.20, -0.22, -0.52), "rest_rot": Vector3(0, 10, 8),
				"windup_rot": Vector3.ZERO, "strike_rot": Vector3.ZERO,
			}
		ItemData.WeaponType.CROSSBOW:
			return {
				"ranged": true, "charge": false, "sweep": false, "bleed": false,
				"dmg_mult": 0.7, "cooldown": 0.55, "windup": 0.0, "range": 60.0, "stamina": 10.0,
				"anim": "aim", "color": Color("7a6a52"),
				"rest_pos": Vector3(0.24, -0.26, -0.48), "rest_rot": Vector3(0, 4, 0),
				"windup_rot": Vector3.ZERO, "strike_rot": Vector3.ZERO,
			}
		_:  # SWORD (and NONE/default)
			return {
				"ranged": false, "charge": false, "sweep": false, "bleed": false,
				"dmg_mult": 1.0, "cooldown": 0.5, "windup": 0.19, "range": 3.2, "stamina": 12.0,
				"anim": "slash", "color": Color("d6dae4"),
				# A wide diagonal slash: cocked over the right shoulder, then carved
				# down and across the body to a low-left follow-through (~150° sweep).
				"rest_pos": Vector3(0.33, -0.38, -0.55), "rest_rot": Vector3(34, 22, 12),
				"windup_rot": Vector3(-28, 78, 40), "strike_rot": Vector3(48, -80, -60),
			}
