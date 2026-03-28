# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

extends Node
## Script for holding shared values, used by mutiple ui panels in the program, also supports network shaired values
## Static Values: can be used to store any object / variant
## Selection Values: Used to store lists, mainly used for storing selections


## Dictionary containing all the static values being shared between different parts of the spectrum ui, stored as value_name:value
var static_values: Dictionary = {}

## Dictionary containing all the selection values being shared between different parts of the spectrum ui, stored as value_name:value
var selection_values: Dictionary = {}


## Resets all the values and disconnects all signals
func reset() -> void:
	static_values = {}
	selection_values = {}


func _disconnect_all_signal_methods(sig: Signal) -> void:
	for signal_dict: Dictionary in sig.get_connections():
		sig.disconnect(signal_dict.callable)


#region Static Values
## Connect to a value
func connect_to_static_value(value_name: String, callback: Callable):
	if not has_user_signal(value_name + "_static_value_callback"):
		add_user_signal(value_name + "_static_value_callback")
	
	connect(value_name + "_static_value_callback", callback)


## Disconnect from a value
func disconnect_from_static_value(value_name: String, callback: Callable):
	disconnect(value_name + "_static_value_callback", callback)


## Set a value
func set_static_value(value_name: String, value: Variant):
	if not has_user_signal(value_name + "_static_value_callback"):
		add_user_signal(value_name + "_static_value_callback")
		
	if not static_values[value_name] == value:
		static_values[value_name] = value
		emit_signal(value_name + "_static_value_callback", static_values[value_name])


## Get a value, returnes the value, otherwise default
func get_static_value(value_name: String, default: Variant = null) -> Variant:
	return static_values.get(value_name, default)
#endregion


#region Selection Values
func connect_to_selection_value(value_name: String, callback: Callable) -> void:
	if not has_user_signal(value_name + "_selection_value_callback"):
		add_user_signal(value_name + "_selection_value_callback")
	
	connect(value_name + "_selection_value_callback", callback)


## Disconnect from a selection value
func disconnect_from_selection_value(value_name: String, callback: Callable):
	disconnect(value_name + "_selection_value_callback", callback)


## Set a selection value
func set_selection_value(value_name: String, value: Array, no_signal: bool = false): 
	if not has_user_signal(value_name + "_selection_value_callback"):
		add_user_signal(value_name + "_selection_value_callback")
	
	#if selection_values.get(value_name, null) != value:
	selection_values[value_name] = value
	
	if not no_signal:
		emit_signal(value_name + "_selection_value_callback", selection_values[value_name].duplicate())


## Emits a selection value signal
func emit_selection_value(value_name: String) -> void:
	if value_name in selection_values:
		emit_signal(value_name + "_selection_value_callback", selection_values[value_name].duplicate())


## Add an array of items to a selection value
func add_to_selection_value(value_name: String, array_to_add: Array, no_signal: bool = false):
	var new_array: Array = selection_values.get(value_name, [])
	
	for item: Variant in array_to_add:
		if item not in new_array:
			new_array.append(item)
	
	if not no_signal:
		set_selection_value(value_name, new_array)


## Removes an array of items to a selection value
func remove_from_selection_value(value_name: String, array_to_remove: Array, no_signal: bool = false):
	var new_array: Array = selection_values.get(value_name, []).duplicate()
	
	for item: Variant in array_to_remove:
		new_array.erase(item)
	
	if not no_signal:
		set_selection_value(value_name, new_array)


## Get a selection value, returnes the value, otherwise default
func get_selection_value(value_name: String, default: Variant = []) -> Variant:
	return selection_values.get(value_name, default)


## Returns the length of a selection value
func len_of(value_name: String) -> int:
	return len(selection_values.get(value_name, []))


## TODO: Called when a engine component emits delete_requested and is in a static value
#func _on_engine_component_deleted_static(selection_value: String, component: EngineComponent) -> void:
	#remove_from_selection_value(selection_value, [component])


## Called when an EngineComponent emits delete_requested and is in a selection value
func _on_engine_component_deleted_selection_value(selection_value: String, component: EngineComponent) -> void:
	remove_from_selection_value(selection_value, [component])

#endregion
