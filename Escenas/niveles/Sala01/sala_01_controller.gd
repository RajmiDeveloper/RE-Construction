extends "res://Escenas/niveles/nivel_base.gd"

## Extiende el controlador reutilizable para ubicar los mecanismos sobre el
## suelo del mapa personalizado de la Sala 1.
@onready var button: Area2D = $Mecanismos/Boton

func _ready() -> void:
	super._ready()
	# Este mapa tiene sectores altos; deja que el personaje alcance el piso
	# antes de aplicar el limite de caida general.
	player.death_distance = 1800.0
	player.set_spawn_position(spawn_point.global_position)
	call_deferred("_place_mechanisms_on_floor")


func _place_mechanisms_on_floor() -> void:
	# Espera a que TileMapLayer registre sus colisiones y el jugador se asiente.
	for _frame in range(90):
		if player.is_on_floor():
			break
		await get_tree().physics_frame

	var button_x := spawn_point.global_position.x + 96.0
	var exit_x := spawn_point.global_position.x + 240.0
	var fallback_floor_y: float = player.global_position.y + 8.0
	var button_floor_y := _find_floor_y(button_x, fallback_floor_y)
	var exit_floor_y := _find_floor_y(exit_x, fallback_floor_y)
	button.global_position = Vector2(button_x, button_floor_y - 7.0)
	exit_door.global_position = Vector2(exit_x, exit_floor_y - 11.0)


func _find_floor_y(world_x: float, fallback_y: float) -> float:
	var ray_start := Vector2(world_x, player.global_position.y - 24.0)
	var ray_end := Vector2(world_x, player.global_position.y + 1200.0)
	var query := PhysicsRayQueryParameters2D.create(
		ray_start,
		ray_end,
		1,
		[player.get_rid()]
	)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return fallback_y
	return hit["position"].y
