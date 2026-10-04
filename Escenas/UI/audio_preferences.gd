extends RefCounted

const SETTINGS_PATH := "user://interface.cfg"


static func restore() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		AudioServer.set_bus_mute(0, bool(settings.get_value("audio", "muted", false)))


static func is_muted() -> bool:
	return AudioServer.is_bus_mute(0)


static func toggle() -> bool:
	var muted := not is_muted()
	AudioServer.set_bus_mute(0, muted)
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("audio", "muted", muted)
	settings.save(SETTINGS_PATH)
	return muted
