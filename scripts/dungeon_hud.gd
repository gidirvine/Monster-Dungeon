extends Node2D

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 960, 36), Color("0d1219"))
	draw_line(Vector2(0, 35), Vector2(960, 35), Color("53616a"), 1.0)
	draw_string(font, Vector2(18, 24), "THE FORSAKEN DEPTHS  •  FLOOR 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e2d8b5"))
	draw_string(font, Vector2(386, 24), "VISION: 5  •  WASD / ARROWS: MOVE  •  R: NEW FLOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("8fa1a5"))
	draw_string(font, Vector2(838, 24), "HP 20 / 20", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("dc6960"))
