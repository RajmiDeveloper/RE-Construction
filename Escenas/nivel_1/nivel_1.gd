extends Node2D

@export var shadow_scene: PackedScene

@onready var player = $personaje

var _spawn_position: Vector2
var _shadows: Array[Node] = []

func _ready() -> void:
	_spawn_position = player.global_position
	player.life_finished.connect(_on_player_life_finished)


func _on_player_life_finished(recording: Array) -> void:
	if shadow_scene == null:
		push_warning("No se asignó shadow_scene en nivel_1.tscn")
		return

	var shadow = shadow_scene.instantiate()
	add_child(shadow)
	shadow.start_replay(recording)
	_shadows.append(shadow)


func reset_run() -> void:
	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	_shadows.clear()
	player.reset_run()
	player.global_position = _spawn_position
