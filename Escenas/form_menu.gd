extends CanvasLayer

signal form_selected(form_id: int)
signal menu_closed

const ENTER_KEY_SCENE: PackedScene = preload("res://Escenas/objetos/indicaciones/tecla_enter.tscn")
const E_KEY_SCENE: PackedScene = preload("res://Escenas/objetos/indicaciones/tecla_e.tscn")
const FORM_IDS: Array[int] = [FormCatalog.METAL, FormCatalog.FUEGO, FormCatalog.ELECTRICA]

@onready var metal_button: Button = $Panel/MetalButton
@onready var fire_button: Button = $Panel/FireButton
@onready var electric_button: Button = $Panel/ElectricButton

var _buttons: Array[Button] = []
var _available_forms: Array = []
var _enter_key: Node2D
var _e_key: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	metal_button.pressed.connect(_on_metal_pressed)
	fire_button.pressed.connect(_on_fire_pressed)
	electric_button.pressed.connect(_on_electric_pressed)
	_buttons.assign([metal_button, fire_button, electric_button])
	_enter_key = ENTER_KEY_SCENE.instantiate()
	_e_key = E_KEY_SCENE.instantiate()
	for key_hint in [_enter_key, _e_key]:
		key_hint.scale = Vector2.ONE
		key_hint.visible = false
		add_child(key_hint)
	for index in _buttons.size():
		var button := _buttons[index]
		button.focus_neighbor_top = button.get_path_to(_buttons[(index + 2) % 3])
		button.focus_neighbor_bottom = button.get_path_to(_buttons[(index + 1) % 3])
		button.focus_entered.connect(_update_selection_hints)
		button.mouse_entered.connect(button.grab_focus)
		button.resized.connect(_update_selection_hints)
	$Panel.item_rect_changed.connect(func(): _update_selection_hints.call_deferred())


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if visible:
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_E:
			var selected_index := _buttons.find(get_viewport().gui_get_focus_owner())
			if selected_index >= 0:
				_select_form(FORM_IDS[selected_index])
			get_viewport().set_input_as_handled()
		return
	if event.keycode != KEY_TAB or get_tree().paused:
		return
	var player = get_parent()
	if player.has_method("can_open_form_menu") and player.can_open_form_menu():
		open(player.get_allowed_transformations())
		get_viewport().set_input_as_handled()


func open(available_forms: Array) -> void:
	if visible or get_tree().paused:
		return
	_available_forms = available_forms.duplicate()
	var required_form: int = get_parent().get_required_transformation()
	_update_form_styles(required_form)
	$Panel/Hint.text = "Usá la forma marcada en amarillo\nTab o Escape para cancelar" if required_form >= 0 else "Tab o Escape para cancelar"
	visible = true
	get_tree().paused = true
	var initial_index := FORM_IDS.find(required_form)
	_buttons[initial_index if initial_index >= 0 else 0].grab_focus()
	_update_selection_hints.call_deferred()


func _update_form_styles(required_form: int) -> void:
	for index in _buttons.size():
		var button := _buttons[index]
		var permitted := _available_forms.has(FORM_IDS[index])
		var required := FORM_IDS[index] == required_form
		# Se bloquea la confirmación, conservando el foco y la navegación.
		button.disabled = false
		button.visible = true
		button.modulate = Color.WHITE if permitted else Color(0.55, 0.55, 0.55, 1.0)
		for style_name in ["normal", "hover", "pressed", "focus"]:
			button.remove_theme_stylebox_override(style_name)
		for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(color_name, Color("ffd34f") if required else Color("d2e0ec"))
		if required:
			var stone := StyleBoxFlat.new()
			stone.bg_color = Color("373223")
			stone.border_color = Color("ffd34f")
			stone.set_border_width_all(3)
			stone.set_corner_radius_all(5)
			for style_name in ["normal", "hover", "pressed"]:
				button.add_theme_stylebox_override(style_name, stone)
			var focus_border := stone.duplicate() as StyleBoxFlat
			focus_border.draw_center = false
			button.add_theme_stylebox_override("focus", focus_border)


func _update_selection_hints() -> void:
	if not is_instance_valid(_enter_key) or not is_instance_valid(_e_key):
		return
	var selected := get_viewport().gui_get_focus_owner() as Button
	var show_hints := visible and _buttons.has(selected)
	_enter_key.visible = show_hints
	_e_key.visible = show_hints
	if not show_hints:
		return
	var bounds := selected.get_global_rect()
	var center_y := bounds.get_center().y
	_enter_key.position = Vector2(bounds.position.x - 36.0, center_y)
	_e_key.position = Vector2(bounds.end.x + 36.0, center_y)


func _select_form(form_id: int) -> void:
	if visible and _available_forms.has(form_id):
		form_selected.emit(form_id)


func close() -> void:
	if not visible:
		return
	visible = false
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner):
		focus_owner.release_focus()
	get_tree().paused = false
	menu_closed.emit()


func _exit_tree() -> void:
	if visible:
		get_tree().paused = false


func _on_metal_pressed() -> void:
	_select_form(FormCatalog.METAL)


func _on_fire_pressed() -> void:
	_select_form(FormCatalog.FUEGO)


func _on_electric_pressed() -> void:
	_select_form(FormCatalog.ELECTRICA)
