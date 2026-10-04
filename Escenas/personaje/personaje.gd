extends CharacterBody2D

const FORM_SHADER = preload("res://Escenas/personaje/forma_tint.gdshader")

@export var animacion: AnimatedSprite2D
@export var Trigger: Area2D
@export var death_distance: float = 240.0

@onready var fire_effect: AnimatedSprite2D = $EfectoFuego
@onready var electric_effect: AnimatedSprite2D = $EfectoElectrico
@onready var form_menu = $FormMenu
@onready var hitbox: CollisionShape2D = $Hitbox

signal life_finished(recording: Array)
signal death_started
signal form_changed(form_id: int)

const walk_speed: float = 100.0
const jump_velocity: float = -250.0

const ANIM_IDLE: int = 0
const ANIM_RUN: int = 1
const ANIM_JUMP: int = 2
const DEATH_RESTART_DELAY: float = 1.5
const STATIONARY_POSITION_TOLERANCE_SQUARED: float = 0.01

var _spawn_position: Vector2
var _death_y: float
var _recording: Array[Dictionary] = []
var _recording_time: float = 0.0
var _dead: bool = false
var _death_sequence: int = 0
var _controls_enabled: bool = true
var current_form: int = FormCatalog.NORMAL
var can_transform: bool = true
var _form_material: ShaderMaterial
var _normal_sprite_frames: SpriteFrames

func _ready() -> void:
	_spawn_position = global_position
	_death_y = global_position.y + death_distance
	add_to_group("player")
	form_menu.form_selected.connect(_on_form_selected)
	_setup_form_material()
	reset_form()
	_set_animation(ANIM_IDLE)
	_record_point()


func _unhandled_input(event: InputEvent) -> void:
	if not get_tree().paused and not _dead and _controls_enabled and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		die()


func _physics_process(delta: float) -> void:
	# El reloj de la vida solo avanza durante gameplay. Esta guarda tambien
	# protege la grabacion si el nodo llegara a procesar durante una pausa.
	if get_tree().paused or _dead or not _controls_enabled:
		return

	# Gravedad.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Salto con flecha arriba o barra espaciadora.
	var enter_pressed := Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	var is_jumping := Input.is_action_just_pressed("ui_up") or (Input.is_action_just_pressed("ui_accept") and not enter_pressed)
	if is_jumping and is_on_floor():
		velocity.y = jump_velocity

	# Movimiento horizontal.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * walk_speed
		animacion.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)

	# La animacion depende primero de si el personaje esta en el aire.
	# Asi, moverse horizontalmente durante un salto no cambia a correr.
	if not is_on_floor() or is_jumping:
		_set_animation(ANIM_JUMP)
	elif direction:
		_set_animation(ANIM_RUN)
	else:
		_set_animation(ANIM_IDLE)

	move_and_slide()
	_recording_time += delta

	# Por ahora, caer fuera del nivel es el disparador de muerte.
	# Las trampas y enemigos futuros pueden llamar directamente a die().
	if global_position.y > _death_y:
		die()
		return

	_record_point()


func die() -> void:
	if _dead:
		return

	_dead = true
	death_started.emit()
	_death_sequence += 1
	var death_sequence := _death_sequence
	var finished_recording: Array[Dictionary] = _recording.duplicate(true)
	if finished_recording.is_empty():
		_record_point()
		finished_recording = _recording.duplicate(true)

	_trim_stationary_tail(finished_recording)
	velocity = Vector2.ZERO
	form_menu.close()
	hitbox.set_deferred("disabled", true)
	_update_effect(fire_effect, false, false)
	_update_effect(electric_effect, false, false)
	animacion.play("caer")
	await get_tree().create_timer(DEATH_RESTART_DELAY, false, false, true).timeout
	if death_sequence != _death_sequence or not _dead:
		return

	life_finished.emit(finished_recording)
	_reset_life()


func reset_run() -> void:
	_reset_life()


func transform_to(form_id: int) -> bool:
	if not can_transform or current_form != FormCatalog.NORMAL:
		return false
	if not FormCatalog.is_valid(form_id) or form_id == FormCatalog.NORMAL:
		return false

	current_form = form_id
	can_transform = false
	_apply_form_visual()
	form_changed.emit(current_form)
	# Registra el cambio aunque ocurra entre dos frames de fisica, para que la
	# sombra conserve exactamente el instante en que se eligio la forma.
	_record_point()
	return true


func record_interaction(target: Node, action_name: StringName) -> void:
	if _dead or not _controls_enabled or not is_instance_valid(target) or _recording.is_empty():
		return

	var level_root := get_parent()
	if not is_instance_valid(level_root) or not level_root.is_ancestor_of(target):
		return

	# Las acciones se guardan como puntos de grabacion normales para mantener
	# su posicion y el instante en que ocurrieron durante la reproduccion.
	_recording.append({
		"position": global_position,
		"time": _recording_time,
		"animation": _get_animation_id(),
		"form": current_form,
		"actions": [{
			"type": action_name,
			"target_path": level_root.get_path_to(target),
		}],
	})


