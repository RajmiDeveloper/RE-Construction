extends CharacterBody2D

@export var animacion: AnimatedSprite2D
@export var Trigger: Area2D
@export var death_distance: float = 240.0

signal life_finished(recording: Array)

const walk_speed: float = 100.0
const jump_velocity: float = -250.0

const ANIM_IDLE: int = 0
const ANIM_RUN: int = 1
const ANIM_JUMP: int = 2

var _spawn_position: Vector2
var _death_y: float
var _recording: Array[Dictionary] = []
var _recording_time: float = 0.0
var _dead: bool = false

func _ready() -> void:
	_spawn_position = global_position
	_death_y = global_position.y + death_distance
	_set_animation(ANIM_IDLE)
	_record_point()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		die()


func _physics_process(delta: float) -> void:
	if _dead:
		return

	# Gravedad.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Salto con flecha arriba o barra espaciadora.
	var is_jumping := Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept")
	if is_jumping and is_on_floor():
		velocity.y = jump_velocity
		_set_animation(ANIM_JUMP)

	# Movimiento horizontal.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * walk_speed
		if not is_jumping:
			_set_animation(ANIM_RUN)
		animacion.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)

	if is_on_floor() and is_zero_approx(velocity.x):
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
	var finished_recording: Array = _recording.duplicate(true)
	if finished_recording.is_empty():
		_record_point()
		finished_recording = _recording.duplicate(true)

	life_finished.emit(finished_recording)
	_reset_life()


func reset_run() -> void:
	_reset_life()


func _reset_life() -> void:
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_recording.clear()
	_recording_time = 0.0
	_dead = false
	_set_animation(ANIM_IDLE)
	_record_point()


func _record_point() -> void:
	_recording.append({
		"position": global_position,
		"time": _recording_time,
		"animation": _get_animation_id()
	})


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
