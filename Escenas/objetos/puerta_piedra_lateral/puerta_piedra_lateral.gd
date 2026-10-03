extends StaticBody2D

@export var is_open: bool = false
@export_range(0.0, 256.0, 1.0) var opening_height: float = 96.0
@export_range(0.0, 2.0, 0.05) var move_duration: float = 0.55
@export var activated_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var _closed_position: Vector2
var _initial_open_state: bool
var _move_tween: Tween
var _closed_texture: Texture2D


func _ready() -> void:
	add_to_group("level_resettable")
	_closed_position = position
	_initial_open_state = is_open
	_closed_texture = sprite.texture
	_move_to_state(is_open, false)


func set_open(value: bool) -> void:
	if is_open == value and (_move_tween == null or not _move_tween.is_running()):
		return
	is_open = value
	_move_to_state(is_open, true)


func reset_state() -> void:
	is_open = _initial_open_state
	_move_to_state(is_open, true)


func _move_to_state(open: bool, animate: bool) -> void:
	if not is_node_ready():
		return
	if _move_tween != null and _move_tween.is_running():
		_move_tween.kill()
	sprite.texture = activated_texture if open and animate and activated_texture != null else _closed_texture

	var target_position := _closed_position
	if open:
		target_position.y -= opening_height

	if not animate or move_duration <= 0.0:
		position = target_position
		return

	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position", target_position, move_duration)
