extends "res://Escenas/niveles/nivel_base.gd"

@onready var metal_inicio: Area2D = $Mecanismos/MetalInicio
@onready var metal_escalera: Area2D = $Mecanismos/MetalEscalera
@onready var hielo: Node2D = $Mecanismos/Hielo
@onready var estado: Label = $HUD/Panel/Margen/Texto/Estado
@onready var consejo: Label = $HUD/Panel/Margen/Texto/Consejo


func _ready() -> void:
	super._ready()
	level_completed.connect(_show_completion)


func _physics_process(_delta: float) -> void:
	if _completed:
		return
	var ice_cleared: bool = not hielo.get_node("Sprite2D").visible
	estado.text = "Ecos: %d · Metal I: %s · Metal II: %s · Hielo: %s" % [
		_shadows.size(),
		"activo" if metal_inicio.is_pressed else "pendiente",
		"activo" if metal_escalera.is_pressed else "pendiente",
		"derretido" if ice_cleared else "sólido",
	]
	if ice_cleared:
		consejo.text = "El calor abrió el camino. La forma eléctrica puede cruzar el rayo."
	elif metal_inicio.is_pressed and metal_escalera.is_pressed:
		consejo.text = "El hielo necesita calor sostenido. Las sombras de fuego también derriten."
	else:
		consejo.text = "Las placas necesitan peso. R deja un eco; cada vida empieza en Normal."


func _unhandled_input(event: InputEvent) -> void:
	# Permite reiniciar también cuando se ejecuta la sala directamente con F6.
	if get_tree().paused or not event is InputEventKey:
		return
	if event.pressed and not event.echo and event.keycode == KEY_BACKSPACE:
		reset_level()
		get_viewport().set_input_as_handled()


func _on_player_life_finished(recording: Array) -> void:
	if not _active or _completed:
		return
	# Caer en pinchos o rayos restaura los mismos obstáculos que pulsar R.
	# Los ecos deben volver a abrir el recorrido en cada nueva vida.
	_reset_mechanisms()
	super._on_player_life_finished(recording)


func _show_completion() -> void:
	estado.text = "Sala completada · %d ecos" % _shadows.size()
	consejo.text = "Tus vidas anteriores construyeron el camino."
