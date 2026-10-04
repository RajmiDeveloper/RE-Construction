extends Node2D

const MECHANISM_REWINDER = preload("res://Escenas/niveles/mechanism_rewind.gd")

@export var shadow_scene: PackedScene

@onready var player = $personaje
@onready var shadows_container: Node2D = $Sombras
@onready var pause_menu: CanvasLayer = $PauseMenu

var _spawn_position: Vector2
var _shadows: Array[Node] = []
var _recordings: Array[Array] = []
var _mechanism_rewinder: Node

func _ready() -> void:
	_mechanism_rewinder = MECHANISM_REWINDER.new()
	add_child(_mechanism_rewinder)
	_mechanism_rewinder.configure(self)
	# El menu recibe el input durante la pausa; los mecanismos se congelan.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_spawn_position = player.global_position
	player.death_started.connect(_on_player_death_started)
	player.life_finished.connect(_on_player_life_finished)
	pause_menu.configure(self, &"reset_run")


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if event.keycode == KEY_BACKSPACE and not get_tree().paused:
		_restart_test()
		get_viewport().set_input_as_handled()


func _on_player_life_finished(recording: Array) -> void:
	# Se guarda una copia independiente de cada vida para que ninguna
	# grabación posterior pueda reemplazar o modificar las anteriores.
	var saved_recording: Array = recording.duplicate(true)
	_recordings.append(saved_recording)

	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	_shadows.clear()

	if shadow_scene == null:
		push_warning("No se asignó shadow_scene en nivel_1.tscn")
		return

	# Vuelve a crear todas las sombras al inicio usando las vidas acumuladas.
	for past_recording in _recordings:
		var shadow = shadow_scene.instantiate()
		shadows_container.add_child(shadow)
		shadow.start_replay(past_recording.duplicate(true))
		_shadows.append(shadow)


func _on_player_death_started() -> void:
	_mechanism_rewinder.start_rewind()
	for shadow in _shadows:
		if is_instance_valid(shadow) and shadow.has_method("disappear"):
			shadow.disappear()
	_shadows.clear()


func reset_run() -> void:
	_mechanism_rewinder.cancel()
	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	_shadows.clear()
	_recordings.clear()
	_reset_mechanisms()
	player.reset_run()
	player.global_position = _spawn_position


func _reset_mechanisms() -> void:
	for resettable in get_tree().get_nodes_in_group("level_resettable"):
		if is_ancestor_of(resettable) and resettable.has_method("reset_state"):
			resettable.reset_state()


func _restart_test() -> void:
	pause_menu.resume()
	reset_run()
