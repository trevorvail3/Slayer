class_name UIWidgets
extends RefCounted

## Shared looter UI widgets so item rows read the same everywhere (inventory /
## forge / vault): rarity-tinted rows with a colored edge, consistent item text,
## and glass "section" panels. Keeps the menus consistent and marketable.

## An interactive, rarity-tinted item row. Caller connects `pressed`.
static func item_button(item: ItemData, suffix := "") -> Button:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	var c := item.display_color()
	b.add_theme_stylebox_override("normal", _row_style(c, 0.10))
	b.add_theme_stylebox_override("hover", _row_style(c, 0.22))
	b.add_theme_stylebox_override("pressed", _row_style(c, 0.28))
	b.add_theme_stylebox_override("focus", _row_style(c, 0.22))
	b.add_theme_color_override("font_color", c.lightened(0.35))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.text = item_text(item, suffix)
	return b

## A non-interactive rarity-tinted row (for equipped slots), with an optional
## prefix like "Weapon:  ".
static func item_display(item: ItemData, prefix := "") -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var c := item.display_color()
	p.add_theme_stylebox_override("panel", _row_style(c, 0.10))
	var l := Label.new()
	l.text = prefix + item_text(item)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", c.lightened(0.35))
	p.add_child(l)
	return p

## The canonical one-line item description used on every row.
static func item_text(item: ItemData, suffix := "") -> String:
	var wt := ""
	if item.slot == ItemData.Slot.WEAPON and item.weapon_type != ItemData.WeaponType.NONE:
		wt = "  (%s)" % item.weapon_type_name()
	var star := "  ★" if LootManager.is_god_roll(item) else ""
	var line := "%s%s%s    ·    %s  ·  Pow %d" % [item.name, wt, star, item.rarity.name, item.power]
	for a in item.affixes:
		line += "    " + a.describe()
	if suffix != "":
		line += suffix
	return line

static func _row_style(c: Color, alpha: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(c.r, c.g, c.b, alpha)
	s.set_corner_radius_all(4)
	s.border_width_left = 4
	s.border_color = c
	s.content_margin_left = 12
	s.content_margin_right = 10
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s

## A glass section panel with a Cinzel heading. Returns {panel, body, heading}:
## add content to `body` (a VBox); `panel` is what you place in the layout.
static func section(title_text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var h := Label.new()
	h.text = title_text
	UITheme.style_title(h, 22)
	v.add_child(h)
	return {"panel": panel, "body": v, "heading": h}
