extends Node2D

signal level_completed

@export var level_title: String = "Sala"
@export var shadow_scene: PackedScene

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var player = $Jugador
@onready var shadows_container: Node2D = $Sombras
@onready var exit_door = get_node_or_null("Salida")

var _shadows: Array[Node] = []
var _recordings: Array[Array] = []
var _active: bool = false
var _completed: bool = false


func _ready() -> void:
	player.set_spawn_position(spawn_point.global_position)
	player.restart_requested.connect(_on_player_restart_requested)
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
	for shadow in _shadows:
		if is_instance_valid(shadow) and shadow.has_method("restart_replay"):
			shadow.restart_replay()
	player.set_spawn_position(spawn_point.global_position)
	player.reset_run()
	player.set_controls_enabled(_active)


func _on_player_restart_requested() -> void:
	_reset_mechanisms()


func _on_player_death_started() -> void:
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
