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


func open(available_forms: Array) -> void:
	metal_button.visible = available_forms.has(FormCatalog.METAL)
	fire_button.visible = available_forms.has(FormCatalog.FUEGO)
	electric_button.visible = available_forms.has(FormCatalog.ELECTRICA)
	visible = true
	if metal_button.visible:
		metal_button.grab_focus()
	elif fire_button.visible:
		fire_button.grab_focus()
	elif electric_button.visible:
		electric_button.grab_focus()


func close() -> void:
	visible = false
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner):
		focus_owner.release_focus()
	menu_closed.emit()


func _on_metal_pressed() -> void:
	form_selected.emit(FormCatalog.METAL)


func _on_fire_pressed() -> void:
	form_selected.emit(FormCatalog.FUEGO)


func _on_electric_pressed() -> void:
	form_selected.emit(FormCatalog.ELECTRICA)
