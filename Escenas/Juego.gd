extends Node

const CATALOG = preload("res://Escenas/UI/level_catalog.gd")
const AUDIO = preload("res://Escenas/UI/audio_preferences.gd")
const MENU_MUSIC = preload("res://Assets/Sonidos/test/musicaMenu.mp3")

enum Screen { MAIN, SELECTOR, GAME, PAUSE, TRANSITION, END }

@export var transition_duration: float = 0.8

@onready var level_container: Node2D = $NivelActual
@onready var main_menu = $UI/MainMenu
@onready var selector = $UI/LevelSelector
@onready var pause_menu = $UI/PauseMenu
@onready var end_screen = $UI/EndScreen
@onready var transition_ui: Control = $UI/TransitionUI
@onready var transition_label: Label = $UI/TransitionUI/Label
@onready var hud: Control = $UI/HUD

var _current_level: Node2D
var _current_index: int = -1
var _screen: Screen = Screen.MAIN
var _selector_origin: Screen = Screen.MAIN
var _navigation_generation: int = 0
var _menu_music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_shell")
	AUDIO.restore()
	_menu_music = AudioStreamPlayer.new()
	_menu_music.name = "MusicaMenu"
	var menu_stream := MENU_MUSIC.duplicate() as AudioStreamMP3
	menu_stream.loop = true
	_menu_music.stream = menu_stream
	_menu_music.volume_db = -12.0
	_menu_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_music)
	main_menu.start_requested.connect(start_game)
	main_menu.levels_requested.connect(open_level_selector)
	main_menu.quit_requested.connect(_quit_game)
	selector.level_selected.connect(_select_level)
	selector.back_requested.connect(_selector_back)
	pause_menu.continue_requested.connect(_resume_game)
	pause_menu.selector_requested.connect(open_level_selector)
	pause_menu.restart_requested.connect(_restart_level)
	end_screen.menu_requested.connect(return_to_menu)
	end_screen.replay_requested.connect(start_game)
	$UI/HUD/PauseButton.pressed.connect(_pause_game)
	_show_screen(Screen.MAIN)
	if get_tree().has_meta("game_completed"):
		get_tree().remove_meta("game_completed")
		_finish_game()
	elif get_tree().has_meta("open_level_selector"):
		get_tree().remove_meta("open_level_selector")
		open_level_selector()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		match _screen:
			Screen.GAME:
				# TAB abre un menu propio que tambien pausa el juego.
				if get_tree().paused:
					return
				_pause_game()
			Screen.PAUSE:
				_resume_game()
			Screen.SELECTOR:
				_selector_back()
			Screen.END:
				return_to_menu()
			_:
				return
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_BACKSPACE and _screen == Screen.GAME and not get_tree().paused:
		_restart_level()
		get_viewport().set_input_as_handled()


func start_game() -> void:
	_load_level(0)


func open_level_selector() -> void:
	_selector_origin = Screen.PAUSE if _screen == Screen.PAUSE else Screen.MAIN
	_show_screen(Screen.SELECTOR)
	get_tree().paused = is_instance_valid(_current_level)


func return_to_menu() -> void:
	_navigation_generation += 1
	get_tree().paused = false
	_clear_current_level()
	_show_screen(Screen.MAIN)


func _select_level(entry_id: String) -> void:
	var index: int = CATALOG.index_of(entry_id)
	if CATALOG.is_available(index):
		_load_level(index)


func _selector_back() -> void:
	if _selector_origin == Screen.PAUSE and is_instance_valid(_current_level):
		_show_screen(Screen.PAUSE)
		get_tree().paused = true
	else:
		return_to_menu()


func _load_level(index: int) -> void:
	if not CATALOG.is_available(index):
		get_tree().paused = false
		_clear_current_level()
		_selector_origin = Screen.MAIN
		_show_screen(Screen.SELECTOR)
		return
	_navigation_generation += 1
	get_tree().paused = false
	_clear_current_level()
	_current_index = index
	var entry: Dictionary = CATALOG.ENTRIES[index]
	var packed := load(entry["scene"]) as PackedScene
	if packed == null:
		push_error("No se pudo cargar %s" % entry["scene"])
		return_to_menu()
		return
	_current_level = packed.instantiate() as Node2D
	level_container.add_child(_current_level)
	_current_level.level_completed.connect(_on_level_completed)
	_current_level.set_active(true)
	pause_menu.set_level_caption(entry["title"])
	$UI/HUD/LevelName.text = entry["id"]
	_show_screen(Screen.GAME)


func _on_level_completed() -> void:
	if _screen != Screen.GAME:
		return
	var finished_game: bool = CATALOG.is_final_level(_current_index)
	_show_screen(Screen.TRANSITION)
	transition_label.text = "%s completado" % CATALOG.ENTRIES[_current_index]["title"]
	var generation := _navigation_generation
	await get_tree().create_timer(transition_duration, true).timeout
	if generation == _navigation_generation:
		if finished_game:
			_finish_game()
		else:
			_load_level(_current_index + 1)


func _finish_game() -> void:
	_navigation_generation += 1
	get_tree().paused = false
	_clear_current_level()
	_show_screen(Screen.END)


func _restart_level() -> void:
	if not is_instance_valid(_current_level):
		return
	_resume_game()
	_current_level.reset_level()


func _pause_game() -> void:
	if _screen != Screen.GAME or not is_instance_valid(_current_level):
		return
	_close_form_menu()
	_show_screen(Screen.PAUSE)
	get_tree().paused = true


func _resume_game() -> void:
	if not is_instance_valid(_current_level):
		return
	_show_screen(Screen.GAME)
	get_tree().paused = false


func _show_screen(screen: Screen) -> void:
	if screen == Screen.GAME or screen == Screen.TRANSITION:
		var focus_owner := get_viewport().gui_get_focus_owner()
		if is_instance_valid(focus_owner):
			focus_owner.release_focus()
	_screen = screen
	if screen == Screen.MAIN or screen == Screen.SELECTOR or screen == Screen.END:
		if not _menu_music.playing:
			_menu_music.play()
	else:
		_menu_music.stop()
	main_menu.visible = screen == Screen.MAIN
	selector.visible = screen == Screen.SELECTOR
	pause_menu.visible = screen == Screen.PAUSE
	end_screen.visible = screen == Screen.END
	transition_ui.visible = screen == Screen.TRANSITION
	hud.visible = screen == Screen.GAME
	if screen == Screen.SELECTOR:
		selector.get_node("Design/Entries/T1").grab_focus.call_deferred()
	elif screen == Screen.MAIN:
		main_menu.get_node("Design/Options/StartButton").grab_focus.call_deferred()
	elif screen == Screen.PAUSE:
		pause_menu.get_node("Design/Options/ContinueButton").grab_focus.call_deferred()
	elif screen == Screen.END:
		end_screen.present()


func _close_form_menu() -> void:
	if not is_instance_valid(_current_level):
		return
	var form_menu := _current_level.get_node_or_null("Jugador/FormMenu")
	if is_instance_valid(form_menu) and form_menu.visible:
		form_menu.close()


func _clear_current_level() -> void:
	_close_form_menu()
	if is_instance_valid(_current_level):
		_current_level.set_active(false)
		level_container.remove_child(_current_level)
		_current_level.queue_free()
	_current_level = null
	_current_index = -1


func _quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
