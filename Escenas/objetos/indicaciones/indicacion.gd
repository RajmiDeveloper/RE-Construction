@tool
extends TextureRect

@export var simbolo: Texture2D:
	set(value):
		simbolo = value
		texture = value


func _ready() -> void:
	texture = simbolo
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
