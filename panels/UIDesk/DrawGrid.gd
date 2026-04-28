# Copyright (c) 2025 Liam Sherwin, All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.

@tool
class_name DrawGrid extends Control
## Draws a grid of a specified size


## The color of the grid
@export var color: Color = Color.DIM_GRAY : set = set_color

## Whether or not to show the grid
@export var show_grid: bool = true : set = set_show_grid

## The grid size in px
@export var grid_size: Vector2 = Vector2(20, 20) : set = set_grid_size

## The line width in px
@export var line_width: float = 1 : set = set_line_width

## Sets the display mode of this grid
@export var grid_mode: DisplayMode = DisplayMode.GRID_MODE_LINE : set = set_grid_mode

## Sets the visability of the point
@export var show_point: bool = false : set = set_show_point


## Enum for 
enum DisplayMode {GRID_MODE_LINE, GRID_MODE_DOT, GRID_MODE_DOT_LINE}

## The size of the point
const PointSize: Vector2 = Vector2(10, 10)

## Animation speed of the point
const PointAnimationSpeed: float = 0.08


## The Point
var _point: Panel = Panel.new()

## Should the point be visible because the mouse is in frame
var _mouse_in_frame: bool = false

## Target pos for the point
var _point_target_position: Vector2


## Ready
func _ready() -> void:
	_point.add_theme_stylebox_override("panel", ThemeManager.StyleBoxes.GridPoint)
	_point.hide()
	
	_point.mouse_filter = Control.MOUSE_FILTER_PASS
	_point.size = PointSize
	
	add_child(_point)
	
	mouse_entered.connect(func ():
		if show_point:
			Interface.show_and_fade(_point)
		
		_mouse_in_frame = true
	)
	
	mouse_exited.connect(func ():
		Interface.fade_and_hide(_point)
		_mouse_in_frame = false
	)
	
	set_process(false)


## Process
func _process(delta: float) -> void:
	var speed: float = max(_point.position.distance_to(_point_target_position) / PointAnimationSpeed, 0.001)
	_point.position = _point.position.move_toward(_point_target_position, speed * delta)
	
	if _point.position.is_equal_approx(_point_target_position):
		set_process(false)


## Whether or not to show the grid
func set_show_grid(p_show_grid) -> void:
	show_grid = p_show_grid
	queue_redraw()


## Sets the grid size in px
func set_grid_size(p_grid_size: Vector2) -> void:
	grid_size = p_grid_size
	queue_redraw()


## Sets the color of the grid
func set_color(p_color: Color) -> void:
	color = p_color
	queue_redraw()


## Sets the line or dot size of the grid
func set_line_width(p_line_width: float) -> void:
	line_width = p_line_width
	queue_redraw()


## Sets whether or not to show dots instead of lines
func set_grid_mode(p_grid_mode) -> void:
	grid_mode = p_grid_mode
	queue_redraw()


## Sets the point show mode
func set_show_point(p_show_point: bool) -> void:
	show_point = p_show_point
	_point.visible = show_point if _mouse_in_frame else false


func _draw() -> void:
	if not show_grid:
		return
	
	if grid_mode == DisplayMode.GRID_MODE_DOT or grid_mode == DisplayMode.GRID_MODE_DOT_LINE:
		for x in range(0, size.x, grid_size.x):
			for y in range(0, size.y, grid_size.y):
				draw_circle(Vector2(x, y), line_width, color)
	
	if grid_mode == DisplayMode.GRID_MODE_LINE or grid_mode == DisplayMode.GRID_MODE_DOT_LINE:
		for x in range(0, size.x, grid_size.x):
			draw_line(Vector2(x, 0), Vector2(x, size.y), color, line_width)
		
		for y in range(0, size.y, grid_size.y):
			draw_line(Vector2(0, y), Vector2(size.x, y), color, line_width)


## Called for all GUI inputs
func _gui_input(event: InputEvent) -> void:
	if show_point and event is InputEventMouseMotion:
		_point_target_position = get_local_mouse_position().snapped(grid_size) - PointSize / 2
		
		if _point_target_position != _point.position:
			set_process(true)
