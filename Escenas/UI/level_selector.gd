@tool
extends "res://Escenas/UI/menu_screen.gd"

signal level_selected(entry_id: String)
signal back_requested

const CATALOG = preload("res://Escenas/UI/level_catalog.gd")
const DISABLED_BUTTON_SHADER = preload("res://Escenas/UI/disabled_button.gdshader")


func _ready() -> void:
	super._ready()
	var disabled_material := ShaderMaterial.new()
	disabled_material.shader = DISABLED_BUTTON_SHADER
	for button in $Design/Entries.get_children():
		if button is Button:
			button.disabled = not CATALOG.is_available(CATALOG.index_of(String(button.text)))
			button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
			button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
			button.material = disabled_material if button.disabled else null
			if not Engine.is_editor_hint():
				button.pressed.connect(_select.bind(String(button.text)))
	if Engine.is_editor_hint():
		return
	$Design/BackButton.pressed.connect(func(): back_requested.emit())
	visibility_changed.connect(_focus_first)


func _select(entry_id: String) -> void:
	if CATALOG.is_available(CATALOG.index_of(entry_id)):
		level_selected.emit(entry_id)


func _focus_first() -> void:
	if is_visible_in_tree():
		$Design/Entries/T1.grab_focus()
