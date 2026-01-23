# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name IntensityButton extends Button
## Button to change the intensity of a Function


## The max distance away from the center point
@export var max_distance: int = 800

## Multiplier of the value
@export var multiplier: float = 0.2

## The ProgressBar
@export var progress_bar: ProgressBar

## The TextureRect icon
@export var button_icon: TextureRect


## The function to control
var _function: Function = null

## SignalGroup for Function
var _signal_connections: SignalGroup = SignalGroup.new([
	_on_intensity_changed,
	_on_delete_requested,
])


## Disable the process at startup
func _ready() -> void: 
	set_process(false)


## Sets the function
func set_function(p_function: Function) -> void:
	_signal_connections.disconnect_object(_function)
	_function = p_function
	_signal_connections.connect_object(_function)
	
	var is_valid: bool = is_instance_valid(_function)
	set_disabled(not is_valid)
	
	if is_valid:
		progress_bar.set_value_no_signal(_function.get_intensity())
	else:
		progress_bar.set_value_no_signal(0)


## Calculates the mouse distance from the button, and adusts the intensity
func _process(delta: float) -> void:
	if is_instance_valid(_function):
		var global_mouse: Vector2 = get_global_mouse_position()
		var center_position: Vector2 = global_position + (size / 2) 
		var change: float = remap(center_position.x - global_mouse.x, -max_distance, max_distance, -1, 1) * multiplier
		
		_function.set_intensity(clamp(_function.get_intensity() - change, 0, 1))


## Sets the enabled state of this button
func set_enabled(p_state: bool) -> void:
	set_process(p_state)
	button_icon.set_visible(not p_state)
	progress_bar.set_show_percentage(p_state)



## Called when the intensity changes on the function
func _on_intensity_changed(p_intensity: float) -> void:
	progress_bar.set_value_no_signal(p_intensity)


## Called when the function is to be deleted
func _on_delete_requested() -> void:
	set_function(null)


## Called when the button is pressed
func _on_button_down() -> void: 
	set_enabled(true)


## Called when the button is released
func _on_button_up() -> void: 
	set_enabled(false)


## Called for each GUI input on the button
func _on_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.is_pressed():
		p_event = p_event as InputEventMouseButton
		 
		match p_event.get_button_index():
			MOUSE_BUTTON_RIGHT when is_instance_valid(_function):
				if _function.get_intensity() == 1:
					_function.blackout()
				else:
					_function.full()
