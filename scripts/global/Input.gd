# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SpectrumInputServer extends Node
## Custom input manager for Spectrum


## Called when an InputAction is added
signal input_action_added(action: InputAction)

## Called when an InputAction is removed
signal input_action_removed(action: InputAction)


## Midi Mappings based on the pitch value, {channel: {pitch: Mapping, ...}, ...}
var _midi_pitch_mappings: Dictionary = {}

## Midi Mappings based on the control number value, {channel: {control: Mapping, ...}, ...}
var _midi_controler_mappings: Dictionary = {}

## User defined actions
var _input_actions: RefMap = RefMap.new()

## Internal actions
var _internal_actions: Dictionary[String, Callable] = {
	"clear_programmer": Programmer.clear,
	"store_mode": _handle_store_mode_action,
	"ui_cancel": Interface.hide_all_popup_panels,
	"command_palette": Interface.toggle_popup_visable.bind(Interface.WindowPopup.COMMAND_PALETTE, self),
	"screenshot": Interface.take_screenshot,
}

## Allowed input events for shortcuts
var _allowed_events: Array[String] = [
	"InputEventKey",
	"InputEventJoypadButton",
]


## Blocklist for keycodes
var _keycode_block_list: Array[Key] = [
	KEY_SPACE,
	KEY_ENTER,
	KEY_ESCAPE,
]

## Blocklist for joy buttons
var _joy_button_block_list: Array[JoyButton] = [
	JOY_BUTTON_INVALID,
	JOY_BUTTON_BACK,
	JOY_BUTTON_GUIDE,
	JOY_BUTTON_START,
]

## All Action Triggers
var _action_triggers_types: Dictionary[String, Script] = {
	"ActionTriggerComponent": ActionTriggerComponent
}

## All Action Triggers
var _input_triggers_types: Dictionary[String, Script] = {
	"InputTriggerKey": InputTriggerKey,
	"InputTriggerJoyKey": InputTriggerJoyKey,
}


func _ready() -> void:
	OS.open_midi_inputs()
	Core.resetting.connect(_reset)


## Called for every InputEvent
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMIDI: 
		_handle_midi_input(event)
	
	for action: String in _internal_actions:
		if Input.is_action_just_released(action):
			_internal_actions[action].call()
	
	for input_action: InputAction in _input_actions.get_left():
		if event.is_action_pressed(input_action.uuid()):
			input_action.activate()
			
		elif event.is_action_released(input_action.uuid()):
			input_action.deactivate()


## Resets to a default state
func _reset() -> void:
	for action: InputAction in _input_actions.get_left():
		remove_input_action(action)


## Gets all current InputActions
func get_input_actions() -> Array:
	return _input_actions.get_left()


## Gets an InputAction by uuid
func get_input_action(p_uuid: String) -> InputAction:
	return _input_actions.right(p_uuid)


## Creates a new InputAction
func create_input_action() -> InputAction:
	var action: InputAction = InputAction.new()
	
	if add_input_action(action):
		return action
	else:
		return null


## Adds an InputAction
func add_input_action(p_action: InputAction, no_signal: bool = false) -> bool:
	if _input_actions.has_left(p_action):
		return false
	
	_input_actions.map(p_action, p_action.uuid())
	
	if not InputMap.has_action(p_action.uuid()):
		InputMap.add_action(p_action.uuid())
	
	if not no_signal:
		input_action_added.emit(p_action)
	
	return true


## Removes an InputAction
func remove_input_action(p_action: InputAction, no_signal: bool = false) -> bool:
	if not _input_actions.has_left(p_action):
		return false
	
	_input_actions.erase_left(p_action)
	
	if InputMap.has_action(p_action.uuid()):
		InputMap.erase_action(p_action.uuid())
	
	if not no_signal:
		input_action_removed.emit(p_action)
	
	return true


## Returns an array with the classname for all ActionTriggers
func get_action_trigger_types() -> Array[String]:
	return Array(_action_triggers_types.keys(), TYPE_STRING, "", null)


## Returns an array with the classname for all InputTriggers
func get_input_trigger_types() -> Array[String]:
	return Array(_input_triggers_types.keys(), TYPE_STRING, "", null)


## Gets a new InputTrigger from the classname
func get_input_trigger(p_input_trigger_class) -> InputTrigger:
	if not has_input_trigger_class(p_input_trigger_class):
		return null
	
	return _input_triggers_types[p_input_trigger_class].new()


## Gets a new ActionTrigger from the classname
func get_action_trigger(p_action_trigger_class) -> ActionTrigger:
	if not has_action_trigger_class(p_action_trigger_class):
		return null
	
	return _action_triggers_types[p_action_trigger_class].new()


## Checks if an InputTrigger class is valid
func has_input_trigger_class(p_input_trigger_class: String) -> bool:
	return _input_triggers_types.has(p_input_trigger_class)


## Checks if an ActionTrigger class is valid
func has_action_trigger_class(p_action_trigger_class: String) -> bool:
	return _action_triggers_types.has(p_action_trigger_class)


## Checks if an event is allowed for shortcut inputs
func is_event_allowed(event: InputEvent) -> bool:
	return event.get_class() in _allowed_events


## Checks if a key is allowed
func is_key_allowed(key: Key) -> bool:
	return key not in _keycode_block_list


## Checks if a joybutton is allowed
func is_joy_button_allowed(button: JoyButton) -> bool:
	return button not in _joy_button_block_list


## Handles Midi input events
func _handle_midi_input(midi: InputEventMIDI) -> void:
	if midi.channel in _midi_pitch_mappings:
		match midi.message:
			MIDI_MESSAGE_NOTE_ON:
				if midi.pitch in _midi_pitch_mappings[midi.channel]: 
					_midi_pitch_mappings[midi.channel][midi.pitch].down()
			
			MIDI_MESSAGE_NOTE_OFF:
				if midi.pitch in _midi_pitch_mappings[midi.channel]: 
					_midi_pitch_mappings[midi.channel][midi.pitch].up()
			
			MIDI_MESSAGE_CONTROL_CHANGE:
				if midi.controller_number in _midi_controler_mappings[midi.channel]:
					_midi_controler_mappings[midi.channel][midi.controller_number].value(midi.controller_value)


## Handles the store mode action
func _handle_store_mode_action() -> void:
	Programmer.exit_store_mode() if Programmer.get_store_mode() else Programmer.enter_store_mode()


## Saves this ui to a dictionary
func save() -> Dictionary:
	var saved_input_actions: Array[Dictionary]
	
	for input_action: InputAction in _input_actions.get_left():
		saved_input_actions.append(input_action.save())
	
	return {
		"input_actions": saved_input_actions
	}


## Loads this ui from a dictionary
func load(saved_data: Dictionary) -> void:
	var saved_input_actions: Array = type_convert(saved_data.get("input_actions", []), TYPE_ARRAY)
		
	for saved_input_action: Variant in saved_input_actions:
		if saved_input_action is Dictionary and saved_input_action.get("class") == "InputAction":
			var input_action: InputAction = InputAction.new()
			InputMap.add_action(type_convert(saved_input_action.get("uuid"), TYPE_STRING))
			
			input_action.load(saved_input_action)
			add_input_action(input_action)
