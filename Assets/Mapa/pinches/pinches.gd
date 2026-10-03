extends Node2D

enum State { RETRACTED, EXTENDING, EXTENDED, RETRACTING }

@export_range(0.0, 200.0, 1.0) var spike_move_distance: float = 50.0
@export_range(1.0, 1000.0, 1.0) var spike_move_speed: float = 200.0
@export_range(0.05, 60.0, 0.05) var retracted_duration: float = 2.0
@export_range(0.05, 60.0, 0.05) var extended_duration: float = 1.0

@onready var spike_sprite: Sprite2D = $Sprite2D
@onready var killzone: Area2D = $killzone
@onready var retract_timer: Timer = $retract_timer
@onready var spike_timer: Timer = $spike_timer

var state: State = State.RETRACTED
var original_position: Vector2
var target_position: Vector2
var original_killzone_position: Vector2


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("level_resettable")
	original_position = spike_sprite.position
	original_killzone_position = killzone.position
	target_position = original_position - Vector2(0.0, spike_move_distance)
	reset_state()


func reset_state() -> void:
	spike_timer.stop()
	retract_timer.stop()
	state = State.RETRACTED
	spike_sprite.position = original_position
	spike_sprite.visible = false
	killzone.position = original_killzone_position
	spike_timer.start(maxf(retracted_duration, 0.05))


func _physics_process(delta: float) -> void:
	match state:
		State.EXTENDING:
			_move_spikes(target_position, delta)
			if spike_sprite.position == target_position:
				state = State.EXTENDED
				retract_timer.start(maxf(extended_duration, 0.05))
		State.RETRACTING:
			_move_spikes(original_position, delta)
			if spike_sprite.position == original_position:
				state = State.RETRACTED
				spike_sprite.visible = false
				spike_timer.start(maxf(retracted_duration, 0.05))

	# Detecta tambien al jugador que ya estaba encima cuando salen.
	if state != State.RETRACTED:
		for body in killzone.get_overlapping_bodies():
			_on_killzone_body_entered(body)


func _move_spikes(destination: Vector2, delta: float) -> void:
	spike_sprite.position = spike_sprite.position.move_toward(
		destination, maxf(spike_move_speed, 1.0) * delta
	)
	killzone.position = original_killzone_position + spike_sprite.position - original_position


func _on_spike_timer_timeout() -> void:
	if state != State.RETRACTED:
		return
	state = State.EXTENDING
	spike_sprite.visible = true


func _on_retract_timer_timeout() -> void:
	if state == State.EXTENDED:
		state = State.RETRACTING


func _on_killzone_body_entered(body: Node2D) -> void:
	if state != State.RETRACTED and body.is_in_group("player") and body.has_method("die"):
		body.call_deferred("die")
