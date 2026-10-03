extends StaticBody2D

const FORM_SHADER = preload("res://Escenas/personaje/forma_tint.gdshader")

const ANIM_IDLE: int = 0
const ANIM_RUN: int = 1
const ANIM_JUMP: int = 2
# Capa exclusiva para interacciones de sombras.
# El jugador no utiliza esta capa en su collision_mask, por lo que no choca
# con las sombras cuando se vuelven fisicas.
const SOLID_COLLISION_LAYER: int = 8

@onready var animacion: AnimatedSprite2D = $Animacion
@onready var fire_effect: AnimatedSprite2D = $EfectoFuego
@onready var electric_effect: AnimatedSprite2D = $EfectoElectrico
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/CollisionShape2D

var _recording: Array[Dictionary] = []
var _elapsed: float = 0.0
var _point_index: int = 0
var _replaying: bool = false
var _current_form: int = FormCatalog.NORMAL
var _form_material: ShaderMaterial
var _normal_sprite_frames: SpriteFrames

func _ready() -> void:
	collision_shape.disabled = true
	collision_layer = 0
	collision_mask = 0
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 0
	interaction_area.monitorable = false
	interaction_area.monitoring = false
	interaction_area.add_to_group("shadow_interaction")
	_setup_form_material()
	_apply_form_visual()
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
	interaction_area.collision_layer = 0
	interaction_area.monitorable = false
	interaction_shape.set_deferred("disabled", true)
	_elapsed = 0.0
	_point_index = 0
	_replaying = true
	global_position = _recording[0]["position"]
	_apply_visual(_recording[0]["animation"])
	_apply_form(_recording[0].get("form", FormCatalog.NORMAL))
	_update_form_effects(true)


func _physics_process(delta: float) -> void:
	# El recorrido se reproduce con tiempo de fisica activo, nunca con tiempo
	# transcurrido del menu de formas o del menu de pausa.
	if get_tree().paused or not _replaying:
		return

	_elapsed += delta
	var final_time: float = _recording.back()["time"]
	if _elapsed >= final_time:
		global_position = _recording.back()["position"]
		_apply_visual(_recording.back()["animation"])
		_apply_form(_recording.back().get("form", FormCatalog.NORMAL))
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
	_apply_form(from_point.get("form", FormCatalog.NORMAL))

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
	if not _recording.is_empty():
		_apply_form(_recording.back().get("form", FormCatalog.NORMAL))
	animacion.play("idle")
	animacion.stop()
	animacion.frame = 0
	animacion.frame_progress = 0.0
	animacion.flip_h = false
	collision_layer = SOLID_COLLISION_LAYER
	collision_mask = 0
	collision_shape.set_deferred("disabled", false)
	interaction_area.collision_layer = SOLID_COLLISION_LAYER
	interaction_area.monitorable = true
	interaction_shape.set_deferred("disabled", false)


func set_form(form_id: int) -> void:
	if not FormCatalog.is_valid(form_id):
		form_id = FormCatalog.NORMAL
	if _current_form == form_id:
		return
	_current_form = form_id
	_apply_form_visual()


func get_form_id() -> int:
	return _current_form


func _setup_form_material() -> void:
	_form_material = ShaderMaterial.new()
	_form_material.shader = FORM_SHADER
	_normal_sprite_frames = animacion.sprite_frames
	animacion.material = _form_material


func _apply_form(form_id: int) -> void:
	set_form(form_id)


func _apply_form_visual() -> void:
	_update_form_effects()
	if is_instance_valid(_form_material):
		var form_frames := FormCatalog.get_sprite_frames(_current_form)
		if form_frames != null:
			animacion.sprite_frames = form_frames
			_form_material.set_shader_parameter("tint_color", Color.WHITE)
			_form_material.set_shader_parameter("grayscale_strength", 0.0)
		else:
			animacion.sprite_frames = _normal_sprite_frames
			_form_material.set_shader_parameter("tint_color", FormCatalog.get_tint(_current_form))
			_form_material.set_shader_parameter("grayscale_strength", 1.0 if _current_form == FormCatalog.METAL else 0.0)


func _update_form_effects(restart: bool = false) -> void:
	_update_effect(fire_effect, _current_form == FormCatalog.FUEGO, restart)
	_update_effect(electric_effect, _current_form == FormCatalog.ELECTRICA, restart)


func _update_effect(effect: AnimatedSprite2D, should_play: bool, restart: bool) -> void:
	if not is_instance_valid(effect):
		return
	if should_play:
		effect.visible = true
		if restart or not effect.is_playing():
			effect.play("default")
	else:
		effect.visible = false
		effect.stop()
		effect.frame = 0
