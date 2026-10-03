extends Area2D

signal state_changed(is_pressed: bool)

const PLAYER_LAYER: int = 4
const SHADOW_LAYER: int = 8

@export var texture_released: Texture2D
@export var texture_pressed: Texture2D
@export var required_form_id: int = FormCatalog.METAL

@onready var sprite: Sprite2D = $Sprite2D

var is_pressed: bool = false
var _pressing_bodies: Array[Node2D] = []
var _pressing_areas: Array[Area2D] = []

func _ready() -> void:
	add_to_group("level_resettable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_update_visual()


func _physics_process(_delta: float) -> void:
	# Tambien se consulta el area en cada frame para detectar cuerpos cuya
	# colision se habilito mientras ya estaban superpuestos, como una sombra
	# que acaba de solidificarse encima del boton.
	_pressing_bodies.clear()
	for body in get_overlapping_bodies():
		if _is_pressing_body(body):
			_pressing_bodies.append(body)
	_pressing_areas.clear()
	for area in get_overlapping_areas():
		if _is_pressing_area(area):
			_pressing_areas.append(area)
	_update_state()


func _on_body_entered(body: Node2D) -> void:
	if not _is_pressing_body(body):
		return
	if not _pressing_bodies.has(body):
		_pressing_bodies.append(body)
	_update_state()


func _on_body_exited(body: Node2D) -> void:
	if _pressing_bodies.has(body):
		_pressing_bodies.erase(body)
	_update_state()


func _on_area_entered(area: Area2D) -> void:
	if _is_pressing_area(area) and not _pressing_areas.has(area):
		_pressing_areas.append(area)
	_update_state()


func _on_area_exited(area: Area2D) -> void:
	if _pressing_areas.has(area):
		_pressing_areas.erase(area)
	_update_state()


func _is_pressing_body(body: Node2D) -> bool:
	if not is_instance_valid(body):
		return false

	var collision_body := body as CollisionObject2D
	if collision_body == null:
		return false

	var layer: int = collision_body.collision_layer
	if (layer & PLAYER_LAYER) == 0 and (layer & SHADOW_LAYER) == 0:
		return false
	return body.has_method("get_form_id") and body.call("get_form_id") == required_form_id


func _is_pressing_area(area: Area2D) -> bool:
	if not is_instance_valid(area) or not area.is_in_group("shadow_interaction"):
		return false
	var shadow := area.get_parent()
	return is_instance_valid(shadow) and shadow.has_method("get_form_id") and shadow.call("get_form_id") == required_form_id


func _update_state() -> void:
	for index in range(_pressing_bodies.size() - 1, -1, -1):
		if not is_instance_valid(_pressing_bodies[index]):
			_pressing_bodies.remove_at(index)
	for index in range(_pressing_areas.size() - 1, -1, -1):
		if not is_instance_valid(_pressing_areas[index]):
			_pressing_areas.remove_at(index)

	var new_state := not _pressing_bodies.is_empty() or not _pressing_areas.is_empty()
	if new_state == is_pressed:
		return

	is_pressed = new_state
	_update_visual()
	state_changed.emit(is_pressed)


func _update_visual() -> void:
	if not is_instance_valid(sprite):
		return

	sprite.texture = texture_pressed if is_pressed else texture_released


func reset_state() -> void:
	_pressing_bodies.clear()
	_pressing_areas.clear()
	is_pressed = false
	_update_visual()
	state_changed.emit(false)
