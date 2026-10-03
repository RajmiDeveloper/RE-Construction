extends Node2D

@export var shadow_scene: PackedScene

@onready var player = $personaje
@onready var shadows_container: Node2D = $Sombras

var _spawn_position: Vector2
var _shadows: Array[Node] = []
var _recordings: Array[Array] = []

func _ready() -> void:
	_spawn_position = player.global_position
	player.life_finished.connect(_on_player_life_finished)


func _on_player_life_finished(recording: Array) -> void:
	if shadow_scene == null:
		push_warning("No se asignó shadow_scene en nivel_1.tscn")
		return

	# Cada nueva vida vuelve a poner todas las sombras en el inicio
	# para que repitan sus recorridos al mismo tiempo.
	for existing_shadow in _shadows:
		if is_instance_valid(existing_shadow):
			existing_shadow.restart_replay()

	# Se guarda una copia independiente de cada vida para que ninguna
	# grabación posterior pueda reemplazar o modificar las anteriores.
	var saved_recording: Array = recording.duplicate(true)
	_recordings.append(saved_recording)

	var shadow = shadow_scene.instantiate()
	shadows_container.add_child(shadow)
	shadow.start_replay(saved_recording)
	_shadows.append(shadow)


func reset_run() -> void:
	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	_shadows.clear()
	_recordings.clear()
	player.reset_run()
	player.global_position = _spawn_position
