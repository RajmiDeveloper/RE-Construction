extends Node

@export var level_scenes: Array[PackedScene] = []
@export var transition_duration: float = 0.8

@onready var level_container: Node2D = $NivelActual
@onready var transition_ui: CanvasLayer = $TransitionUI
@onready var transition_label: Label = $TransitionUI/Panel/Label
@onready var main_menu: CanvasLayer = $MainMenu
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var end_ui: CanvasLayer = $EndUI
@onready var form_menu = $FormMenu

var _current_level
var _current_index: int = -1
var _transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$MainMenu/Panel/StartButton.pressed.connect(start_game)
	$MainMenu/Panel/QuitButton.pressed.connect(_quit_game)
	$PauseMenu/Panel/ContinueButton.pressed.connect(_resume_game)
	$PauseMenu/Panel/RestartButton.pressed.connect(_restart_level)
	$PauseMenu/Panel/MenuButton.pressed.connect(return_to_menu)
	$EndUI/Panel/MenuButton.pressed.connect(return_to_menu)
	form_menu.form_selected.connect(_on_form_selected)
	_show_main_menu()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if form_menu.visible:
			if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
				_close_form_menu()
				get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_TAB:
			if _can_open_form_menu():
				_open_form_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE and is_instance_valid(_current_level) and not _transitioning:
			_current_level.reset_level()
		elif event.is_action_pressed("ui_cancel") and is_instance_valid(_current_level) and not _transitioning:
			if pause_menu.visible:
				_resume_game()
			else:
				_pause_game()


func start_game() -> void:
	get_tree().paused = false
	form_menu.close()
	main_menu.visible = false
	end_ui.visible = false
	_load_level(0)


func return_to_menu() -> void:
	form_menu.close()
	get_tree().paused = false
	pause_menu.visible = false
	end_ui.visible = false
	_clear_current_level()
	_show_main_menu()


func _load_level(index: int) -> void:
	if index < 0 or index >= level_scenes.size():
		_show_end_screen()
		return

	_clear_current_level()
	_current_index = index
	_current_level = level_scenes[index].instantiate()
	if not _current_level.has_signal("level_completed") or not _current_level.has_method("set_active"):
		push_error("La escena del nivel %d no implementa la interfaz requerida (level_completed y set_active)." % (index + 1))
		_current_level.queue_free()
		_current_level = null
		return
	level_container.add_child(_current_level)
	_current_level.level_completed.connect(_on_level_completed)
	_current_level.set_active(true)
	transition_ui.visible = false
	_transitioning = false


func _on_level_completed() -> void:
	if _transitioning:
		return
	_transitioning = true
	_show_transition("Sala %d completada" % (_current_index + 1))
	await get_tree().create_timer(transition_duration, true).timeout
	_load_level(_current_index + 1)


func _restart_level() -> void:
	form_menu.close()
	_resume_game()
	if is_instance_valid(_current_level):
		_current_level.reset_level()


func _pause_game() -> void:
	pause_menu.visible = true
	get_tree().paused = true


func _resume_game() -> void:
	pause_menu.visible = false
	get_tree().paused = false


func _show_main_menu() -> void:
	form_menu.close()
	transition_ui.visible = false
	pause_menu.visible = false
	main_menu.visible = true


func _show_transition(message: String) -> void:
	transition_label.text = message
	transition_ui.visible = true


func _show_end_screen() -> void:
	form_menu.close()
	transition_ui.visible = false
	end_ui.visible = true
	_transitioning = false


func _clear_current_level() -> void:
	if is_instance_valid(_current_level):
		level_container.remove_child(_current_level)
		_current_level.queue_free()
	_current_level = null


func _quit_game() -> void:
	get_tree().quit()


func _can_open_form_menu() -> bool:
	return is_instance_valid(_current_level) \
		and not _transitioning \
		and not main_menu.visible \
		and not pause_menu.visible \
		and not end_ui.visible \
		and _current_level.has_method("can_transform_player") \
		and _current_level.can_transform_player()


func _open_form_menu() -> void:
	if not _can_open_form_menu():
		return
	form_menu.open([FormCatalog.METAL])
	get_tree().paused = true


func _close_form_menu() -> void:
	form_menu.close()
	get_tree().paused = false


func _on_form_selected(form_id: int) -> void:
	if not form_menu.visible:
		return
	if is_instance_valid(_current_level) and not _transitioning:
		_current_level.transform_player(form_id)
	_close_form_menu()
