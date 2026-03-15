# Copyright (c) 2024 Liam Sherwin, All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.

class_name InputTriggerJoyKey extends InputTrigger
## Combines inputs and control things


## Emitted when the keycode changes
signal button_changed(button: JoyButton)


## The InputEventKey used
var _input_event: InputEventJoypadButton = InputEventJoypadButton.new()

## Button Index
var _button: JoyButton = JOY_BUTTON_INVALID


## Ready
func _component_ready() -> void:
	set_name("InputTriggerJoyKey")
	_set_class_name("InputTriggerJoyKey")
	
	_settings.register_setting("InputTriggerJoyKey", Data.Type.INPUTEVENT, set_input_event, get_input_event, [button_changed])
	_settings.register_setting("Button", Data.Type.INT, set_button, get_button, [button_changed]).set_min_max(0, 0x7FFFFFFF)


## Sets the input event
func set_input_event(p_input_event: InputEventJoypadButton) -> void:
	set_button(p_input_event.button_index)


## Sets the keycode
func set_button(p_button: JoyButton) -> bool:
	if p_button == _button:
		return false
	
	_button = p_button
	_input_event.button_index = _button
	
	button_changed.emit(_button)
	return true


## Gets the input event
func get_input_event() -> InputEventJoypadButton:
	return _input_event


## Gets the button
func get_button() -> JoyButton:
	return _button


## Saves this InputTriggerKey to a dictonary
func _save() -> Dictionary:
	return {
		"button": _button,
	}


## Loads this InputTriggerKey from a dictionary
func _load(saved_data: Dictionary) -> void:
	set_button(type_convert(saved_data.get("button", _button), TYPE_INT))
