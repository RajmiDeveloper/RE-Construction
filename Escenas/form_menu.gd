extends CanvasLayer

signal form_selected(form_id: int)
signal menu_closed

@onready var metal_button: Button = $Panel/MetalButton
@onready var fire_button: Button = $Panel/FireButton
@onready var electric_button: Button = $Panel/ElectricButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	metal_button.pressed.connect(_on_metal_pressed)
	fire_button.pressed.connect(_on_fire_pressed)
	electric_button.pressed.connect(_on_electric_pressed)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if visible:
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
		return
	if event.keycode != KEY_TAB or get_tree().paused:
		return
	var player = get_parent()
	if player.has_method("can_open_form_menu") and player.can_open_form_menu():
		open([FormCatalog.METAL, FormCatalog.FUEGO, FormCatalog.ELECTRICA])
		get_viewport().set_input_as_handled()


func open(available_forms: Array) -> void:
	if visible or get_tree().paused:
		return
	metal_button.visible = available_forms.has(FormCatalog.METAL)
	fire_button.visible = available_forms.has(FormCatalog.FUEGO)
	electric_button.visible = available_forms.has(FormCatalog.ELECTRICA)
	visible = true
	get_tree().paused = true
	if metal_button.visible:
		metal_button.grab_focus()
	elif fire_button.visible:
		fire_button.grab_focus()
	elif electric_button.visible:
		electric_button.grab_focus()


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
	form_selected.emit(FormCatalog.METAL)


func _on_fire_pressed() -> void:
	form_selected.emit(FormCatalog.FUEGO)


func _on_electric_pressed() -> void:
	form_selected.emit(FormCatalog.ELECTRICA)
