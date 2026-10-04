extends Node

signal rewind_finished

const FREEZE_DURATION: float = 0.5
const REWIND_DURATION: float = 1.0

enum Phase { IDLE, FROZEN, REWINDING }

var _level: Node2D
var _mechanisms: Array[Node] = []
var _initial: Dictionary = {}
var _frozen: Dictionary = {}
var _saved_process_modes: Dictionary = {}
var _temporary_visuals: Array[Node] = []
var _native_rewind_mechanisms: Array[Node] = []
var _phase: Phase = Phase.IDLE
var _generation: int = 0
var _tween: Tween


func configure(level: Node2D) -> void:
	_level = level
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_capture_initial")


func is_rewinding() -> bool:
	return _phase != Phase.IDLE


func start_rewind() -> void:
	if _phase != Phase.IDLE:
		return
	if _initial.is_empty():
		_capture_initial()
	_generation += 1
	var generation := _generation
	_frozen = _snapshot_all()
	_saved_process_modes.clear()
	for mechanism in _mechanisms:
		if is_instance_valid(mechanism) and mechanism.has_method("freeze_for_rewind"):
			mechanism.call("freeze_for_rewind")
	for state in _frozen.values():
		var node = state.get("node")
		if not is_instance_valid(node):
			continue
		_saved_process_modes[node.get_instance_id()] = {"node": node, "mode": node.process_mode}
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is AnimatedSprite2D:
			var animated := node as AnimatedSprite2D
			animated.stop()
			animated.frame = state["frame"]
	_phase = Phase.FROZEN
	await get_tree().create_timer(FREEZE_DURATION, false, false, true).timeout
	if generation != _generation:
		return
	_begin_reverse(generation)


func cancel() -> void:
	_generation += 1
	if _tween != null and _tween.is_running():
		_tween.kill()
	_clear_temporary_visuals()
	_restore_process_modes()
	for mechanism in _mechanisms:
		if is_instance_valid(mechanism) and mechanism.has_method("finish_rewind"):
			mechanism.call("finish_rewind")
	_frozen.clear()
	_native_rewind_mechanisms.clear()
	_phase = Phase.IDLE


func _process(_delta: float) -> void:
	if _phase != Phase.FROZEN:
		return
	for state in _frozen.values():
		var node = state.get("node")
		if not is_instance_valid(node):
			continue
		if node is Node2D:
			var visual := node as Node2D
			visual.position = state["position"]
			visual.rotation = state["rotation"]
			visual.scale = state["scale"]
			visual.modulate = state["modulate"]
			visual.visible = state["visible"]
		if node is Sprite2D:
			var sprite := node as Sprite2D
			sprite.texture = state["texture"]
			sprite.frame = state["frame"]
		if node is AnimatedSprite2D:
			(node as AnimatedSprite2D).frame = state["frame"]


func _capture_initial() -> void:
	if not is_instance_valid(_level):
		return
	_mechanisms.clear()
	for mechanism in get_tree().get_nodes_in_group("level_resettable"):
		if _level.is_ancestor_of(mechanism):
			_mechanisms.append(mechanism)
	_initial = _snapshot_all()


func _snapshot_all() -> Dictionary:
	var snapshots: Dictionary = {}
	for mechanism in _mechanisms:
		if is_instance_valid(mechanism):
			_capture_tree(mechanism, snapshots)
	return snapshots


func _capture_tree(node: Node, snapshots: Dictionary) -> void:
	var path := String(_level.get_path_to(node))
	snapshots[path] = _snapshot(node)
	for child in node.get_children():
		_capture_tree(child, snapshots)


