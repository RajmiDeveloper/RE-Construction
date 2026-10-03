extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_in_range: Node2D
var _activated: bool = false


func _ready() -> void:
	add_to_group("level_resettable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	animated_sprite.stop()
	animated_sprite.frame = 0


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or _activated or not is_instance_valid(_player_in_range):
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ENTER and event.keycode != KEY_KP_ENTER:
		return

	_activated = true
	animated_sprite.play("activar")
	get_viewport().set_input_as_handled()


func reset_state() -> void:
	_activated = false
	animated_sprite.stop()
	animated_sprite.frame = 0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = body


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
