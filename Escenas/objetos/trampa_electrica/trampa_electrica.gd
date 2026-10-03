@tool
extends Area2D

const RAYO_SHEET: Texture2D = preload("res://Assets/Mapa/Trampas/rayo_vertical_4f.png")
const CUADRO: float = 24.0
const CANTIDAD_CUADROS: int = 4

@export_node_path("Sprite2D") var modulo_superior_path: NodePath
@export_node_path("Sprite2D") var modulo_inferior_path: NodePath
@export var starts_active: bool = true
@export_range(1.0, 24.0, 1.0) var cuadros_por_segundo: float = 8.0
@export_range(1.0, 48.0, 1.0) var ancho_zona_peligro: float = 14.0

@onready var rayos: Node2D = $Rayos
@onready var zona_peligro: CollisionShape2D = $ZonaPeligro

var _modulo_superior: Sprite2D
var _modulo_inferior: Sprite2D
var _segmentos: Array[Sprite2D] = []
var _ultimo_inicio: Vector2
var _ultimo_fin: Vector2
var _ultimo_ancho_zona: float = -1.0
var _geometria_valida: bool = false
var _active: bool = true
var _initial_active: bool = true
var _tiempo: float = 0.0
var _cuadro_actual: int = 0


func _ready() -> void:
	_initial_active = starts_active
	_active = starts_active
	monitoring = _active
	set_process(true)
	if not Engine.is_editor_hint():
		add_to_group("level_resettable")
		body_entered.connect(_on_body_entered)
	if not _active:
		_limpiar_descarga()
		return
	_process(0.0)


func _process(delta: float) -> void:
	if not _active:
		return

	var modulo_superior_actual := _resolver_modulo(modulo_superior_path)
	var modulo_inferior_actual := _resolver_modulo(modulo_inferior_path)
	if modulo_superior_actual != _modulo_superior or modulo_inferior_actual != _modulo_inferior:
		_modulo_superior = modulo_superior_actual
		_modulo_inferior = modulo_inferior_actual
		_geometria_valida = false

	if not is_instance_valid(_modulo_superior) or not is_instance_valid(_modulo_inferior):
		_limpiar_descarga()
		if Engine.is_editor_hint():
			update_configuration_warnings()
		return

	var inicio := _obtener_borde_inferior(_modulo_superior)
	var fin := _obtener_borde_superior(_modulo_inferior)
	if not _geometria_valida or inicio != _ultimo_inicio or fin != _ultimo_fin or ancho_zona_peligro != _ultimo_ancho_zona:
		_ultimo_inicio = inicio
		_ultimo_fin = fin
		_ultimo_ancho_zona = ancho_zona_peligro
		_geometria_valida = true
		_reconstruir_descarga(inicio, fin)

	if Engine.is_editor_hint():
		return

	_tiempo += delta
	var duracion_cuadro: float = 1.0 / maxf(cuadros_por_segundo, 1.0)
	while _tiempo >= duracion_cuadro:
		_tiempo -= duracion_cuadro
		_cuadro_actual = (_cuadro_actual + 1) % CANTIDAD_CUADROS
		_actualizar_cuadros()


func set_active(value: bool) -> void:
	if _active == value:
		return
	_active = value
	monitoring = _active
	if not _active:
		_limpiar_descarga()
		return
	_geometria_valida = false
	_process(0.0)


func reset_state() -> void:
	set_active(_initial_active)


func _resolver_modulo(path: NodePath) -> Sprite2D:
	if path.is_empty():
		return null
	return get_node_or_null(path) as Sprite2D


func _obtener_borde_inferior(modulo: Sprite2D) -> Vector2:
	var alto := _alto_modulo(modulo)
	var extremo_a := to_local(modulo.to_global(Vector2(0.0, -alto * 0.5)))
	var extremo_b := to_local(modulo.to_global(Vector2(0.0, alto * 0.5)))
	return extremo_a if extremo_a.y > extremo_b.y else extremo_b


func _obtener_borde_superior(modulo: Sprite2D) -> Vector2:
	var alto := _alto_modulo(modulo)
	var extremo_a := to_local(modulo.to_global(Vector2(0.0, -alto * 0.5)))
	var extremo_b := to_local(modulo.to_global(Vector2(0.0, alto * 0.5)))
	return extremo_a if extremo_a.y < extremo_b.y else extremo_b


func _alto_modulo(modulo: Sprite2D) -> float:
	if modulo.texture == null:
		return CUADRO
	return float(modulo.texture.get_height())


func _reconstruir_descarga(inicio: Vector2, fin: Vector2) -> void:
	_limpiar_descarga()
	var alineados := absf(inicio.x - fin.x) <= 0.5
	var distancia := fin.y - inicio.y
	if not alineados or distancia < CUADRO:
		if Engine.is_editor_hint():
			update_configuration_warnings()
		return

	var forma := RectangleShape2D.new()
	forma.size = Vector2(ancho_zona_peligro, distancia)
	zona_peligro.shape = forma
	zona_peligro.position = Vector2((inicio.x + fin.x) * 0.5, (inicio.y + fin.y) * 0.5)
	zona_peligro.disabled = false

	var cantidad: int = maxi(1, roundi(distancia / CUADRO))
	var alto_segmento: float = distancia / float(cantidad)
	for indice in range(cantidad):
		var segmento := Sprite2D.new()
		segmento.name = "Rayo%d" % indice
		segmento.texture = RAYO_SHEET
		segmento.hframes = CANTIDAD_CUADROS
		segmento.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		segmento.position = Vector2((inicio.x + fin.x) * 0.5, inicio.y + (float(indice) + 0.5) * alto_segmento)
		segmento.scale = Vector2(1.0, alto_segmento / CUADRO)
		segmento.frame = (_cuadro_actual + indice) % CANTIDAD_CUADROS
		rayos.add_child(segmento)
		_segmentos.append(segmento)

	if Engine.is_editor_hint():
		update_configuration_warnings()


func _limpiar_descarga() -> void:
	for segmento in _segmentos:
		if is_instance_valid(segmento):
			segmento.free()
	_segmentos.clear()
	zona_peligro.disabled = true


func _actualizar_cuadros() -> void:
	for indice in range(_segmentos.size()):
		_segmentos[indice].frame = (_cuadro_actual + indice) % CANTIDAD_CUADROS


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		if body.has_method("get_form_id") and body.call("get_form_id") == FormCatalog.ELECTRICA:
			return
		body.call_deferred("die")


func _get_configuration_warnings() -> PackedStringArray:
	var avisos := PackedStringArray()
	var superior := _resolver_modulo(modulo_superior_path)
	var inferior := _resolver_modulo(modulo_inferior_path)
	if superior == null:
		avisos.append("Asigna el modulo electrico superior en el Inspector.")
	if inferior == null:
		avisos.append("Asigna el modulo electrico inferior en el Inspector.")
	if superior == null or inferior == null:
		return avisos
	if absf(_obtener_borde_inferior(superior).x - _obtener_borde_superior(inferior).x) > 0.5:
		avisos.append("Los modulos deben estar alineados verticalmente.")
	var distancia := _obtener_borde_superior(inferior).y - _obtener_borde_inferior(superior).y
	if distancia < CUADRO:
		avisos.append("Separa los modulos para dejar al menos 24 píxeles para el rayo.")
	return avisos
