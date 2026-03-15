# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIBase extends Control
## Client Component base class for all UI elements


## Emitted when the user-defined name of this object changes.
signal name_changed()

## Emitted when this object is to be deleted (freed from memory). 
signal delete_requested()


## The user-defined name of this object. The variable name can be arbitrary.
var _name: String

## The UUID of this object. The variable name can be arbitrary.
var _uuid: String

## The class name of this object. Must be set by any class that extends this base class.
var _class_name: String

## The inheritance tree of this object. Defaults to include this class.
var _class_tree: Array[String]

## The SettingsManager instance associated with this object. Variable name can be arbitrary.
var _settings: SettingsManager = SettingsManager.new()

## Stores all queued callables for this frame
var _queue_order: Array[Callable] = []

## Stores arguments for each queued callable
var _queue_args: Dictionary[Callable, Array] = {}

## True if _call_queue has already been call_deferred()
var _queue_call_defered: bool = false

## True if _call_queue is running currently
var _queue_is_calling: bool = false


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	_uuid = p_uuid
	_set_class_name("UIBase")
	
	_settings.set_owner(self)
	_settings.set_inheritance_array(_class_tree)


## Returns the user-defined name of this object.
func get_uname() -> String:
	return _name


## Returns the UUID of this object.
func get_uuid() -> String:
	return _uuid


## Returns the class name of this object.
func get_class_name() -> String:
	return _class_name


## Returns a copy of the inheritance tree for this object.
func get_class_tree() -> Array[String]:
	return _class_tree.duplicate()


## Returns the SettingsManager for this object.
func get_settings() -> SettingsManager:
	return _settings


## Sets the name of this object. If p_no_signal is true, the name_changed signal is not emitted.
func set_uname(p_name: String, p_no_signal: bool = false) -> void:
	_name = p_name
	
	if not p_no_signal:
		name_changed.emit(_name)


## Queues a callable for execution, will only allow it to be called once per frame. Uses call_deferred
func queue(p_callable: Callable, p_args: Array[Variant] = []) -> bool:
	if _queue_is_calling:
		p_callable.callv(p_args)
		return true
	elif _queue_args.has(p_callable):
		_queue_args[p_callable] = p_args
		return false
	else:
		_queue_order.append(p_callable)
		_queue_args[p_callable] = p_args
		
		if not _queue_call_defered:
			_call_queue.call_deferred()
			_queue_call_defered = true
		
		return true


## Emits the delete_requested signal to notify that this object should be deleted.
func delete() -> void:
	delete_requested.emit()


## Returns a JSON-compliant dictionary containing a serialized version of this object.
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return {
		"name": _name,
		"class_name": _class_name,
	}.merged({} if p_flags & Data.SerializationFlags.NO_UUID else {
		"uuid": _uuid,
	})


## Deserializes data either read from disk or returned by serialize().
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	set_uname(type_convert(p_serialized_data.get("name", _name), TYPE_STRING), true)
	
	if not p_flags & Data.SerializationFlags.NO_UUID:
		_uuid = type_convert(p_serialized_data.get("uuid", _uuid), TYPE_STRING)


## Sets the class name for this object and appends it to the inheritance tree.
## This should be called by each child class during initialization.
func _set_class_name(p_class_name: String) -> void:
	_class_name = p_class_name
	_class_tree.append(p_class_name)


## Calls all the Callables in the queue
func _call_queue() -> void:
	_queue_is_calling = true
	
	for callable: Callable in _queue_order:
		callable.callv(_queue_args[callable])
	
	_queue_order.clear()
	_queue_args.clear()
	_queue_is_calling = false
	_queue_call_defered = false
