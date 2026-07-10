class_name Affix
extends Resource

## A single rolled stat on an item, e.g. "+12 Might".
## Stats theme: might, vigor, fortitude, swiftness, ferocity.

@export var stat: String = ""
@export var value: int = 0

func _init(p_stat: String = "", p_value: int = 0) -> void:
	stat = p_stat
	value = p_value

func describe() -> String:
	return "+%d %s" % [value, stat.capitalize()]
