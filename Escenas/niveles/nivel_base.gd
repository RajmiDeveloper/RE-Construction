extends Node2D

signal level_completed

const MECHANISM_REWINDER = preload("res://Escenas/niveles/mechanism_rewind.gd")
const STANDALONE_PAUSE = preload("res://Escenas/UI/standalone_pause.tscn")
const TUTORIAL_TWO_SCENE := "res://Escenas/niveles/Tutoriales/tutorial_02.tscn"
const TUTORIAL_ONE_SCENE := "res://Escenas/niveles/Tutoriales/tutorial_01.tscn"
const LEVEL_ONE_SCENE := "res://Escenas/niveles/Sala01/sala_01.tscn"

@export var level_title: String = "Sala"
@export var shadow_scene: PackedScene
@export var allowed_transformations: Array[int] = [FormCatalog.METAL, FormCatalog.FUEGO, FormCatalog.ELECTRICA]
@export_enum("Ninguna:-1", "Metal:1", "Fuego:2", "Eléctrica:3") var required_transformation: int = -1

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var player = $Jugador
@onready var shadows_container: Node2D = $Sombras
@onready var exit_door = get_node_or_null("Salida")

var _shadows: Array[Node] = []
var _recordings: Array[Array] = []
var _active: bool = false
var _completed: bool = false
var _mechanism_rewinder: Node


func get_allowed_transformations(_player_position: Vector2) -> Array[int]:
	return allowed_transformations.duplicate()


func get_required_transformation(_player_position: Vector2) -> int:
	return required_transformation


func _ready() -> void:
	if get_tree().get_first_node_in_group("game_shell") == null:
		var local_pause := STANDALONE_PAUSE.instantiate()
		add_child(local_pause)
		local_pause.configure(self)
	_mechanism_rewinder = MECHANISM_REWINDER.new()
	add_child(_mechanism_rewinder)
	_mechanism_rewinder.configure(self)
	player.set_spawn_position(spawn_point.global_position)
	player.death_started.connect(_on_player_death_started)
	player.life_finished.connect(_on_player_life_finished)
	if is_instance_valid(exit_door) and exit_door.has_signal("player_reached"):
		exit_door.player_reached.connect(_on_player_reached_exit)
	set_active(true)


func set_active(value: bool) -> void:
	_active = value
	if is_instance_valid(player) and player.has_method("set_controls_enabled"):
		player.set_controls_enabled(value and not _completed)


func reset_level() -> void:
	_mechanism_rewinder.cancel()
	_completed = false
	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	_shadows.clear()
	_recordings.clear()

	_reset_mechanisms()

	player.set_spawn_position(spawn_point.global_position)
	player.reset_run()
	player.set_controls_enabled(_active)


func restart_current_life() -> void:
	if _completed:
		return
	_mechanism_rewinder.cancel()
	_reset_mechanisms()
	for shadow in _shadows:
		if is_instance_valid(shadow) and shadow.has_method("restart_replay"):
			shadow.restart_replay()
	player.set_spawn_position(spawn_point.global_position)
	player.reset_run()
	player.set_controls_enabled(_active)


func _on_player_death_started() -> void:
	_mechanism_rewinder.start_rewind()
	for shadow in _shadows:
		if is_instance_valid(shadow) and shadow.has_method("disappear"):
			shadow.disappear()
	_shadows.clear()


func _reset_mechanisms() -> void:
	for mechanism in get_tree().get_nodes_in_group("level_resettable"):
		if is_ancestor_of(mechanism) and mechanism.has_method("reset_state"):
			mechanism.reset_state()


func _on_player_life_finished(recording: Array) -> void:
	if not _active or _completed:
		return
	_recordings.append(recording.duplicate(true))
	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	_shadows.clear()

	if shadow_scene == null:
		push_warning("No se asignó shadow_scene en %s" % level_title)
		return

	for past_recording in _recordings:
		var shadow = shadow_scene.instantiate()
		shadows_container.add_child(shadow)
		shadow.start_replay(past_recording.duplicate(true))
		_shadows.append(shadow)


func _on_player_reached_exit() -> void:
	if _completed or not _active:
		return
	_completed = true
	player.set_controls_enabled(false)
	level_completed.emit()
	# Al ejecutar un tutorial directamente con F6 no existe Juego.gd para avanzar.
	if get_tree().get_first_node_in_group("game_shell") != null:
		return
	if scene_file_path == TUTORIAL_ONE_SCENE:
		get_tree().call_deferred("change_scene_to_file", TUTORIAL_TWO_SCENE)
	elif scene_file_path == TUTORIAL_TWO_SCENE:
		get_tree().call_deferred("change_scene_to_file", LEVEL_ONE_SCENE)
