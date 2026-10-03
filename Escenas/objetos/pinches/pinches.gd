extends Node2D

enum State { RETRACTED, EXTENDING, EXTENDED, RETRACTING }

@export_range(0.01, 1.0, 0.01) var animation_frame_duration: float = 0.2
@export_range(0.05, 60.0, 0.05) var retracted_duration: float = 2.5
@export_range(0.05, 60.0, 0.05) var extended_duration: float = 1.5

@onready var spike_sprite: Sprite2D = $Sprite2D
@onready var killzone: Area2D = $killzone
@onready var killzone_shape: CollisionShape2D = $killzone/CollisionShape2D
@onready var retract_timer: Timer = $retract_timer
@onready var spike_timer: Timer = $spike_timer

var state: State = State.RETRACTED
var _frame_accumulator: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("level_resettable")
	killzone_shape.shape = killzone_shape.shape.duplicate()
	reset_state()


func reset_state() -> void:
	spike_timer.stop()
	retract_timer.stop()
	state = State.RETRACTED
	_frame_accumulator = 0.0
	_set_frame(0)
	spike_timer.start(maxf(retracted_duration, 0.05))


func _physics_process(delta: float) -> void:
	match state:
		State.EXTENDING:
			_advance_animation(delta, 1)
		State.RETRACTING:
			_advance_animation(delta, -1)

	# Detecta tambien al jugador que ya estaba encima cuando sale el pincho.
	if state != State.RETRACTED:
		for body in killzone.get_overlapping_bodies():
			_on_killzone_body_entered(body)


func _advance_animation(delta: float, direction: int) -> void:
	_frame_accumulator += delta
	var frame_duration := maxf(animation_frame_duration, 0.01)
	while _frame_accumulator >= frame_duration:
		_frame_accumulator -= frame_duration
		_set_frame(spike_sprite.frame + direction)
		if direction > 0 and spike_sprite.frame >= 3:
			state = State.EXTENDED
			retract_timer.start(maxf(extended_duration, 0.05))
			_frame_accumulator = 0.0
			return
		if direction < 0 and spike_sprite.frame <= 0:
			state = State.RETRACTED
			spike_timer.start(maxf(retracted_duration, 0.05))
			_frame_accumulator = 0.0
			return


func _set_frame(frame_index: int) -> void:
	spike_sprite.frame = frame_index
	var frame_heights: Array[float] = [0.0, 5.0, 12.0, 19.0]
	var frame_widths: Array[float] = [0.0, 20.0, 20.0, 20.0]
	var height := frame_heights[frame_index]
	killzone_shape.disabled = height == 0.0
	if height > 0.0:
		var rectangle := killzone_shape.shape as RectangleShape2D
		rectangle.size = Vector2(frame_widths[frame_index], height)
		killzone_shape.position = Vector2(0.0, -height / 2.0)


func _on_spike_timer_timeout() -> void:
	if state != State.RETRACTED:
		return
	state = State.EXTENDING
	_frame_accumulator = 0.0


func _on_retract_timer_timeout() -> void:
	if state == State.EXTENDED:
		state = State.RETRACTING
		_frame_accumulator = 0.0


func _on_killzone_body_entered(body: Node2D) -> void:
	if state != State.RETRACTED and body.is_in_group("player") and body.has_method("die"):
		body.call_deferred("die")
