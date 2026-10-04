extends "res://Escenas/niveles/nivel_base.gd"

@export_node_path("AnimatableBody2D") var gate_path: NodePath = NodePath("Mecanismos/Compuerta")
@export_range(0.0, 32.0, 1.0) var form_switch_margin: float = 5.0


func get_allowed_transformations(player_position: Vector2) -> Array[int]:
	return [get_required_transformation(player_position)]


func get_required_transformation(player_position: Vector2) -> int:
	var gate_shape := get_node_or_null(NodePath(str(gate_path) + "/CollisionShape2D")) as CollisionShape2D
	if gate_shape == null or gate_shape.shape == null:
		return FormCatalog.METAL
	var right_edge := gate_shape.to_global(Vector2(gate_shape.shape.get_rect().end.x, 0.0)).x
	return FormCatalog.ELECTRICA if player_position.x > right_edge + form_switch_margin else FormCatalog.METAL
