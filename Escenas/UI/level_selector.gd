@tool
extends "res://Escenas/UI/menu_screen.gd"

signal level_selected(entry_id: String)
signal back_requested


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	for button in $Design/Entries.get_children():
		if button is Button:
			button.pressed.connect(_select.bind(String(button.text)))
	$Design/BackButton.pressed.connect(func(): back_requested.emit())
	visibility_changed.connect(_focus_first)


func _select(entry_id: String) -> void:
	level_selected.emit(entry_id)


func _focus_first() -> void:
	if is_visible_in_tree():
		$Design/Entries/T1.grab_focus()
