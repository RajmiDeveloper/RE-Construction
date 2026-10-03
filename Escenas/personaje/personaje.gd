extends CharacterBody2D

@export var animacion: AnimatedSprite2D
@export var Trigger: Area2D
const walk_speed: float = 100.0
const jump_velocity: float = -250.0

func _ready() -> void:
	debug()


func debug():
	print("speed: ", walk_speed)
	print("jump_speed: ", jump_velocity)
	print( velocity)
	pass

func _physics_process(delta: float) -> void:
	
	#gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#salto con flecha o barra
	var is_jumping := Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept")
	if (is_jumping  and is_on_floor()):
		velocity.y = jump_velocity
		animacion.play("saltar")
	
	#direccion en X, con las flechas
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * walk_speed
		if not is_jumping:
			animacion.play("correr")
		if direction > 0:
			animacion.flip_h = false
		else:
			animacion.flip_h = true
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
	
	if velocity.is_zero_approx():
		animacion.play("idle")
		
	move_and_slide()
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
