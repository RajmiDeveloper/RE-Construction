class_name FormCatalog
extends RefCounted

## Catalogo central de formas. Los SpriteFrames se podran asociar cuando
## exista el arte definitivo de cada forma.
enum FormId {
	NORMAL,
	METAL,
	FUEGO,
	ELECTRICA,
}

const NORMAL: int = FormId.NORMAL
const METAL: int = FormId.METAL
const FUEGO: int = FormId.FUEGO
const ELECTRICA: int = FormId.ELECTRICA
const METAL_TINT := Color(0.70, 0.70, 0.70, 1.0)
const METAL_SPRITE_FRAMES: SpriteFrames = preload("res://Escenas/personaje/animacion_metal.tres")
const FUEGO_SPRITE_FRAMES: SpriteFrames = preload("res://Escenas/personaje/animacion_fuego.tres")
const ELECTRICA_SPRITE_FRAMES: SpriteFrames = preload("res://Escenas/personaje/animacion_electrica.tres")

static func is_valid(form_id: int) -> bool:
	return form_id == NORMAL or form_id == METAL or form_id == FUEGO or form_id == ELECTRICA


static func get_display_name(form_id: int) -> String:
	match form_id:
		METAL:
			return "Metal"
		FUEGO:
			return "Fuego"
		ELECTRICA:
			return "Eléctrica"
		_:
			return "Normal"


static func get_tint(form_id: int) -> Color:
	if form_id == METAL:
		return METAL_TINT
	return Color.WHITE


static func get_sprite_frames(form_id: int) -> SpriteFrames:
	if form_id == METAL:
		return METAL_SPRITE_FRAMES
	if form_id == FUEGO:
		return FUEGO_SPRITE_FRAMES
	if form_id == ELECTRICA:
		return ELECTRICA_SPRITE_FRAMES
	return null


static func get_menu_icon(_form_id: int) -> Texture2D:
	# El icono temporal se representa en FormMenu con un simbolo de viga.
	return null
