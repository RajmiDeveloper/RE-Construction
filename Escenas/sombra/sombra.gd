extends StaticBody2D

const ANIM_IDLE: int = 0
const ANIM_RUN: int = 1
const ANIM_JUMP: int = 2
# Capa exclusiva para interacciones de sombras.
# El jugador no utiliza esta capa en su collision_mask, por lo que no choca
# con las sombras cuando se vuelven fisicas.
const SOLID_COLLISION_LAYER: int = 8

@onready var animacion: AnimatedSprite2D = $Animacion
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _recording: Array[Dictionary] = []
var _elapsed: float = 0.0
var _point_index: int = 0
var _replaying: bool = false

func _ready() -> void:
	collision_shape.disabled = true
	collision_layer = 0
	collision_mask = 0
	modulate = Color(0.45, 0.55, 0.9, 0.62)


func start_replay(recording: Array) -> void:
	_recording.clear()
	for point in recording:
		if point is Dictionary and point.has("position") and point.has("time"):
			_recording.append(point)

	restart_replay()


func restart_replay() -> void:
	if _recording.is_empty():
		_become_solid()
		return

	# Una sombra que ya era física vuelve a ser intangible al comenzar
	# el siguiente intento.
	collision_layer = 0
	collision_mask = 0
	collision_shape.set_deferred("disabled", true)
	_elapsed = 0.0
	_point_index = 0
	_replaying = true
	global_position = _recording[0]["position"]
	_apply_visual(_recording[0]["animation"])


func _physics_process(delta: float) -> void:
	if not _replaying:
		return

	_elapsed += delta
	var final_time: float = _recording.back()["time"]
	if _elapsed >= final_time:
		global_position = _recording.back()["position"]
		_apply_visual(_recording.back()["animation"])
		_become_solid()
		return

	while _point_index + 1 < _recording.size() and _recording[_point_index + 1]["time"] <= _elapsed:
		_point_index += 1

	var from_point: Dictionary = _recording[_point_index]
	var to_point: Dictionary = _recording[min(_point_index + 1, _recording.size() - 1)]
	var from_time: float = from_point["time"]
	var to_time: float = to_point["time"]
	var segment_length: float = to_time - from_time
	var segment_progress: float = 1.0
	if segment_length > 0.0:
		segment_progress = clamp((_elapsed - from_time) / segment_length, 0.0, 1.0)

	global_position = from_point["position"].lerp(to_point["position"], segment_progress)
	_apply_visual(from_point["animation"])

	if not is_zero_approx(to_point["position"].x - from_point["position"].x):
		animacion.flip_h = to_point["position"].x < from_point["position"].x


func _apply_visual(animation_id: int) -> void:
	match animation_id:
		ANIM_RUN:
			animacion.play("correr")
		ANIM_JUMP:
			animacion.play("saltar")
		_:
			animacion.play("idle")


func _become_solid() -> void:
	_replaying = false
	animacion.play("idle")
	animacion.stop()
	animacion.frame = 0
	animacion.frame_progress = 0.0
	animacion.flip_h = false
	collision_layer = SOLID_COLLISION_LAYER
	collision_mask = 0
	collision_shape.set_deferred("disabled", false)
