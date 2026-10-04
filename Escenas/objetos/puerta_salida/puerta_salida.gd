extends Area2D

signal player_reached

const PLAYER_LAYER: int = 4

var is_open: bool = false

@onready var closed_visual: Sprite2D = $PuertaCerrada
@onready var open_visual: Sprite2D = $PuertaAbierta

var _player_nearby: bool = false
var _completed: bool = false
var _rewinding: bool = false


func _ready() -> void:
	add_to_group("level_resettable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	_update_visuals()


func reset_state() -> void:
	_completed = false
	_player_nearby = false
	is_open = false
	_update_visuals()


func set_open(value: bool) -> void:
	if _rewinding:
		return
	if is_open == value:
		return
	is_open = value
	_update_visuals()


func _input(event: InputEvent) -> void:
	if _rewinding:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ENTER and event.keycode != KEY_KP_ENTER and event.keycode != KEY_E:
		return
	if not is_open or not _player_nearby or _completed:
		return

	_completed = true
	player_reached.emit()
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if _rewinding:
		return
	if _is_player(body):
		_player_nearby = true
		is_open = true
		_update_visuals()


func _on_body_exited(body: Node2D) -> void:
	if _rewinding:
		return
	if _is_player(body):
		_player_nearby = false
		is_open = false
		_update_visuals()


func _is_player(body: Node2D) -> bool:
	var collision_body := body as CollisionObject2D
	return collision_body != null and (collision_body.collision_layer & PLAYER_LAYER) != 0


func _update_visuals() -> void:
	if not is_node_ready():
		return
	closed_visual.visible = not is_open
	open_visual.visible = is_open


func freeze_for_rewind() -> void:
	_rewinding = true


func finish_rewind() -> void:
	_rewinding = false
