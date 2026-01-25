# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name TableTitleButton extends Button
## Controls the resizing of the TitleButton


## Emitted when the size is changed
signal size_changed(new_size: int)

## Emitted when this Column is right clicked
signal right_clicked()


## Previous mouse X position
var _previous_pos: int


## Disable the process at startup
func _ready() -> void:
	set_process(false)


## Calculates the mouse distance from the button, and adusts the intensity
func _process(delta: float) -> void:
	var current_size: int = get_custom_minimum_size().x
	var new_size: int = current_size + (get_global_mouse_position().x - _previous_pos)
	
	if new_size == current_size:
		return
	
	set_min_width(new_size)
	_previous_pos = get_global_mouse_position().x


## Sets the min width
func set_min_width(p_width: int) -> void:
	if p_width <= get_minimum_size().x:
		return
	
	set_custom_minimum_size(Vector2(p_width, 0))
	size_changed.emit(p_width)


## Called when the button is pressed
func _on_button_down() -> void: 
	_previous_pos = get_global_mouse_position().x
	set_process(true)


## Called when the button is released
func _on_button_up() -> void: 
	set_process(false)


## Called for each GUI input
func _gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.is_pressed():
		p_event = p_event as InputEventMouseButton
		
		match p_event.get_button_index():
			MOUSE_BUTTON_RIGHT:
				right_clicked.emit()
