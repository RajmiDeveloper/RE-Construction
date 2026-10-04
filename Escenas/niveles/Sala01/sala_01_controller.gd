extends "res://Escenas/niveles/nivel_base.gd"

@onready var metal_inicio: Area2D = $Mecanismos/MetalInicio
@onready var metal_escalera: Area2D = $Mecanismos/MetalEscalera


func _unhandled_input(event: InputEvent) -> void:
	# Permite reiniciar también cuando se ejecuta la sala directamente con F6.
	if get_tree().paused or not event is InputEventKey:
		return
	if event.pressed and not event.echo and event.keycode == KEY_BACKSPACE:
		reset_level()
		get_viewport().set_input_as_handled()
