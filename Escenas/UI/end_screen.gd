@tool
extends "res://Escenas/UI/menu_screen.gd"

signal menu_requested
signal replay_requested

const STONE: Texture2D = preload("res://Assets/UI/Menu/piedra_alargada.png")
const STONE_REGION := Rect2(40.0 / 2172.0, 176.0 / 724.0, 2092.0 / 2172.0, 376.0 / 724.0)

var _entrance: Tween


func _ready() -> void:
	super._ready()
	_style_title()
	if Engine.is_editor_hint():
		return
	var particle_image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	particle_image.fill(Color.WHITE)
	$Design/AmbientMotes.texture = ImageTexture.create_from_image(particle_image)
	$Design/Content/Actions/MenuButton.pressed.connect(func(): menu_requested.emit())
	$Design/Content/Actions/ReplayButton.pressed.connect(func(): replay_requested.emit())
	visibility_changed.connect(_on_visibility_changed)
	if visible:
		present.call_deferred()


func _style_title() -> void:
	var style := StyleBoxTexture.new()
	style.texture = STONE
	var texture_size := STONE.get_size()
	style.region_rect = Rect2(STONE_REGION.position * texture_size, STONE_REGION.size * texture_size)
	style.modulate_color = Color(0.82, 0.96, 0.94)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, style.region_rect.size.y * 0.2)
	$Design/Content/StoneTitle.add_theme_stylebox_override("panel", style)


func present() -> void:
	if _entrance != null and _entrance.is_running():
		_entrance.kill()
	modulate.a = 0.0
	$Design/Content.position = Vector2(0, 18)
	$Design/AmbientMotes.emitting = true
	_entrance = create_tween().set_parallel(true)
	_entrance.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance.tween_property(self, "modulate:a", 1.0, 0.7)
	_entrance.tween_property($Design/Content, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	$Design/Content/Actions/MenuButton.grab_focus.call_deferred()


func _on_visibility_changed() -> void:
	if not visible:
		$Design/AmbientMotes.emitting = false
		if _entrance != null and _entrance.is_running():
			_entrance.kill()
