extends Area2D

signal state_changed(is_pressed: bool)

const PLAYER_LAYER: int = 4
const SHADOW_LAYER: int = 8

@export var texture_released: Texture2D
@export var texture_pressed: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var is_pressed: bool = false
var _pressing_bodies: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()


func _on_body_entered(body: Node2D) -> void:
	if not _is_pressing_body(body):
		return
	if not _pressing_bodies.has(body):
		_pressing_bodies.append(body)
	_update_state()


func _on_body_exited(body: Node2D) -> void:
	if _pressing_bodies.has(body):
		_pressing_bodies.erase(body)
	_update_state()


func _is_pressing_body(body: Node2D) -> bool:
	if not is_instance_valid(body):
		return false

	var collision_body := body as CollisionObject2D
	if collision_body == null:
		return false

	var layer: int = collision_body.collision_layer
	return (layer & PLAYER_LAYER) != 0 or (layer & SHADOW_LAYER) != 0


func _update_state() -> void:
	for index in range(_pressing_bodies.size() - 1, -1, -1):
		if not is_instance_valid(_pressing_bodies[index]):
			_pressing_bodies.remove_at(index)

	var new_state := not _pressing_bodies.is_empty()
	if new_state == is_pressed:
		return

	is_pressed = new_state
	_update_visual()
	state_changed.emit(is_pressed)


func _update_visual() -> void:
	if not is_instance_valid(sprite):
		return

	sprite.texture = texture_pressed if is_pressed else texture_released
