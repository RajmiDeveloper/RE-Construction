class_name FormCatalog
extends RefCounted

## Catalogo central de formas. Los SpriteFrames se podran asociar cuando
## exista el arte definitivo de cada forma.
enum FormId {
	NORMAL,
	METAL,
}

const NORMAL: int = FormId.NORMAL
const METAL: int = FormId.METAL
const METAL_TINT := Color(0.94, 0.95, 0.97, 1.0)

static func is_valid(form_id: int) -> bool:
	return form_id == NORMAL or form_id == METAL


static func get_display_name(form_id: int) -> String:
	match form_id:
		METAL:
			return "Metal"
		_:
			return "Normal"


static func get_tint(form_id: int) -> Color:
	if form_id == METAL:
		return METAL_TINT
	return Color.WHITE


static func get_sprite_frames(_form_id: int) -> SpriteFrames:
	# Punto de extension para el sprite de viga de acero futuro.
	return null


static func get_menu_icon(_form_id: int) -> Texture2D:
	# El icono temporal se representa en FormMenu con un simbolo de viga.
	return null
