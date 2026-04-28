# Copyright (c) 2024 Liam Sherwin, All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.

class_name UIDataEditorGrid extends Control
## Grid for the data editor


## Grid Resolution
@export var resolution: Vector2i = Vector2i(11, 5)

## Grid color
@export var color: Color = Color.DIM_GRAY


## Draws the grid
func _draw() -> void:
	var res: Vector2i = resolution - Vector2i(1, 1)
	
	for index: int in range(0, res.y + 1):
		var y_pos: int = (size.y / res.y) * index
		draw_line(Vector2(0, y_pos), Vector2(size.x, y_pos), color, 0.5, true)
	
	for index: int in range(0, res.x + 1):
		var x_pos: int = (size.x / res.x) * index
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y), color, 0.5, true)
