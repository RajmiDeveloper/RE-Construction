extends Node2D

@export var shadow_scene: PackedScene

const SHADOW_DISAPPEAR_DELAY: float = 1.0

@onready var player = $personaje
@onready var shadows_container: Node2D = $Sombras
@onready var pause_menu: CanvasLayer = $PauseMenu

var _spawn_position: Vector2
var _shadows: Array[Node] = []
var _recordings: Array[Array] = []
var _shadow_disappearance_sequence: int = 0

func _ready() -> void:
	# Esta escena tambien se ejecuta sola desde el editor con F6, por eso
	# mantiene el input activo mientras el arbol esta pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_position = player.global_position
	player.restart_requested.connect(_on_player_restart_requested)
	player.death_started.connect(_on_player_death_started)
	player.life_finished.connect(_on_player_life_finished)
	pause_menu.get_node("Panel/ContinueButton").pressed.connect(_resume_game)
	pause_menu.get_node("Panel/RestartButton").pressed.connect(_restart_test)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			_resume_game()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused:
			_pause_game()
			get_viewport().set_input_as_handled()
	elif event.keycode == KEY_BACKSPACE and not get_tree().paused:
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


func _on_player_restart_requested() -> void:
	_reset_mechanisms()


func _on_player_death_started() -> void:
	_shadow_disappearance_sequence += 1
	var sequence := _shadow_disappearance_sequence
	await get_tree().create_timer(SHADOW_DISAPPEAR_DELAY).timeout
	if sequence != _shadow_disappearance_sequence:
		return
	for shadow in _shadows:
		if is_instance_valid(shadow) and shadow.has_method("disappear"):
			shadow.disappear()
	_shadows.clear()


func reset_run() -> void:
	_shadow_disappearance_sequence += 1
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


func _pause_game() -> void:
	pause_menu.visible = true
	get_tree().paused = true


func _resume_game() -> void:
	pause_menu.visible = false
	get_tree().paused = false


func _restart_test() -> void:
	_resume_game()
	reset_run()
