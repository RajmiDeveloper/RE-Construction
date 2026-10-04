@tool
extends Node2D

const TEXTURA_COLUMNA: Texture2D = preload("res://Assets/Mapa/PlataformaMetal/columna_32x16.png")
const ALTO_PLATAFORMA: float = 16.0
const ESCALA_COLUMNA: float = 0.5
const ALTO_TRAMO: float = 8.0
const CAPA_SOMBRA: int = 8

@export_range(1.0, 240.0, 1.0) var velocidad_bajada: float = 60.0
@export_range(1.0, 240.0, 1.0) var velocidad_subida: float = 80.0
@export var volver_al_quitar_peso: bool = true

@onready var punto_superior: Marker2D = $PuntoSuperior
@onready var punto_inferior: Marker2D = $PuntoInferior
@onready var fin_columna: Marker2D = $FinColumna
@onready var columnas: Node2D = $Columnas
@onready var cuerpo: AnimatableBody2D = $Cuerpo
@onready var zona_peso: Area2D = $Cuerpo/ZonaPeso

var _tramos: Array[Sprite2D] = []
var _hundida: bool = false
var _puntos_editor_listos: bool = false
var _ultimo_superior: Vector2
var _ultimo_inferior: Vector2
var _ultimo_fin_columna: Vector2


func _ready() -> void:
	cuerpo.position = punto_superior.position
	_actualizar_columna()
	if Engine.is_editor_hint():
		set_physics_process(false)
	else:
		add_to_group("level_resettable")
		set_process(false)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if _puntos_editor_listos and punto_superior.position == _ultimo_superior \
			and punto_inferior.position == _ultimo_inferior \
			and fin_columna.position == _ultimo_fin_columna:
		return

	_puntos_editor_listos = true
	_ultimo_superior = punto_superior.position
	_ultimo_inferior = punto_inferior.position
	_ultimo_fin_columna = fin_columna.position
	cuerpo.position = punto_superior.position
	_actualizar_columna()
	update_configuration_warnings()


func _physics_process(delta: float) -> void:
	if punto_inferior.position.y <= punto_superior.position.y:
		return

	var sombras_encima: Array[Node2D] = []
	var hay_metal: bool = _detectar_peso_metal(sombras_encima)
	if hay_metal:
		_hundida = true
	elif volver_al_quitar_peso:
		_hundida = false

	var destino: Vector2 = punto_superior.position
	var velocidad: float = velocidad_subida
	if _hundida:
		destino = Vector2(punto_superior.position.x, punto_inferior.position.y)
		velocidad = velocidad_bajada

	var posicion_anterior: Vector2 = cuerpo.global_position
	cuerpo.position = cuerpo.position.move_toward(destino, velocidad * delta)
	var desplazamiento: Vector2 = cuerpo.global_position - posicion_anterior
	for sombra in sombras_encima:
		if is_instance_valid(sombra):
			sombra.global_position += desplazamiento

	_actualizar_columna()


func reset_state() -> void:
	_hundida = false
	cuerpo.position = punto_superior.position
	_actualizar_columna()


func _detectar_peso_metal(sombras_encima: Array[Node2D]) -> bool:
	var hay_metal: bool = false
	for body in zona_peso.get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		if body.is_in_group("player"):
			if _es_metal(body):
				hay_metal = true
			continue

		var cuerpo_detectado := body as CollisionObject2D
		if cuerpo_detectado == null or (cuerpo_detectado.collision_layer & CAPA_SOMBRA) == 0:
			continue
		# Solo transporta sombras detenidas; las demas siguen su grabacion.
		var reproduciendo: bool = body.has_method("is_replaying") and body.call("is_replaying")
		if not reproduciendo and not sombras_encima.has(body):
			sombras_encima.append(body)
		if _es_metal(body):
			hay_metal = true

	for area in zona_peso.get_overlapping_areas():
		if not area.is_in_group("shadow_platform_weight") and not area.is_in_group("shadow_interaction"):
			continue
		var sombra := area.get_parent() as Node2D
		if sombra == null:
			continue
		var sombra_reproduciendose: bool = sombra.has_method("is_replaying") and sombra.call("is_replaying")
		if not sombra_reproduciendose and not sombras_encima.has(sombra):
			sombras_encima.append(sombra)
		if _es_metal(sombra):
			hay_metal = true
	return hay_metal


func _es_metal(node: Node) -> bool:
	return node.has_method("get_form_id") and int(node.call("get_form_id")) == FormCatalog.METAL


func _actualizar_columna() -> void:
	var inicio: float = cuerpo.position.y + ALTO_PLATAFORMA * 0.5
	var distancia: float = maxf(0.0, fin_columna.position.y - inicio)
	var cantidad: int = ceili(distancia / ALTO_TRAMO)

	while _tramos.size() < cantidad:
		var tramo := Sprite2D.new()
		tramo.name = "Tramo%d" % _tramos.size()
		tramo.texture = TEXTURA_COLUMNA
		tramo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tramo.scale = Vector2.ONE * ESCALA_COLUMNA
		columnas.add_child(tramo)
		_tramos.append(tramo)
	while _tramos.size() > cantidad:
		var sobrante: Sprite2D = _tramos.pop_back()
		sobrante.queue_free()

	if cantidad == 0:
		return
	for indice in range(cantidad):
		var tramo: Sprite2D = _tramos[indice]
		var inicio_tramo: float = float(indice) * ALTO_TRAMO
		var alto_tramo: float = minf(ALTO_TRAMO, distancia - inicio_tramo)
		var alto_textura: float = alto_tramo / ESCALA_COLUMNA
		tramo.region_enabled = true
		tramo.region_rect = Rect2(0.0, 0.0, TEXTURA_COLUMNA.get_width(), alto_textura)
		tramo.position = Vector2(cuerpo.position.x, inicio + inicio_tramo + alto_tramo * 0.5)


func _get_configuration_warnings() -> PackedStringArray:
	var avisos := PackedStringArray()
	var superior := get_node_or_null("PuntoSuperior") as Marker2D
	var inferior := get_node_or_null("PuntoInferior") as Marker2D
	var final := get_node_or_null("FinColumna") as Marker2D
	if superior == null or inferior == null or final == null:
		return avisos
	if inferior.position.y <= superior.position.y:
		avisos.append("PuntoInferior debe estar debajo de PuntoSuperior.")
	if final.position.y <= superior.position.y + ALTO_PLATAFORMA * 0.5:
		avisos.append("FinColumna debe estar debajo de la plataforma inicial.")
	if absf(inferior.position.x - superior.position.x) > 0.5 \
			or absf(final.position.x - superior.position.x) > 0.5:
		avisos.append("Los tres puntos deben estar alineados verticalmente.")
	return avisos
