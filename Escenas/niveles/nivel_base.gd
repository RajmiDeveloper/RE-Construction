extends Node2D

signal level_completed

@export var level_title: String = "Sala"
@export var shadow_scene: PackedScene

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var player = $Jugador
@onready var shadows_container: Node2D = $Sombras
@onready var exit_door = $Salida

var _shadows: Array[Node] = []
var _completed: bool = false

func _ready() -> void:
	player.set_spawn_position(spawn_point.global_position)
	player.life_finished.connect(_on_player_life_finished)
	exit_door.player_reached.connect(_on_player_reached_exit)


func restart_current_life() -> void:
	if not _completed:
		player.die()


func reset_level() -> void:
	_completed = false
	_clear_shadows()
	for resettable in get_tree().get_nodes_in_group("level_resettable"):
		if resettable != self and is_ancestor_of(resettable) and resettable.has_method("reset_state"):
			resettable.call("reset_state")
	player.set_spawn_position(spawn_point.global_position)
	player.reset_run()
	player.set_controls_enabled(true)


func set_active(value: bool) -> void:
	player.set_controls_enabled(value)


func can_transform_player() -> bool:
	return not _completed and is_instance_valid(player) and player.can_transform and player.get_form_id() == FormCatalog.NORMAL


func transform_player(form_id: int) -> bool:
	if _completed or not is_instance_valid(player):
		return false
	return player.transform_to(form_id)


func get_player_form() -> int:
	if not is_instance_valid(player):
		return FormCatalog.NORMAL
	return player.get_form_id()


func _on_player_life_finished(recording: Array) -> void:
	if _completed or shadow_scene == null:
		return
	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.restart_replay()

	var shadow = shadow_scene.instantiate()
	shadows_container.add_child(shadow)
	shadow.start_replay(recording.duplicate(true))
	_shadows.append(shadow)


func _on_player_reached_exit() -> void:
	if _completed:
		return
	_completed = true
	player.set_controls_enabled(false)
	level_completed.emit()


func _clear_shadows() -> void:
	for shadow in _shadows:
		if is_instance_valid(shadow):
			shadow.queue_free()
	_shadows.clear()
