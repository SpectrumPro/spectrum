# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DMXOutput extends EngineComponent
## Base class for all DMX outputs


## Emited when this output connects or disconnects, added note for reason
signal connection_state_changed(state: bool, note: String)

## Emitted when the auto start state is changed
signal auto_start_changed(auto_start)


## Autostart state
var _auto_start: bool = true

## Current connection state
var _connection_state: bool = false

## The last note given for connection status
var _previous_note: String = ""


## init
func _init(p_uuid: String = UUID.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("DMXOutput")
	_set_class_name("DMXOutput")
	
	_settings.register_custom_panel("connection_status_panel", preload("res://components/SettingsManagerCustomPanels/DMXOutputStatusDisplay.tscn"), "set_output")
	_settings.register_setting("auto_start", Data.Type.BOOL, set_auto_start, get_auto_start, [auto_start_changed])
	
	_settings.register_control("start", Data.Type.ACTION, start)
	_settings.register_control("stop", Data.Type.ACTION, stop)
	
	_settings.register_status("connection_status", Data.Type.BOOL, get_connection_state, [connection_state_changed])
	
	_settings.register_networked_callbacks({
		"on_connection_state_changed": _on_connection_state_changed,
		"on_auto_start_changed": _set_auto_start,
	})


## Sets the auto start state
func set_auto_start(p_auto_start: bool) -> Promise: return rpc("set_auto_start", [p_auto_start])

## Internal: Sets the auto start state
func _set_auto_start(p_auto_start: bool) -> void:
	_auto_start = p_auto_start
	auto_start_changed.emit(p_auto_start)

## Gets the auto start state
func get_auto_start() -> bool:
	return _auto_start


## Gets the previous note
func get_previous_note() -> String:
	return _previous_note


## Gets the current connection state
func get_connection_state()-> bool:
	return _connection_state


## Starts this plugin
func start() -> Promise: 
	return rpc("start")


## Stops this plugin
func stop() -> Promise: 
	return rpc("stop")


## Server: Called when the connection state changes on the server
func _on_connection_state_changed(p_state: bool, p_note: String) -> void:
	_connection_state = p_state
	connection_state_changed.emit(p_state, p_note)
