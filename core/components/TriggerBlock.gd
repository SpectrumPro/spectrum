# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name TriggerBlock extends EngineComponent
## Block of triggers


## Emitted when a trigger is added
signal trigger_added(component: EngineComponent, id: String, name: String, row: int, column: int)

## Emitted when a trigger is added
signal trigger_removed(row: int, column: int)

## Emitted when a column is reset
signal column_reset(column: int)

## Emitted when a trigger name is changes
signal trigger_name_changed(row: int, column: int, name: String)

## Emitted when a trigger is triggred
signal trigger_up(row: int, column: int)

## Emitted when a trigger is triggred
signal trigger_down(row: int, column: int)


## All triggeres stores as { row: { column: {trigger...} } }
var _triggers: Dictionary[int, Dictionary]


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_name("TriggerBlock")
	_set_class_name("TriggerBlock")
		
	_settings.register_networked_callbacks({
		"trigger_added": _add_trigger,
		"trigger_removed": _remove_trigger,
		"column_reset": _reset_column,
		"trigger_name_changed": _rename_trigger,
		"trigger_up": _call_trigger_up,
		"trigger_down": _call_trigger_down,
	})


## Adds a trigger at the given row and column
func add_trigger(p_component: EngineComponent, p_id: String, p_name: String, p_row: int, p_column: int) -> Promise:
	return rpc("add_trigger", [p_component, p_id, p_name, p_row, p_column])


## Removes a trigger
func remove_trigger(p_row: int, p_column: int) -> Promise:
	return rpc("remove_trigger", [p_row, p_column])


## Resets a whole column
func reset_column(p_column: int) -> Promise:
	return rpc("reset_column", [p_column])


## Removes a trigger
func rename_trigger(p_row: int, p_column: int, p_name: String) -> Promise:
	return rpc("rename_trigger", [p_row, p_column, p_name])


## Triggers a trigger
func call_trigger_up(p_row: int, p_column: int, p_value: Variant = null) -> Promise:
	return rpc("call_trigger_up", [p_row, p_column, p_value])


## Triggers a trigger
func call_trigger_down(p_row: int, p_column: int, p_value: Variant = null) -> Promise:
	return rpc("call_trigger_down", [p_row, p_column, p_value])


## Gets all the triggers
func get_triggers() -> Dictionary[int, Dictionary]:
	return _triggers.duplicate()


## Overide this function to serialize your object
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	var triggers: Dictionary[int, Dictionary]
	
	for row: int in _triggers:
		triggers[row] = {}
		for column: int in _triggers[row]:
			triggers[row][column] = {
				"component": _triggers[row][column].component.uuid,
				"up": _triggers[row][column].up.get_method() if _triggers[row][column].up else "",
				"down": _triggers[row][column].down.get_method() if _triggers[row][column].down else "",
				"name": _triggers[row][column].name,
				"id": _triggers[row][column].id
			}
	
	return super.serialize(p_flags).merged({
		"triggers": triggers
	})


## Overide this function to handle load requests
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	var triggers: Dictionary = type_convert(p_serialized_data.get("triggers", {}), TYPE_DICTIONARY)
	
	for row_key: int in triggers.keys():
		var row_dict: Dictionary = type_convert(triggers.get(row_key, {}), TYPE_DICTIONARY)
		
		for column_key: int in row_dict.keys():
			var trigger_data: Dictionary = type_convert(row_dict.get(column_key, {}), TYPE_DICTIONARY)
			
			var component_id: String = type_convert(trigger_data.get("component", ""), TYPE_STRING)
			var id: String = type_convert(trigger_data.get("id", ""), TYPE_STRING)
			var name: String = type_convert(trigger_data.get("name", ""), TYPE_STRING)
			
			if component_id == null:
				continue
			
			ComponentDB.request_component(component_id, func(component: EngineComponent) -> void:
				_add_trigger(component, id, name, row_key, column_key, true)
			)


## Internal: Adds a trigger at the given row and column
func _add_trigger(p_component: EngineComponent, p_id: String, p_name: String, p_row: int, p_column: int, no_signal: bool = false) -> bool:
	if not p_component.get_control_method(p_id):
		return false
	
	_triggers.get_or_add(p_row, {})[p_column] = {
		"component": p_component,
		"id": p_id,
		"name": p_name,
	}
	
	if not no_signal:
		trigger_added.emit(p_component, p_id, p_name, p_row, p_column)
	
	return true


## Internal: Removes a trigger
func _remove_trigger(p_row: int, p_column: int, no_signal: bool = false) -> bool:
	if not _triggers.has(p_row) or not _triggers[p_row].has(p_column):
		return false
	
	_triggers.get(p_row, {}).erase(p_column)
		
	if not no_signal:
		trigger_removed.emit(p_row, p_column)
	
	return true


## Internal Resets a whole column
func _reset_column(p_column: int) -> void:
	for row: int in _triggers:
		if p_column in _triggers[row]:
			_remove_trigger(row, p_column, true)
	
	column_reset.emit(p_column)


## Renames a trigger
func _rename_trigger(p_row: int, p_column: int, p_name: String, no_signal: bool = false) -> bool:
	if not _triggers.has(p_row) or not _triggers[p_row].has(p_column):
		return false
	
	_triggers[p_row][p_column].name = p_name
	
	if not no_signal:
		trigger_name_changed.emit(p_row, p_column, no_signal)


	return true


## Internal: Triggers a trigger
func _call_trigger_up(p_row: int, p_column: int, p_value: Variant = null) -> void:
	var trigger: Dictionary = _triggers.get(p_row, {}).get(p_column, {})
	
	if not trigger:
		return
	
	trigger_up.emit(p_row, p_column, p_value)


## Internal: Triggers a trigger
func _call_trigger_down(p_row: int, p_column: int, p_value: Variant = null) -> void:
	var trigger: Dictionary = _triggers.get(p_row, {}).get(p_column, {})
	
	if not trigger:
		return
	
	trigger_down.emit(p_row, p_column, p_value)
