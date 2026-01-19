# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIBase extends Control
## Client Component base class for all UI elements


## Emitted when the UI name is changed
signal ui_name_changed(ui_name: String)


## UUID of this UIBase
var _uuid: String = UUID_Util.v4()

## Class tree
var _class_tree: Array[String] = ["UIBase"]

## Current class name
var _self_class_name: String = "UIBase"

## The name of this UIBase
var _ui_name: String = _self_class_name

## Stores all queued callables for this frame
var _queue_order: Array[Callable]

## Stores arguments for each queued callable
var _queue_args: Dictionary[Callable, Array]

## True if _call_queue has already been call_defered()
var _queue_call_defered: bool = false

## True if _call_queue is running currently
var _queue_is_calling: bool = false

## Settings for this component
var settings_manager: SettingsManager = SettingsManager.new()


## Init
func _init() -> void:
	settings_manager.set_owner(self)
	settings_manager.set_inheritance_array(_class_tree)
	
	settings_manager.register_setting("name", Data.Type.STRING, set_ui_name, get_ui_name, [ui_name_changed])
	
	(func ():
		if _ui_name == "UIBase":
			_ui_name = _self_class_name
	).call_deferred()


## Gets the uuid
func uuid() -> String:
	return _uuid


## Queues a callable for execution, will only all it to be called once per frame. Uses call_defered
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


## Sets the UI name
func set_ui_name(p_ui_name) -> void:
	_ui_name = p_ui_name
	ui_name_changed.emit(_ui_name)


## Gets the UIName
func get_ui_name() -> String:
	return _ui_name


## Gets the classname
func get_class_name() -> String:
	return _self_class_name


## Gets the class tree
func get_class_tree() -> Array[String]:
	return _class_tree.duplicate()


## Sets the classname of this component
func _set_class_name(p_class_name: String) -> void:
	_self_class_name = p_class_name
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


## Serialize this ClientComponent into a Dictionary
func serialize() -> Dictionary:
	return {
		"uuid": _uuid,
		"name": _ui_name,
		"class": _self_class_name,
	}


## Deserializes this ClientComponent from a dictionary
func deserialize(p_serialized_data: Dictionary) -> void:
	_uuid = type_convert(p_serialized_data.get("uuid", _uuid), TYPE_STRING)
	_ui_name = type_convert(p_serialized_data.get("name", name), TYPE_STRING)
