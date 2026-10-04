@tool
extends "res://Escenas/UI/menu_screen.gd"

signal continue_requested
signal selector_requested
signal restart_requested

const AUDIO = preload("res://Escenas/UI/audio_preferences.gd")
const SOUND_ON: Texture2D = preload("res://Assets/UI/Menu/sonido.svg")
const SOUND_OFF: Texture2D = preload("res://Assets/UI/Menu/silencio.svg")


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	$Design/Options/ContinueButton.pressed.connect(func(): continue_requested.emit())
	$Design/Options/SelectorButton.pressed.connect(func(): selector_requested.emit())
	$Design/Options/RestartButton.pressed.connect(func(): restart_requested.emit())
	$Design/SoundButton.pressed.connect(_toggle_sound)
	visibility_changed.connect(_on_visibility_changed)
	update_sound()


func update_sound() -> void:
	$Design/SoundButton.icon = SOUND_OFF if AUDIO.is_muted() else SOUND_ON
	$Design/SoundButton.tooltip_text = "Activar sonido" if AUDIO.is_muted() else "Quitar sonido"
	$Design/SoundButton.button_pressed = AUDIO.is_muted()


func set_level_caption(caption: String) -> void:
	$Design/LevelCaption.text = caption


func _toggle_sound() -> void:
	AUDIO.toggle()
	update_sound()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		update_sound()
		$Design/Options/ContinueButton.grab_focus()