func get_form_id() -> int:
	return current_form


func can_open_form_menu() -> bool:
	return not _dead and _controls_enabled and can_transform and current_form == FormCatalog.NORMAL


func _on_form_selected(form_id: int) -> void:
	if not form_menu.visible:
		return
	transform_to(form_id)
	form_menu.close()


func reset_form() -> void:
	var changed := current_form != FormCatalog.NORMAL or not can_transform
	current_form = FormCatalog.NORMAL
	can_transform = true
	_apply_form_visual()
	if changed:
		form_changed.emit(current_form)


func set_spawn_position(value: Vector2) -> void:
	_spawn_position = value
	_death_y = value.y + death_distance
	global_position = value
	velocity = Vector2.ZERO


func set_controls_enabled(value: bool) -> void:
	_controls_enabled = value
	if not _controls_enabled:
		form_menu.close()
		velocity = Vector2.ZERO


func _reset_life() -> void:
	_death_sequence += 1
	hitbox.set_deferred("disabled", false)
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_recording.clear()
	_recording_time = 0.0
	_dead = false
	reset_form()
	_set_animation(ANIM_IDLE)
	_record_point()


func _record_point() -> void:
	_recording.append({
		"position": global_position,
		"time": _recording_time,
		"animation": _get_animation_id(),
		"form": current_form,
	})


func _trim_stationary_tail(recording: Array[Dictionary]) -> void:
	if recording.size() < 2:
		return

	var final_index := recording.size() - 1
	var final_point: Dictionary = recording[final_index]
	var final_position: Vector2 = final_point["position"]
	var stationary_start := final_index

	while stationary_start > 0:
		var previous_position: Vector2 = recording[stationary_start - 1]["position"]
		if previous_position.distance_squared_to(final_position) > STATIONARY_POSITION_TOLERANCE_SQUARED:
			break
		stationary_start -= 1

	if stationary_start == final_index:
		return

	# No recortes una interaccion que ocurrio durante la espera al final de la
	# grabacion. La sombra debe conservarla y ejecutarla en ese mismo lugar.
	var last_action_index := -1
	for index in range(stationary_start, final_index + 1):
		if not recording[index].get("actions", []).is_empty():
			last_action_index = index
	if last_action_index >= stationary_start:
		var action_point: Dictionary = recording[last_action_index]
		for index in range(last_action_index + 1, final_index + 1):
			if recording[index].get("form", FormCatalog.NORMAL) != action_point.get("form", FormCatalog.NORMAL):
				return
			if recording[index].get("animation", ANIM_IDLE) != action_point.get("animation", ANIM_IDLE):
				return
		recording.resize(last_action_index + 1)
		return

	# Mantiene el punto donde termino el movimiento y lo actualiza al estado
	# final para quitar la espera inmovil antes de que se pulsara R.
	var final_stationary_point: Dictionary = recording[stationary_start].duplicate(true)
	final_stationary_point["position"] = final_position
	final_stationary_point["animation"] = final_point["animation"]
	final_stationary_point["form"] = final_point.get("form", FormCatalog.NORMAL)
	recording.resize(stationary_start + 1)
	recording[stationary_start] = final_stationary_point


func _setup_form_material() -> void:
	if not is_instance_valid(animacion):
		return
	_form_material = ShaderMaterial.new()
	_form_material.shader = FORM_SHADER
	_normal_sprite_frames = animacion.sprite_frames
	animacion.material = _form_material


func _apply_form_visual() -> void:
	_update_form_effects()
	if not is_instance_valid(_form_material):
		return
	var form_frames := FormCatalog.get_sprite_frames(current_form)
	if form_frames != null:
		animacion.sprite_frames = form_frames
		_form_material.set_shader_parameter("tint_color", FormCatalog.get_tint(current_form))
		_form_material.set_shader_parameter("grayscale_strength", 1.0 if current_form == FormCatalog.METAL else 0.0)
	else:
		animacion.sprite_frames = _normal_sprite_frames
		_form_material.set_shader_parameter("tint_color", FormCatalog.get_tint(current_form))
		_form_material.set_shader_parameter("grayscale_strength", 1.0 if current_form == FormCatalog.METAL else 0.0)


func _update_form_effects(restart: bool = false) -> void:
	_update_effect(fire_effect, current_form == FormCatalog.FUEGO, restart)
	_update_effect(electric_effect, current_form == FormCatalog.ELECTRICA, restart)


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


func _get_animation_id() -> int:
	if not is_instance_valid(animacion):
		return ANIM_IDLE

	match animacion.animation:
		&"correr":
			return ANIM_RUN
		&"saltar":
			return ANIM_JUMP
		_:
			return ANIM_IDLE


func _set_animation(animation_id: int) -> void:
	if not is_instance_valid(animacion):
		return

	match animation_id:
		ANIM_RUN:
			animacion.play("correr")
		ANIM_JUMP:
			animacion.play("saltar")
		_:
			animacion.play("idle")
#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up"))  and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()
