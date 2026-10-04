extends CanvasLayer

const AUDIO = preload("res://Escenas/UI/audio_preferences.gd")

var _level: Node
var _reset_method: StringName = &"reset_level"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AUDIO.restore()
	$Menu.continue_requested.connect(resume)
	$Menu.restart_requested.connect(_restart)
	$Menu.selector_requested.connect(_open_selector)
	visible = false


func configure(level: Node, reset_method: StringName = &"reset_level") -> void:
	_level = level
	_reset_method = reset_method
	if is_node_ready():
		var caption := "Campo de pruebas"
		for property in level.get_property_list():
			if property["name"] == "level_title":
				caption = String(level.get("level_title"))
				break
		$Menu.set_level_caption(caption)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if visible:
		resume()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused:
		visible = true
		get_tree().paused = true
		$Menu/Design/Options/ContinueButton.grab_focus()
		get_viewport().set_input_as_handled()


func resume() -> void:
	visible = false
	get_tree().paused = false


func _restart() -> void:
	resume()
	if is_instance_valid(_level) and _level.has_method(_reset_method):
		_level.call(_reset_method)


func _open_selector() -> void:
	resume()
	get_tree().set_meta("open_level_selector", true)
	get_tree().change_scene_to_file("res://Escenas/Juego.tscn")
