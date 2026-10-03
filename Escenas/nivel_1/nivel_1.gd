extends Node2D

@export var shadow_scene: PackedScene

@onready var player = $personaje
@onready var shadows_container: Node2D = $Sombras
@onready var form_menu = $FormMenu
@onready var pause_menu: CanvasLayer = $PauseMenu

var _spawn_position: Vector2
var _shadows: Array[Node] = []
var _recordings: Array[Array] = []

func _ready() -> void:
	# Esta escena tambien se ejecuta sola desde el editor con F6, por eso
	# mantiene el input activo mientras el arbol esta pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_position = player.global_position
	player.life_finished.connect(_on_player_life_finished)
	form_menu.form_selected.connect(_on_form_selected)
	pause_menu.get_node("Panel/ContinueButton").pressed.connect(_resume_game)
	pause_menu.get_node("Panel/RestartButton").pressed.connect(_restart_test)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if form_menu.visible:
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
			_close_form_menu()
			get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_TAB:
		if not pause_menu.visible and player.can_transform and player.get_form_id() == FormCatalog.NORMAL:
			form_menu.open([FormCatalog.METAL, FormCatalog.FUEGO, FormCatalog.ELECTRICA])
			get_tree().paused = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_BACKSPACE:
		_restart_test()
		get_viewport().set_input_as_handled()


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
	for resettable in get_tree().get_nodes_in_group("level_resettable"):
		if is_ancestor_of(resettable) and resettable.has_method("reset_state"):
			resettable.reset_state()
	player.reset_run()
	player.global_position = _spawn_position


func _on_form_selected(form_id: int) -> void:
	player.transform_to(form_id)
	_close_form_menu()


func _close_form_menu() -> void:
	form_menu.close()
	get_tree().paused = false


func _pause_game() -> void:
	pause_menu.visible = true
	get_tree().paused = true


func _resume_game() -> void:
	pause_menu.visible = false
	get_tree().paused = false


func _restart_test() -> void:
	_resume_game()
	reset_run()
