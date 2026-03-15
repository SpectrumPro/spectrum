# Copyright (c) 2024 Liam Sherwin, All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.

class_name InputTriggerKey extends InputTrigger
## Combines inputs and control things


## Emitted when the keycode changes
signal keycode_changed(keycode: Key)

## Emitted when the shift pressed state changes
signal shift_pressed_state_changed(shift_pressed: bool)

## Emitted when the control pressed state changes
signal control_pressed_state_changed(control_pressed: bool)

## Emitted when the alt pressed state changes
signal alt_pressed_state_changed(alt_pressed: bool)

## Emitted when the meta pressed state changes
signal meta_pressed_state_changed(meta_pressed: bool)


## The InputEventKey used
var _input_event: InputEventKey = InputEventKey.new()

## Keycode
var _keycode: Key = KEY_NONE

## Shift state
var _shift_pressed: bool = false

## Control state
var _control_pressed: bool = false

## Alt state
var _alt_pressed: bool = false

## Meta state
var _meta_pressed: bool = false


## Ready
func _component_ready() -> void:
	set_name("InputTriggerKey")
	_set_class_name("InputTriggerKey")
	
	_settings.register_setting("InputTriggerKey", Data.Type.INPUTEVENT, set_input_event, get_input_event)
	_settings.register_setting("KeyCode", Data.Type.INT, set_keycode, get_keycode, [keycode_changed]).set_min_max(0, 0x7FFFFFFF)
	_settings.register_setting("Shift", Data.Type.BOOL, set_shift_pressed, get_shift_pressed, [shift_pressed_state_changed])
	_settings.register_setting("Control", Data.Type.BOOL, set_control_pressed, get_control_pressed, [control_pressed_state_changed])
	_settings.register_setting("Alt", Data.Type.BOOL, set_alt_pressed, get_alt_pressed, [alt_pressed_state_changed])
	_settings.register_setting("Meta", Data.Type.BOOL, set_meta_pressed, get_meta_pressed, [meta_pressed_state_changed])



## Sets the input event
func set_input_event(p_input_event: InputEventKey) -> void:
	set_keycode(p_input_event.keycode)
	set_shift_pressed(p_input_event.shift_pressed)
	set_control_pressed(p_input_event.ctrl_pressed)
	set_alt_pressed(p_input_event.alt_pressed)
	set_meta_pressed(p_input_event.meta_pressed)


## Sets the keycode
func set_keycode(p_keycode: Key) -> bool:
	if p_keycode == _keycode:
		return false

	_keycode = p_keycode
	_input_event.keycode = _keycode
	keycode_changed.emit(_keycode)
	return true


## Sets the shift pressed state
func set_shift_pressed(p_shift_pressed: bool) -> bool:
	if p_shift_pressed == _shift_pressed:
		return false

	_shift_pressed = p_shift_pressed
	_input_event.shift_pressed = _shift_pressed
	shift_pressed_state_changed.emit(_shift_pressed)
	return true


## Sets the control pressed state
func set_control_pressed(p_control_pressed: bool) -> bool:
	if p_control_pressed == _control_pressed:
		return false

	_control_pressed = p_control_pressed
	_input_event.ctrl_pressed = _control_pressed
	control_pressed_state_changed.emit(_control_pressed)
	return true


## Sets the alt pressed state
func set_alt_pressed(p_alt_pressed: bool) -> bool:
	if p_alt_pressed == _alt_pressed:
		return false

	_alt_pressed = p_alt_pressed
	_input_event.alt_pressed = _alt_pressed
	alt_pressed_state_changed.emit(_alt_pressed)
	return true


## Sets the meta pressed state
func set_meta_pressed(p_meta_pressed: bool) -> bool:
	if p_meta_pressed == _meta_pressed:
		return false

	_meta_pressed = p_meta_pressed
	_input_event.meta_pressed = _meta_pressed
	meta_pressed_state_changed.emit(_meta_pressed)
	return true


## Gets the input event
func get_input_event() -> InputEventKey:
	return _input_event


## Gets the keycode
func get_keycode() -> Key:
	return _keycode


## Gets the shift pressed state
func get_shift_pressed() -> bool:
	return _shift_pressed


## Gets the control pressed state
func get_control_pressed() -> bool:
	return _control_pressed


## Gets the alt pressed state
func get_alt_pressed() -> bool:
	return _alt_pressed


## Gets the meta pressed state
func get_meta_pressed() -> bool:
	return _meta_pressed


## Saves this InputTriggerKey to a dictonary
func _save() -> Dictionary:
	return {
		"keycode": _keycode,
		"shift_pressed": _shift_pressed,
		"control_pressed": _control_pressed,
		"alt_pressed": _alt_pressed,
		"meta_pressed": _meta_pressed
	}


## Loads this InputTriggerKey from a dictionary
func _load(saved_data: Dictionary) -> void:
	set_keycode(type_convert(saved_data.get("keycode", _keycode), TYPE_INT))
	set_shift_pressed(type_convert(saved_data.get("shift_pressed", _shift_pressed), TYPE_BOOL))
	set_control_pressed(type_convert(saved_data.get("control_pressed", _control_pressed), TYPE_BOOL))
	set_alt_pressed(type_convert(saved_data.get("alt_pressed", _alt_pressed), TYPE_BOOL))
	set_meta_pressed(type_convert(saved_data.get("meta_pressed", _meta_pressed), TYPE_BOOL))
