extends "res://Escenas/niveles/nivel_base.gd"

func _ready() -> void:
	super._ready()
	# Hay desniveles grandes entre el punto de inicio y las plataformas.
	player.death_distance = 1800.0
	player.set_spawn_position(spawn_point.global_position)
