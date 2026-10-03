extends Area2D

signal player_reached

const PLAYER_LAYER: int = 4

@export var is_open: bool = true

@onready var door_visual: Polygon2D = $DoorVisual
@onready var light_visual: Polygon2D = $LightVisual

var _initial_open_state: bool
var _completed: bool = false

func _ready() -> void:
	add_to_group("level_resettable")
	_initial_open_state = is_open
	body_entered.connect(_on_body_entered)
	set_open(is_open)


func set_open(value: bool) -> void:
	is_open = value
	monitoring = is_open
	door_visual.color = Color("5cb85c") if is_open else Color("8f3d4b")
	light_visual.color = Color("c6f18a") if is_open else Color("e87575")
	if is_open:
		call_deferred("_check_overlapping_player")


func reset_state() -> void:
	_completed = false
	set_open(_initial_open_state)


func _check_overlapping_player() -> void:
	if not is_open or _completed:
		return
	for body in get_overlapping_bodies():
		_try_complete(body)


func _on_body_entered(body: Node2D) -> void:
	_try_complete(body)


func _try_complete(body: Node2D) -> void:
	if _completed or not is_open or not is_instance_valid(body):
		return
	var collision_body := body as CollisionObject2D
	if collision_body == null or (collision_body.collision_layer & PLAYER_LAYER) == 0:
		return
	_completed = true
	player_reached.emit()
