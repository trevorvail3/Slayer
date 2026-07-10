class_name MainMenu
extends Control

## The start screen (boot scene). Title + New Game / Continue / Quit.
## New Game → choose your Order → story intro → the world.
## Continue → resume the save. All dark-glass + bronze via UITheme.

var _pending_kind: int = ClassDefs.Kind.WARDEN
var _overlay: Control      # character-create or story-intro, when shown

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.menu_open = true
	_build()

func _build() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Title block, upper third.
	var title := Label.new()
	title.text = "SLAYER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", UITheme.GOLD)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 130
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Bear the Mark of Vael"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 250
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	# Button column, centered.
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.position = Vector2(-150, -20)
	col.custom_minimum_size = Vector2(300, 0)
	add_child(col)

	var new_btn := _menu_button("New Game")
	new_btn.pressed.connect(_on_new_game)
	col.add_child(new_btn)

	var cont_btn := _menu_button("Continue")
	cont_btn.disabled = not SaveManager.has_save()
	cont_btn.pressed.connect(_on_continue)
	col.add_child(cont_btn)

	var quit_btn := _menu_button("Quit")
	quit_btn.pressed.connect(_on_quit)
	col.add_child(quit_btn)

	var version := Label.new()
	version.text = "v0.9 — Crafting & god-rolls"
	version.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.position = Vector2(20, -34)
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(version)

func _menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 46)
	b.add_theme_font_size_override("font_size", 22)
	return b

func _on_new_game() -> void:
	var cc := CharacterCreateUI.new()
	cc.chosen.connect(_on_class_chosen)
	cc.cancelled.connect(_close_overlay)
	_show_overlay(cc)

func _on_class_chosen(kind: int) -> void:
	_pending_kind = kind
	_close_overlay()
	var intro := StoryIntro.new()
	intro.finished.connect(_on_intro_finished)
	_show_overlay(intro)

func _on_intro_finished() -> void:
	Game.new_game(_pending_kind)

func _on_continue() -> void:
	Game.continue_game()

func _on_quit() -> void:
	get_tree().quit()

func _show_overlay(node: Control) -> void:
	_close_overlay()
	_overlay = node
	add_child(node)

func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
