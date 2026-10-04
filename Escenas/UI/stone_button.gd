@tool
extends Button

const STONE: Texture2D = preload("res://Assets/UI/Menu/piedra.png")
const LONG_STONE: Texture2D = preload("res://Assets/UI/Menu/piedra_alargada.png")
const LONG_REGION := Rect2(40.0 / 2172.0, 176.0 / 724.0, 2092.0 / 2172.0, 376.0 / 724.0)
const FONT: Font = preload("res://Assets/UI/Menu/fonts/menu_font.tres")
const HIGHLIGHT_TINT := Color(1.18, 1.22, 1.12)

@export var lettering_size: int = 26
@export var elongated: bool = false:
	set(value):
		elongated = value
		if is_node_ready():
			_apply_styles()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_override("font", FONT)
	add_theme_font_size_override("font_size", lettering_size)
	# Conserva el texto del Button para accesibilidad y dibuja su relieve.
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color"]:
		add_theme_color_override(color_name, Color.TRANSPARENT)
	add_theme_constant_override("outline_size", 0)
	focus_entered.connect(_update_focus_style)
	focus_exited.connect(_update_focus_style)
	_apply_styles()


func _apply_styles() -> void:
	_update_focus_style()
	add_theme_stylebox_override("hover", _stone_style(HIGHLIGHT_TINT))
	add_theme_stylebox_override("pressed", _stone_style(Color(0.78, 0.91, 0.88), true))
	add_theme_stylebox_override("disabled", _stone_style(Color(0.52, 0.57, 0.56)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _update_focus_style() -> void:
	add_theme_stylebox_override("normal", _stone_style(HIGHLIGHT_TINT if has_focus() else Color.WHITE))


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
	style.texture = LONG_STONE if elongated else STONE
	style.modulate_color = tint
	var border := float(STONE.get_width()) * 0.14
	if elongated:
		# Recorta el margen transparente sin alterar el PNG original.
		var texture_size := LONG_STONE.get_size()
		style.region_rect = Rect2(LONG_REGION.position * texture_size, LONG_REGION.size * texture_size)
		# El grosor depende de la altura, para conservar las esquinas.
		border = style.region_rect.size.y * 0.2
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, border)
		style.set_content_margin(side, 16)
	if pressed:
		style.content_margin_top = 20
		style.content_margin_bottom = 12
	return style
