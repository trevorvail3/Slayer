class_name StoryIntro
extends Control

## The opening: the creation myth and who you are, as a stylized fading screen.
## Emits `finished` when the player continues past it. Bones of the narrative —
## later this can become a fuller cinematic; for now it sets the world + your role.

signal finished

const LINES := [
	"In the time before time, there were two gods.",
	"Vael, of the dark.   Aldmar, of the light.",
	"She struck him down — once, from the shadow —",
	"and his vast body became the world: Aldermoor.",
	"",
	"Why she did it, no one agrees. That wound of a question",
	"split mankind into warring faiths, and the faiths into war.",
	"",
	"You are a Slayer, marked by Vael's own hand —",
	"a mortal who fights like a demigod.",
	"",
	"The Reach is restless. Take up your blade.",
]

var _body: VBoxContainer
var _continue: Button
var _tween: Tween

func _ready() -> void:
	_build()
	_play()

func _build() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.02, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	col.add_child(_body)
	for line in LINES:
		var l := Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", UITheme.TEXT)
		l.modulate.a = 0.0
		_body.add_child(l)

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 24)
	col.add_child(pad)

	_continue = Button.new()
	_continue.text = "Take up your blade  ›"
	_continue.custom_minimum_size = Vector2(280, 0)
	_continue.modulate.a = 0.0
	_continue.pressed.connect(_finish)
	var wrap := CenterContainer.new()
	wrap.add_child(_continue)
	col.add_child(wrap)

	var skip := Button.new()
	skip.text = "Skip"
	skip.flat = true
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.position = Vector2(-110, -56)
	skip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	skip.pressed.connect(_finish)
	add_child(skip)

## Fade the lines in one after another, then reveal the Continue button.
func _play() -> void:
	_tween = create_tween()
	for l in _body.get_children():
		var label := l as Label
		if label.text == "":
			_tween.tween_interval(0.12)
			continue
		_tween.tween_property(label, "modulate:a", 1.0, 0.5)
		_tween.tween_interval(0.25)
	_tween.tween_property(_continue, "modulate:a", 1.0, 0.6)

func _finish() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	finished.emit()
