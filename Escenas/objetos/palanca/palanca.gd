extends Area2D

@export_node_path("Area2D") var trampa_electrica_path: NodePath

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_in_range: Node2D
var _activated: bool = false
var _trampa_electrica: Node
var _rewinding: bool = false


func _ready() -> void:
	add_to_group("level_resettable")
	if not trampa_electrica_path.is_empty():
		_trampa_electrica = get_node_or_null(trampa_electrica_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	animated_sprite.stop()
	animated_sprite.frame = 0


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or _rewinding or _activated or not is_instance_valid(_player_in_range):
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ENTER and event.keycode != KEY_KP_ENTER and event.keycode != KEY_E:
		return

	_activate()
	if _player_in_range.has_method("record_interaction"):
		_player_in_range.call("record_interaction", self, &"activate")
	get_viewport().set_input_as_handled()


func activate_from_shadow() -> void:
	_activate()


func _activate() -> void:
	if _rewinding or _activated:
		return
	_activated = true
	animated_sprite.play("activar")
	if is_instance_valid(_trampa_electrica) and _trampa_electrica.has_method("set_active"):
		_trampa_electrica.call("set_active", false)


func reset_state() -> void:
	_activated = false
	animated_sprite.stop()
	animated_sprite.frame = 0
	if is_instance_valid(_trampa_electrica) and _trampa_electrica.has_method("reset_state"):
		_trampa_electrica.call("reset_state")


func freeze_for_rewind() -> void:
	_rewinding = true
	animated_sprite.stop()


func finish_rewind() -> void:
	_rewinding = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = body


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
