@tool
extends Node2D

enum Orientacion { PISO, PARED_IZQUIERDA, PARED_DERECHA }
enum Estado { REPOSO, CARGANDO }

const PROYECTIL = preload("res://Escenas/objetos/torreta/esquirla.tscn")

@export var orientacion: Orientacion = Orientacion.PISO:
	set(value):
		orientacion = value
		if is_node_ready():
			_actualizar_orientacion()
@export_range(0.05, 60.0, 0.05) var tiempo_reposo: float = 2.0
@export_range(0.05, 10.0, 0.05) var tiempo_carga: float = 0.6
@export_range(10.0, 1000.0, 5.0) var velocidad_proyectil: float = 140.0
@export_range(0.1, 30.0, 0.1) var vida_proyectil: float = 5.0
@export_range(0.05, 0.5, 0.01) var duracion_zona_mortal: float = 0.15

@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var boca: Marker2D = $Visual/Boca
@onready var zona_mortal: Area2D = $Visual/ZonaMortal
@onready var temporizador_zona_mortal: Timer = $TemporizadorZonaMortal
@onready var proyectiles: Node2D = $Proyectiles

var estado: Estado = Estado.REPOSO
var _tiempo: float = 0.0


func _ready() -> void:
	_actualizar_orientacion()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("level_resettable")
	reset_state()


func _actualizar_orientacion() -> void:
	match orientacion:
		Orientacion.PISO:
			visual.rotation = 0.0
		Orientacion.PARED_IZQUIERDA:
			visual.rotation = PI / 2.0
		Orientacion.PARED_DERECHA:
			visual.rotation = -PI / 2.0


func reset_state() -> void:
	estado = Estado.REPOSO
	_tiempo = 0.0
	sprite.frame = 0
	temporizador_zona_mortal.stop()
	zona_mortal.set_deferred("monitoring", false)
	for proyectil in proyectiles.get_children():
		proyectil.set_physics_process(false)
		proyectil.queue_free()


func _physics_process(delta: float) -> void:
	_tiempo += delta
	if estado == Estado.REPOSO:
		if _tiempo >= maxf(tiempo_reposo, 0.05):
			_tiempo = 0.0
			estado = Estado.CARGANDO
			sprite.frame = 1
	elif _tiempo >= maxf(tiempo_carga, 0.05):
		_disparar()
		_tiempo = 0.0
		estado = Estado.REPOSO
		sprite.frame = 0


func _disparar() -> void:
	zona_mortal.set_deferred("monitoring", true)
	temporizador_zona_mortal.start(maxf(duracion_zona_mortal, 0.05))
	var esquirla = PROYECTIL.instantiate()
	proyectiles.add_child(esquirla)
	var direccion := (boca.global_position - global_position).normalized()
	# El marcador está en la punta del cristal. Unos píxeles hacia fuera hacen
	# que la esquirla parezca desprenderse de la punta y no salir del centro.
	esquirla.global_position = boca.global_position + direccion * 2.0
	esquirla.iniciar(direccion, velocidad_proyectil, vida_proyectil)


func _desactivar_zona_mortal() -> void:
	zona_mortal.set_deferred("monitoring", false)


func _on_zona_mortal_body_entered(cuerpo: Node2D) -> void:
	if not cuerpo.is_in_group("player") or not cuerpo.has_method("die"):
		return
	if cuerpo.has_method("get_form_id") and int(cuerpo.call("get_form_id")) == FormCatalog.METAL:
		return
	cuerpo.call_deferred("die")
