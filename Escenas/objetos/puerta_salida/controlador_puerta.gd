extends Node

@export var door_path: NodePath
@export var button_paths: Array[NodePath] = []

var _door
var _buttons: Array = []
var _rewinding: bool = false

func _ready() -> void:
	add_to_group("level_resettable")
	_door = get_node_or_null(door_path)
	for path in button_paths:
		var button := get_node_or_null(path)
		if button == null:
			continue
		_buttons.append(button)
		button.state_changed.connect(_update_door)
	call_deferred("_update_door")


func reset_state() -> void:
	call_deferred("_update_door")


func _update_door(_ignored_state: bool = false) -> void:
	if _rewinding:
		return
	if not is_instance_valid(_door):
		return
	var all_pressed := not _buttons.is_empty()
	for button in _buttons:
		if not is_instance_valid(button) or not button.is_pressed:
			all_pressed = false
			break
	_door.set_open(all_pressed)


func freeze_for_rewind() -> void:
	_rewinding = true


func finish_rewind() -> void:
	_rewinding = false
	call_deferred("_update_door")