func _snapshot(node: Node) -> Dictionary:
	var state: Dictionary = {"node": node, "mode": node.process_mode}
	if node is Node2D:
		var visual := node as Node2D
		state["position"] = visual.position
		state["rotation"] = visual.rotation
		state["scale"] = visual.scale
		state["modulate"] = visual.modulate
		state["visible"] = visual.visible
	if node is Sprite2D:
		var sprite := node as Sprite2D
		state["texture"] = sprite.texture
		state["frame"] = sprite.frame
		state["hframes"] = sprite.hframes
		state["vframes"] = sprite.vframes
		state["centered"] = sprite.centered
		state["offset"] = sprite.offset
		state["region_enabled"] = sprite.region_enabled
		state["region_rect"] = sprite.region_rect
		state["texture_filter"] = sprite.texture_filter
	if node is AnimatedSprite2D:
		var sprite := node as AnimatedSprite2D
		state["frame"] = sprite.frame
		state["animation"] = sprite.animation
	if node is CollisionShape2D:
		state["disabled"] = (node as CollisionShape2D).disabled
	if node is Area2D:
		state["monitoring"] = (node as Area2D).monitoring
		state["monitorable"] = (node as Area2D).monitorable
	return state


func _begin_reverse(generation: int) -> void:
	_phase = Phase.REWINDING
	_native_rewind_mechanisms.clear()
	for mechanism in _mechanisms:
		if not is_instance_valid(mechanism) or not mechanism.has_method("rewind_to_initial"):
			continue
		_native_rewind_mechanisms.append(mechanism)
		_restore_process_mode_tree(mechanism)
		mechanism.call("rewind_to_initial")
	_tween = create_tween().set_parallel(true)
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for path in _frozen:
		var state: Dictionary = _frozen[path]
		var node = state.get("node")
		if not is_instance_valid(node):
			continue
		if _has_native_rewind_ancestor(node):
			continue
		if _initial.has(path):
			_animate_to_initial(node, state, _initial[path])
		else:
			_animate_extra_node(node)
	for path in _initial:
		if _frozen.has(path):
			continue
		var state: Dictionary = _initial[path]
		var initial_node = state.get("node")
		if is_instance_valid(initial_node):
			if _has_native_rewind_ancestor(initial_node):
				continue
		# El original puede haberse liberado desde la captura inicial, por
		# ejemplo cuando la palanca desactiva y reconstruye los rayos.
		# La presencia de "texture" identifica el snapshot de Sprite2D sin
		# consultar el tipo de una instancia ya liberada.
		if state.has("texture"):
			var parent := _level.get_node_or_null(NodePath(String(path).get_base_dir())) as Node2D
			if parent != null:
				var copy := _make_sprite_copy(state, parent)
				copy.modulate.a = 0.0
				_tween.tween_property(copy, "modulate", state["modulate"], REWIND_DURATION)
	_tween.tween_interval(REWIND_DURATION)
	await _tween.finished
	if generation != _generation:
		return
	_finish_reverse()


func _animate_to_initial(node: Node, current: Dictionary, target: Dictionary) -> void:
	if node is Node2D:
		var visual := node as Node2D
		_tween.tween_property(visual, "position", target["position"], REWIND_DURATION)
		_tween.tween_property(visual, "rotation", target["rotation"], REWIND_DURATION)
		_tween.tween_property(visual, "scale", target["scale"], REWIND_DURATION)
		if not current["visible"] and target["visible"]:
			visual.visible = true
			var faded: Color = visual.modulate
			faded.a = 0.0
			visual.modulate = faded
		var target_modulate: Color = target["modulate"]
		if not target["visible"] or node is Sprite2D and current["texture"] != target["texture"]:
			target_modulate.a = 0.0
		_tween.tween_property(visual, "modulate", target_modulate, REWIND_DURATION)
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if current["texture"] != target["texture"]:
			var parent := sprite.get_parent() as Node2D
			if parent != null:
				var copy := _make_sprite_copy(target, parent)
				copy.modulate.a = 0.0
				_tween.tween_property(copy, "modulate", target["modulate"], REWIND_DURATION)
		_tween.tween_method(Callable(self, "_set_frame_value").bind(sprite), float(sprite.frame), float(target["frame"]), REWIND_DURATION)
	elif node is AnimatedSprite2D:
		var animated := node as AnimatedSprite2D
		animated.stop()
		_tween.tween_method(Callable(self, "_set_frame_value").bind(animated), float(animated.frame), float(target["frame"]), REWIND_DURATION)


