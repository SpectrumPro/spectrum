# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name FunctionGroup extends Function
## A group of functions


## Emitted when functions are added
signal functions_added(functions: Array)

## Emitted when functions are removed
signal functions_removed(functions: Array)

## Emitted when a Function's index is changed
signal functions_index_changed(function: Function, index: int)


## Refmap for storing functions
var _functions: Array[Function]


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_name("FunctionGroup")
	_set_class_name("FunctionGroup")
	
	_settings.register_custom_panel("functions", preload("res://components/SettingsManagerCustomPanels/FixtureGroupFixtures.tscn"), "set_fixture_group")
	
	_settings.register_networked_callbacks({
		"on_functions_added": _add_functions,
		"on_functions_removed": _remove_functions,
		"on_functions_index_changed": _set_function_index,
	})


# Adds a function
func add_function(p_function: Function) -> Promise:
	return rpc("add_function", [p_function])


## Adds mutiple functions at once
func add_functions(p_functions: Array) -> Promise:
	return rpc("add_functions", [p_functions])


## Removes a function
func remove_function(p_function: Function) -> Promise:
	return rpc("remove_function", [p_function])


## Removes mutiple functions at once
func remove_functions(p_functions: Array) -> Promise:
	return rpc("remove_functions", [p_functions])


## Sets the indes of a function
func set_function_index(p_function: Function, p_index: int) -> Promise:
	return rpc("set_function_index", [p_function, p_index])


## Moves a Function up an index
func move_up(p_function: Function) -> Promise:
	return rpc("move_up", [p_function])


## Moves a Function down an index
func move_down(p_function: Function) -> Promise:
	return rpc("move_down", [p_function])


## Gets all the functions
func get_functions() -> Array[Function]:
	return _functions.duplicate()


## Checks if this FunctionGroup has a function
func has_function(p_function: Function) -> bool:
	return _functions.has(p_function)



## Adds a function
func _add_function(p_function: Function, no_signal: bool = false) -> bool:
	if p_function and p_function in _functions and p_function != self:
		return false
	
	p_function.delete_requested.connect(_remove_function)
	_functions.append(p_function)

	if not no_signal:
		functions_added.emit([p_function])

	return true


## Adds mutiple functions at once
func _add_functions(p_functions: Array) -> void:
	var just_added_functions: Array[Function]

	for function: Variant in p_functions:
		if function is Function:
			if _add_function(function, true):
				just_added_functions.append(function)

	if just_added_functions:
		functions_added.emit(just_added_functions)


## Removes a function
func _remove_function(p_function: Function, no_signal: bool = false) -> bool:
	if p_function not in _functions:
		return false

	_functions.erase(p_function)
	p_function.delete_requested.disconnect(_remove_function)
	if not no_signal:
		functions_removed.emit([p_function])

	return true


## Removes mutiple functions at once
func _remove_functions(p_functions: Array) -> void:
	var just_removed_functions: Array[Function]

	for function: Variant in p_functions:
		if function is Function:
			if _remove_function(function, true):
				just_removed_functions.append(function)

	if just_removed_functions:
		functions_removed.emit(just_removed_functions)


## Sets the indes of a function
func _set_function_index(p_function: Function, p_index: int) -> bool:
	if p_function not in _functions or p_index > _functions.size():
		return false

	_functions.erase(p_function)
	_functions.insert(p_index, p_function)

	functions_index_changed.emit(p_function, p_index)

	return true


## Overide this function to serialize your object
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	var function_uuids: Array[String]
	
	for function: Function in _functions:
		function_uuids.append(function.uuid)
	
	return super.serialize(p_flags).merged({
		"functions": function_uuids,
	})


## Overide this function to handle load requests
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	var function_uuids: Array = type_convert(p_serialized_data.get("functions", []), TYPE_ARRAY)
	
	for uuid: Variant in function_uuids:
		if not uuid is String:
			continue
		
		ComponentDB.request_component(uuid, func (function: EngineComponent):
			if function is Function:
				_add_function(function)
		)
