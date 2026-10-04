@tool
extends Button

const STONE: Texture2D = preload("res://Assets/UI/Menu/piedra.png")
const FONT: Font = preload("res://Assets/UI/Menu/fonts/menu_font.tres")

@export var lettering_size: int = 26


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_override("font", FONT)
	add_theme_font_size_override("font_size", lettering_size)
	# Conserva el texto del Button para accesibilidad y dibuja su relieve.
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		add_theme_color_override(color_name, Color.TRANSPARENT)
	add_theme_constant_override("outline_size", 0)
	add_theme_stylebox_override("normal", _stone_style(Color.WHITE))
	add_theme_stylebox_override("hover", _stone_style(Color(1.18, 1.22, 1.12)))
	add_theme_stylebox_override("pressed", _stone_style(Color(0.78, 0.91, 0.88), true))
	add_theme_stylebox_override("disabled", _stone_style(Color(0.52, 0.57, 0.56)))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("9bddc5")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(3)
	focus.set_expand_margin_all(-7)
	add_theme_stylebox_override("focus", focus)


func _draw() -> void:
	if text.is_empty():
		return
	var text_width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, lettering_size).x
	var baseline := Vector2((size.x - text_width) * 0.5, (size.y - FONT.get_height(lettering_size)) * 0.5 + FONT.get_ascent(lettering_size))
	var ink := Color("92b3a7")
	if disabled:
		ink = Color("3d605e")
	elif is_pressed():
		baseline.y += 3.0
		ink = Color("729990")
	elif is_hovered() or has_focus():
		ink = Color("c2d6b6")
	# Sombra en el borde superior y luz abajo: letras hundidas en la piedra.
	FONT.draw_string(get_canvas_item(), baseline + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, lettering_size, Color("477f80"))
	FONT.draw_string(get_canvas_item(), baseline + Vector2(0, -2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, lettering_size, Color("031c24"))
	FONT.draw_string(get_canvas_item(), baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, lettering_size, ink)


func _stone_style(tint: Color, pressed: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = STONE
	style.modulate_color = tint
	var border := float(STONE.get_width()) * 0.14
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, border)
		style.set_content_margin(side, 16)
	if pressed:
		style.content_margin_top = 20
		style.content_margin_bottom = 12
	return style
