class_name ClassDefs
extends RefCounted

## The three classes and their kit. Like WeaponDefs: data here, behavior in Player.
## Each class has a movement ability, a class ability, and a Ferocity-charged Super.

enum Kind { WARDEN, STALKER, RUNECASTER }

static func get_def(k: int) -> Dictionary:
	match k:
		Kind.STALKER:
			return {
				"name": "Stalker", "color": Color("6ad06a"),
				"blurb": "Agile skirmisher. Dodge through danger, seed the ground with caltrops, and unleash a Blade Storm.",
				"move_name": "Dodge", "move_cd": 3.5,
				"ability_name": "Caltrops", "ability_cd": 12.0,
				"super_name": "Blade Storm",
			}
		Kind.RUNECASTER:
			return {
				"name": "Runecaster", "color": Color("b060ff"),
				"blurb": "Mystic. Blink across the field, drop a healing Rift, and call down a Meteor Storm.",
				"move_name": "Blink", "move_cd": 5.0,
				"ability_name": "Runic Rift", "ability_cd": 16.0,
				"super_name": "Meteor Storm",
			}
		_:
			return {
				"name": "Warden", "color": Color("6a9aff"),
				"blurb": "Immovable bulwark. Dash into the fray, raise a Barricade, and detonate a Ground Slam.",
				"move_name": "Shoulder Dash", "move_cd": 4.0,
				"ability_name": "Barricade", "ability_cd": 14.0,
				"super_name": "Ground Slam",
			}
