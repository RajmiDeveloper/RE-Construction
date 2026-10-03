extends CharacterBody2D

const SPEED = 120.0         
const ACCELERATION = 600.0   
const FRICTION = 800.0       
const JUMP_VELOCITY = -300.0

const WALL_JUMP_VEL_Y = -250.0 
const WALL_JUMP_VEL_X = 180.0  

# Referencia al nodo AnimatedSprite2D de Sonic
@onready var animated_sprite = $AnimatedSprite2D

# Variable para guardar dónde arrancó Sonic (el agua la usará para reubicarlo)
var start_position: Vector2

# --- VARIABLES PARA EL IDLE ESPECIAL ---
var idle_timer: float = 0.0
const TIME_TO_SPECIAL_IDLE: float = 4.0 # Segundos de espera antes de la animación especial
var is_special_idle: bool = false

func _ready() -> void:
	# Guardamos su posición inicial apenas empieza la escena
	start_position = global_position
	
	# Conectamos la señal para saber cuándo termina la animación especial
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. Gravedad y deslizamiento en pared
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0:
			velocity += (get_gravity() * 0.3) * delta 
		else:
			velocity += get_gravity() * delta

	# 2. Manejo del salto y salto en pared
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall() and not is_on_floor():
			velocity.y = WALL_JUMP_VEL_Y
			var normal = get_wall_normal()
			velocity.x = normal.x * WALL_JUMP_VEL_X

	# 3. Movimiento horizontal con aceleración y fricción
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		
		# Control visual de Sonic: Voltear y reproducir animación de correr
		animated_sprite.flip_h = direction < 0
		animated_sprite.play("correr")
		
		# Si se mueve, reiniciamos el contador de quietud
		idle_timer = 0.0
		is_special_idle = false
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
		# Si está en el suelo y no está reproduciendo el idle especial, contamos el tiempo
		if is_on_floor() and not is_special_idle:
			idle_timer += delta
			
			if idle_timer >= TIME_TO_SPECIAL_IDLE:
				animated_sprite.play("idle")
		elif not is_on_floor():
			idle_timer = 0.0
			is_special_idle = false

	# 4. Movimiento físico principal
	_slide_and_move_wrapper() # O move_and_slide() según tengas

func _slide_and_move_wrapper():
	move_and_slide()

# Función que se ejecuta automáticamente cuando una animación de termina
func _on_animation_finished() -> void:
		animated_sprite.play("idle")
