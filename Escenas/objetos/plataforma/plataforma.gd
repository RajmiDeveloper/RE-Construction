extends StaticBody2D

@export var platform_size: Vector2 = Vector2(64, 16)
@export var platform_color: Color = Color("53627a")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	_update_geometry()


func _update_geometry() -> void:
	var rectangle := collision_shape.shape as RectangleShape2D
	rectangle.size = platform_size
	var half_size := platform_size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
	visual.color = platform_color
