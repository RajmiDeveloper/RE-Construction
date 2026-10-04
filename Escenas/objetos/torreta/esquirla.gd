extends Node2D

var _direccion := Vector2.UP
var _velocidad: float = 140.0
var _vida: float = 5.0
var _consumida: bool = false


func _ready() -> void:
	top_level = true
	process_mode = Node.PROCESS_MODE_PAUSABLE


func iniciar(direccion: Vector2, velocidad: float, vida: float) -> void:
	_direccion = direccion.normalized()
	_velocidad = velocidad
	_vida = vida
	global_rotation = _direccion.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	if _consumida:
		return
	_vida -= delta
	if _vida <= 0.0:
		_consumir()
		return
	var destino := global_position + _direccion * _velocidad * delta
	# Barrido del trayecto para no atravesar paredes ni al jugador a alta velocidad.
	# Entorno (1), jugador (4) y sombras solidificadas (8).
	var consulta := PhysicsRayQueryParameters2D.create(global_position, destino, 13)
	consulta.hit_from_inside = true
	var espacio := get_world_2d().direct_space_state
	var exclusiones: Array[RID] = []
	# Limita los pasos aunque haya muchas sombras apiladas; evita que una
	# exclusión de física que no se aplique deje el bucle girando indefinidamente.
	for _paso in range(32):
		consulta.exclude = exclusiones
		var impacto := espacio.intersect_ray(consulta)
		if impacto.is_empty():
			global_position = destino
			return

		var cuerpo = impacto["collider"]
		if cuerpo.is_in_group("player"):
			if _es_metal(cuerpo):
				_consumir()
				return
			if cuerpo.has_method("die"):
				cuerpo.call_deferred("die")
			_consumir()
			return

		# Las sombras normales, de fuego o eléctricas dejan pasar la esquirla.
		# Una sombra solo la bloquea cuando ya se solidificó y quedó en capa 8.
		if _es_sombra_solida(cuerpo):
			if _es_metal(cuerpo):
				_consumir()
				return
			exclusiones.append(cuerpo.get_rid())
			continue

		# Las paredes y demás elementos del entorno siguen deteniendo el disparo.
		_consumir()
		return
	# No deja avanzar una esquirla si agotó las exclusiones de esta consulta.
	_consumir()


func _es_metal(cuerpo: Object) -> bool:
	return cuerpo.has_method("get_form_id") and int(cuerpo.call("get_form_id")) == FormCatalog.METAL


func _es_sombra_solida(cuerpo: Object) -> bool:
	return cuerpo is CollisionObject2D and (cuerpo.collision_layer & 8) != 0


func _consumir() -> void:
	_consumida = true
	queue_free()
