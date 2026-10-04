extends RefCounted

const FINAL_LEVEL_ID: String = "5"

const ENTRIES: Array[Dictionary] = [
	{"id": "T1", "title": "Tutorial 1", "scene": "res://Escenas/niveles/Tutoriales/tutorial_01.tscn"},
	{"id": "T2", "title": "Tutorial 2", "scene": "res://Escenas/niveles/Tutoriales/tutorial_02.tscn"},
	{"id": "1", "title": "Nivel 1", "scene": "res://Escenas/niveles/Sala01/sala_01.tscn"},
	{"id": "2", "title": "Nivel 2", "scene": "res://Escenas/niveles/Sala02/sala_02.tscn"},
	{"id": "3", "title": "Nivel 3", "scene": "res://Escenas/niveles/Sala03/sala_03.tscn"},
	{"id": "4", "title": "Nivel 4", "scene": "res://Escenas/niveles/Sala04/sala_04.tscn"},
	{"id": "5", "title": "Nivel 5", "scene": "res://Escenas/niveles/Sala05/sala_05.tscn"},
	{"id": "6", "title": "Nivel 6", "scene": "res://Escenas/niveles/Sala06/nivel_06.tscn", "available": false},
	{"id": "7", "title": "Nivel 7", "scene": "res://Escenas/niveles/Sala07/nivel_07.tscn", "available": false},
	{"id": "8", "title": "Nivel 8", "scene": "res://Escenas/niveles/Sala08/nivel_08.tscn", "available": false},
	{"id": "9", "title": "Nivel 9", "scene": "res://Escenas/niveles/Sala09/nivel_09.tscn", "available": false},
	{"id": "10", "title": "Nivel 10", "scene": "res://Escenas/niveles/Sala10/nivel_10.tscn", "available": false},
]


static func index_of(entry_id: String) -> int:
	for index in ENTRIES.size():
		if ENTRIES[index]["id"] == entry_id:
			return index
	return -1


static func is_available(index: int) -> bool:
	return index >= 0 and index < ENTRIES.size() and bool(ENTRIES[index].get("available", true))


static func is_final_level(index: int) -> bool:
	return is_available(index) and ENTRIES[index]["id"] == FINAL_LEVEL_ID
