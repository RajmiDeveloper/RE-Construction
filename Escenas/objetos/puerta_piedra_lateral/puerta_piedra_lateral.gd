extends AnimatableBody2D

@export var is_open: bool = false
@export_range(0.0, 256.0, 1.0) var opening_height: float = 96.0
@export_range(0.0, 2.0, 0.05) var move_duration: float = 2.0
@export var activated_texture: Texture2D
@export_node_path("Area2D") var button_path: NodePath

@onready var sprite: Sprite2D = $Sprite2D

var _closed_position: Vector2
var _initial_open_state: bool
var _move_tween: Tween
var _closed_texture: Texture2D
var _button: Node


func _ready() -> void:
	add_to_group("level_resettable")
	_closed_position = position
	_initial_open_state = is_open
	_closed_texture = sprite.texture
	if not button_path.is_empty():
		_button = get_node_or_null(button_path)
	if is_instance_valid(_button):
		if not _button.has_signal("state_changed") or not _button.has_method("claim_gate") or not _button.claim_gate(self):
			push_error("La compuerta %s necesita un boton libre con la señal state_changed." % name)
			_button = null
		else:
			_button.state_changed.connect(_on_button_state_changed)
	_move_to_state(is_open, false)
	call_deferred("_sync_button_state")


func set_open(value: bool) -> void:
	if is_open == value and (_move_tween == null or not _move_tween.is_running()):
		return
	is_open = value
	_move_to_state(is_open, true)


func reset_state() -> void:
	if is_instance_valid(_button):
		call_deferred("_sync_button_state")
	else:
		is_open = _initial_open_state
		_move_to_state(is_open, true)


func _on_button_state_changed(pressed: bool) -> void:
	set_open(pressed)


func _sync_button_state() -> void:
	if is_instance_valid(_button):
		set_open(bool(_button.get("is_pressed")))


func _exit_tree() -> void:
	if is_instance_valid(_button) and _button.has_method("release_gate"):
		_button.release_gate(self)


func _move_to_state(open: bool, animate: bool) -> void:
	if not is_node_ready():
		return
	if _move_tween != null and _move_tween.is_running():
		_move_tween.kill()
	sprite.texture = activated_texture if open and animate and move_duration > 0.0 and activated_texture != null else _closed_texture

	var target_position := _closed_position
	if open:
		target_position.y -= opening_height

	if not animate or move_duration <= 0.0:
		position = target_position
		return

	_move_tween = create_tween()
	_move_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position", target_position, move_duration)
