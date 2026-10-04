@tool
extends "res://Escenas/UI/menu_screen.gd"

signal start_requested
signal levels_requested
signal quit_requested


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	$Design/Options/StartButton.pressed.connect(func(): start_requested.emit())
	$Design/Options/LevelsButton.pressed.connect(func(): levels_requested.emit())
	$Design/Options/QuitButton.pressed.connect(func(): quit_requested.emit())
	visibility_changed.connect(_focus_start)
	_focus_start.call_deferred()


func _focus_start() -> void:
	if is_visible_in_tree():
		$Design/Options/StartButton.grab_focus()
