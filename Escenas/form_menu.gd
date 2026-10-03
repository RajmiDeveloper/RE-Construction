extends CanvasLayer

signal form_selected(form_id: int)
signal menu_closed

@onready var metal_button: Button = $Panel/MetalButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	metal_button.pressed.connect(_on_metal_pressed)


func open(available_forms: Array) -> void:
	metal_button.visible = available_forms.has(FormCatalog.METAL)
	visible = true
	if metal_button.visible:
		metal_button.grab_focus()


func close() -> void:
	visible = false
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner):
		focus_owner.release_focus()
	menu_closed.emit()


func _on_metal_pressed() -> void:
	form_selected.emit(FormCatalog.METAL)
