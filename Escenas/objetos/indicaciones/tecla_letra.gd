extends Node2D

@export_enum("A", "W", "D", "E") var letra: String = "A":
	set(value):
		letra = value
		queue_redraw()

const PIXEL_SIZE := 2.0
const COLOR_TECLA := Color("ddf6f5")
const GLYPHS := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
}


func _draw() -> void:
	var glyph: Array = GLYPHS.get(letra, GLYPHS["A"])
	var glyph_size := Vector2(glyph[0].length(), glyph.size()) * PIXEL_SIZE
	var origin := -glyph_size * 0.5
	for y in glyph.size():
		for x in glyph[y].length():
			if glyph[y][x] == "1":
				draw_rect(Rect2(origin + Vector2(x, y) * PIXEL_SIZE, Vector2.ONE * PIXEL_SIZE), COLOR_TECLA)
