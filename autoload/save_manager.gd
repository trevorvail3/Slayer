extends Node

## SaveManager — persists GameState to disk as JSON. Called on travel/build/quit,
## loaded on startup by the Game autoload.

const PATH := "user://slayer_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(PATH)

func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Slayer: could not open save file for writing.")
		return
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	f.close()

func load_game() -> void:
	if not has_save():
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) == TYPE_DICTIONARY:
		GameState.from_dict(data)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)
