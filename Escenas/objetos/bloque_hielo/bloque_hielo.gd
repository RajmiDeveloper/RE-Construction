extends Node2D

const PLAYER_COLLISION_LAYER: int = 4
const SHADOW_COLLISION_LAYER: int = 8
const MELT_SECONDS_PER_FRAME: float = 1.0
const MELTING_FRAME_COUNT: int = 4

@onready var sprite: Sprite2D = $Sprite2D
@onready var solid_shape: CollisionShape2D = $SolidBody/CollisionShape2D
@onready var heat_area: Area2D = $HeatArea

var _melt_elapsed: float = 0.0
var _disappeared: bool = false


func _ready() -> void:
	add_to_group("level_resettable")
	sprite.frame = 0


func _physics_process(delta: float) -> void:
	if _disappeared or get_tree().paused or not _has_nearby_fire_form():
		return

	_melt_elapsed += delta
	while _melt_elapsed >= MELT_SECONDS_PER_FRAME and not _disappeared:
		_melt_elapsed -= MELT_SECONDS_PER_FRAME
		if sprite.frame < MELTING_FRAME_COUNT - 1:
			sprite.frame += 1
		else:
			_disappear()


func reset_state() -> void:
	_melt_elapsed = 0.0
	_disappeared = false
	sprite.frame = 0
	sprite.visible = true
	solid_shape.set_deferred("disabled", false)
	heat_area.set_deferred("monitoring", true)


func _has_nearby_fire_form() -> bool:
	for body in heat_area.get_overlapping_bodies():
		if not _is_fire_form(body):
			continue
		if body.is_in_group("player"):
			return true

		var collision_body := body as CollisionObject2D
		if collision_body != null and (collision_body.collision_layer & SHADOW_COLLISION_LAYER) != 0:
			return true

	for area in heat_area.get_overlapping_areas():
		if not area.is_in_group("shadow_interaction"):
			continue
		if _is_fire_form(area.get_parent()):
			return true

	return false


func _is_fire_form(node: Node) -> bool:
	return is_instance_valid(node) and node.has_method("get_form_id") and int(node.call("get_form_id")) == FormCatalog.FUEGO


func _disappear() -> void:
	_disappeared = true
	sprite.visible = false
	solid_shape.set_deferred("disabled", true)
	heat_area.set_deferred("monitoring", false)