func _animate_extra_node(node: Node) -> void:
	if node is Node2D:
		var visual := node as Node2D
		_tween.tween_property(visual, "position", Vector2.ZERO, REWIND_DURATION)
		_tween.tween_property(visual, "scale", Vector2.ZERO, REWIND_DURATION)
		_tween.tween_property(visual, "modulate:a", 0.0, REWIND_DURATION)


func _set_frame_value(value: float, node: Node) -> void:
	if not is_instance_valid(node):
		return
	var frame := roundi(value)
	if node is Sprite2D:
		var sprite := node as Sprite2D
		if sprite.get_parent().has_method("rewind_set_frame"):
			sprite.get_parent().call("rewind_set_frame", frame)
		else:
			sprite.frame = frame
	elif node is AnimatedSprite2D:
		(node as AnimatedSprite2D).frame = frame


func _make_sprite_copy(state: Dictionary, parent: Node2D) -> Sprite2D:
	var copy := Sprite2D.new()
	copy.texture = state["texture"]
	copy.hframes = state["hframes"]
	copy.vframes = state["vframes"]
	copy.frame = state["frame"]
	copy.centered = state["centered"]
	copy.offset = state["offset"]
	copy.region_enabled = state["region_enabled"]
	copy.region_rect = state["region_rect"]
	copy.texture_filter = state["texture_filter"]
	copy.position = state["position"]
	copy.rotation = state["rotation"]
	copy.scale = state["scale"]
	copy.visible = state["visible"]
	copy.modulate = state["modulate"]
	parent.add_child(copy)
	_temporary_visuals.append(copy)
	return copy


func _finish_reverse() -> void:
	_phase = Phase.IDLE
	for mechanism in _mechanisms:
		if is_instance_valid(mechanism) and mechanism.has_method("reset_state"):
			mechanism.call("reset_state")
	for path in _initial:
		var node := _level.get_node_or_null(NodePath(path))
		if is_instance_valid(node):
			_restore_initial_node(node, _initial[path])
	_clear_temporary_visuals()
	_restore_process_modes()
	for mechanism in _mechanisms:
		if is_instance_valid(mechanism) and mechanism.has_method("finish_rewind"):
			mechanism.call("finish_rewind")
	_frozen.clear()
	_native_rewind_mechanisms.clear()
	rewind_finished.emit()


func _has_native_rewind_ancestor(node: Node) -> bool:
	for mechanism in _native_rewind_mechanisms:
		if mechanism == node or mechanism.is_ancestor_of(node):
			return true
	return false


func _restore_process_mode_tree(node: Node) -> void:
	var saved_state: Dictionary = _saved_process_modes.get(node.get_instance_id(), {})
	if not saved_state.is_empty():
		node.process_mode = saved_state["mode"]
	for child in node.get_children():
		_restore_process_mode_tree(child)


func _restore_initial_node(node: Node, state: Dictionary) -> void:
	if node is Node2D:
		var visual := node as Node2D
		visual.position = state["position"]
		visual.rotation = state["rotation"]
		visual.scale = state["scale"]
		visual.modulate = state["modulate"]
		visual.visible = state["visible"]
	if node is Sprite2D:
		var sprite := node as Sprite2D
		sprite.texture = state["texture"]
		sprite.frame = state["frame"]
	if node is AnimatedSprite2D:
		var animated := node as AnimatedSprite2D
		animated.stop()
		animated.animation = state["animation"]
		animated.frame = state["frame"]
	if node is CollisionShape2D:
		(node as CollisionShape2D).set_deferred("disabled", state["disabled"])
	if node is Area2D:
		(node as Area2D).set_deferred("monitoring", state["monitoring"])
		(node as Area2D).set_deferred("monitorable", state["monitorable"])


func _clear_temporary_visuals() -> void:
	for visual in _temporary_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	_temporary_visuals.clear()


func _restore_process_modes() -> void:
	for state in _saved_process_modes.values():
		var node = state.get("node")
		if is_instance_valid(node):
			node.process_mode = state["mode"]
	_saved_process_modes.clear()
