@tool
extends Control

const DESIGN_SIZE := Vector2(1280, 720)


func _ready() -> void:
	resized.connect(_fit_design)
	_fit_design.call_deferred()


func _fit_design() -> void:
	var design := get_node_or_null("Design") as Control
	if design == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	design.scale = Vector2.ONE * factor
	design.position = (size - DESIGN_SIZE * factor) * 0.5
