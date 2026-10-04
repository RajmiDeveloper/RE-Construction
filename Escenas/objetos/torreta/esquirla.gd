extends Node2D

var _direccion := Vector2.UP
var _velocidad: float = 140.0
var _vida: float = 5.0
var _consumida: bool = false

const PARTICULAS_CANTIDAD: int = 24
const PARTICULAS_DURACION: float = 0.65
const COLOR_CRISTAL := Color(0.68, 0.22, 0.9, 1.0)
const SONIDO_ROTURA: AudioStreamWAV = preload("res://Assets/Sonidos/torreta/cristal_roto.wav")


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
	# Entorno (1), jugador (4) y sombras, incluso durante su reproduccion (8).
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
		var punto_impacto: Vector2 = impacto["position"]
		if cuerpo.is_in_group("player"):
			if _es_metal(cuerpo):
				_romper(punto_impacto)
				return
			if cuerpo.has_method("die"):
				cuerpo.call_deferred("die")
			_romper(punto_impacto)
			return

		# Las sombras normales, de fuego o eléctricas dejan pasar la esquirla.
		# Las sombras de metal la bloquean tambien mientras se reproducen.
		if _es_sombra(cuerpo):
			if _es_metal(cuerpo):
				_romper(punto_impacto)
				return
			exclusiones.append(cuerpo.get_rid())
			continue

		# Las paredes y demás elementos del entorno siguen deteniendo el disparo.
		_romper(punto_impacto)
		return
	# No deja avanzar una esquirla si agotó las exclusiones de esta consulta.
	_consumir()


func _es_metal(cuerpo: Object) -> bool:
	return cuerpo.has_method("get_form_id") and int(cuerpo.call("get_form_id")) == FormCatalog.METAL


func _es_sombra(cuerpo: Object) -> bool:
	return cuerpo is CollisionObject2D and (cuerpo.collision_layer & 8) != 0


func _consumir() -> void:
	_consumida = true
	queue_free()


func _romper(posicion: Vector2) -> void:
	if _consumida:
		return
	_consumida = true
	_emitir_sonido_rotura()
	_emitir_particulas_rotura(posicion)
	queue_free()


func _emitir_sonido_rotura() -> void:
	var sonido := AudioStreamPlayer.new()
	sonido.name = "CristalRoto"
	sonido.stream = SONIDO_ROTURA
	sonido.volume_db = -8.0
	sonido.pitch_scale = randf_range(0.94, 1.06)
	sonido.process_mode = Node.PROCESS_MODE_PAUSABLE
	sonido.finished.connect(sonido.queue_free)
	# El nivel conserva el sonido cuando desaparece la esquirla y se congela
	# la torreta al morir el jugador. El mute del bus Master tambien lo afecta.
	var contenedor: Node = get_parent()
	while contenedor != null and not contenedor.has_method("reset_level"):
		contenedor = contenedor.get_parent()
	if contenedor == null:
		contenedor = get_tree().current_scene
	if contenedor == null:
		contenedor = get_parent()
	contenedor.add_child(sonido)
	sonido.play()


func _emitir_particulas_rotura(posicion: Vector2) -> void:
	var estallido := GPUParticles2D.new()
	estallido.amount = PARTICULAS_CANTIDAD
	estallido.lifetime = PARTICULAS_DURACION
	estallido.one_shot = true
	estallido.explosiveness = 1.0
	estallido.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var imagen_particula := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	imagen_particula.fill(Color.WHITE)
	estallido.texture = ImageTexture.create_from_image(imagen_particula)

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, 0.0, 0.0)
	material.spread = 40.0
	material.initial_velocity_min = 24.0
	material.initial_velocity_max = 58.0
	material.gravity = Vector3(0.0, 36.0, 0.0)
	material.scale_min = 0.7
	material.scale_max = 1.35
	material.color = COLOR_CRISTAL
	var desvanecido := Gradient.new()
	desvanecido.set_color(0, Color.WHITE)
	desvanecido.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var textura_desvanecido := GradientTexture1D.new()
	textura_desvanecido.gradient = desvanecido
	material.color_ramp = textura_desvanecido
	estallido.process_material = material
	estallido.finished.connect(estallido.queue_free)
	get_parent().add_child(estallido)
	estallido.global_position = posicion
	estallido.global_rotation = (-_direccion).angle()
	estallido.emitting = true
