extends "res://Escenas/niveles/nivel_base.gd"

func _ready() -> void:
	_desacoplar_plataforma_metal()
	super._ready()
	# Hay desniveles grandes entre el punto de inicio y las plataformas.
	player.death_distance = 1800.0
	player.set_spawn_position(spawn_point.global_position)


func _desacoplar_plataforma_metal() -> void:
	var plataforma := get_node_or_null("PuertaPiedraLateral/PlataformaMetal") as Node2D
	if plataforma == null:
		return

	# La compuerta se abre hacia arriba; la plataforma conserva su posición
	# mientras la compuerta se mueve.
	plataforma.reparent(self, true)
	plataforma.z_index = -2
