# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name FunctionPlaybackControls extends UIComponent
## Playback control for Function


## The PlayPause button
@export var play_pause_button: Button

## The Stop Button
@export var stop_button: Button

## The IntensityButton
@export var intensity_button: IntensityButton


## The current function
var _function: Function

## SignalGroup for Function
var _signal_connection: SignalGroup = SignalGroup.new([
	_on_active_state_changed,
	_on_transport_state_changed,
	_on_delete_requested,
])


## init
func _init() -> void:
	super._init()
	
	_set_class_name("FunctionPlaybackControls")


## Sets the Function
func set_function(p_function: Function) -> void:
	_signal_connection.disconnect_object(_function)
	_function = p_function
	
	_signal_connection.connect_object(_function)
	intensity_button.set_function(_function)
	
	var is_valid: bool = is_instance_valid(_function)
	
	play_pause_button.set_disabled(not is_valid)
	stop_button.set_disabled(not is_valid)
	play_pause_button.set_pressed_no_signal(false)
	
	if not is_valid:
		return
	
	play_pause_button.set_pressed_no_signal(_function.get_transport_state() != Function.TransportState.PAUSED)
	stop_button.set_disabled(_function.get_active_state() == Function.ActiveState.DISABLED)


## Gets the Function
func get_function() -> Function:
	return _function


## Called when the ActiveState is changed on the Function
func _on_active_state_changed(p_active_state: Function.ActiveState) -> void:
	stop_button.set_disabled(p_active_state == Function.ActiveState.DISABLED)


## Called when the TransportState is changed on the Function
func _on_transport_state_changed(p_transport_state: Function.TransportState) -> void:
	play_pause_button.set_pressed_no_signal(p_transport_state != Function.TransportState.PAUSED)


## Called when the Function is to be deleted
func _on_delete_requested() -> void:
	set_function(null)


## Called when the play pause button is toggled
func _on_play_pause_toggled(p_toggled_on: bool) -> void:
	if p_toggled_on:
		_function.play()
	else:
		_function.pause()


## Called when the stop button is pressed
func _on_stop_pressed() -> void:
	_function.off()
