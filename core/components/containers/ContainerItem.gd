# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ContainerItem extends EngineComponent
## Item for DataContainer


## The Fixture to control
var _fixture: Fixture

## The Fixture's zone
var _zone: String

## The parameter on the zone
var _parameter: String

## The functions of the parameter
var _function: String

## The value to set
var _value: float = 1.0

## Can this value fade state
var _can_fade: bool = true

## Animation start point
var _start: float = 0.0

## Animation stop point
var _stop: float = 1.0

## Attribute ID for this ContainerItem
var _attribute_id: String = ""


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_name("ContainerItem")
	_set_class_name("ContainerItem")


## Checks if this ContainerItem is valid
func is_valid() -> bool:
	if _fixture and _zone and _parameter:
		return true

	else:
		return false


## Sets the fixture
func set_fixture(p_fixture: Fixture) -> bool:
	if p_fixture == _fixture:
		return false

	_fixture = p_fixture
	return true


## Sets the zone
func set_zone(p_zone: String) -> bool:
	if p_zone == _zone:
		return false

	_zone = p_zone
	return true


## Sets the parameter
func set_parameter(p_parameter: String) -> bool:
	if p_parameter == _parameter:
		return false
	
	_parameter = p_parameter
	_update_attribute_id()
	return true


## Sets the function
func set_function(p_function: String) -> bool:
	if p_function == _function:
		return false
	
	_function = p_function
	return true


## Sets the value
func set_value(p_value: float) -> bool:
	if p_value == _value:
		return false
	
	_value = p_value
	return true


## Sets can fade state
func set_can_fade(p_can_fade: bool) -> bool:
	if p_can_fade == _can_fade:
		return false

	_can_fade = p_can_fade
	return true


## Sets the start point
func set_start(p_start: float) -> bool:
	if p_start == _start:
		return false
	
	_start = p_start
	return true


## Sets the stop point
func set_stop(p_stop: float) -> bool:
	if p_stop == _stop:
		return false

	_stop = p_stop
	return true


## Gets the fixture
func get_fixture() -> Fixture:
	return _fixture


## Gets the zone
func get_zone() -> String:
	return _zone


## Gets the parameter
func get_parameter() -> String:
	return _parameter


## Gets the function
func get_function() -> String:
	return _function


## Gets the value
func get_value() -> float:
	return _value


## Gets the can_fade state
func get_can_fade() -> bool:
	return _can_fade


## Gets the start point
func get_start() -> float:
	return _start


## Gets the stop point
func get_stop() -> float:
	return _stop


## Returns a copy of this ContainerItem
func duplicate() -> ContainerItem:
	var item: ContainerItem = ContainerItem.new()
	
	item.set_fixture(_fixture)
	item.set_zone(_zone)
	item.set_parameter(_parameter)
	item.set_function(_function)
	item.set_value(_value)
	item.set_can_fade(_can_fade)
	item.set_start(_start)
	item.set_stop(_stop)

	return item


## Gets the attribute id
func get_attribute_id() -> String:
	_update_attribute_id()
	return _attribute_id


## Saves this component into a dict
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"fixture": _fixture.uuid,
		"zone": _zone,
		"parameter": _parameter,
		"function": _function,
		"value": _value,
		"can_fade": _can_fade,
		"start": _start,
		"stop": _stop,
	})


## Loads this component from a dict
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	_fixture = ComponentDB.get_component(type_convert((p_serialized_data.get("fixture", "")), TYPE_STRING))
	
	_zone = type_convert((p_serialized_data.get("zone", "")), TYPE_STRING)
	_parameter = type_convert((p_serialized_data.get("parameter", "")), TYPE_STRING)
	_function = type_convert((p_serialized_data.get("function", "")), TYPE_STRING)
	_value = type_convert((p_serialized_data.get("value", "")), TYPE_FLOAT)
	
	_can_fade = type_convert((p_serialized_data.get("zone", _can_fade)), TYPE_BOOL)
	
	_start = type_convert((p_serialized_data.get("start", _start)), TYPE_FLOAT)
	_stop = type_convert((p_serialized_data.get("stop", _stop)), TYPE_FLOAT)


## Updates the attribute id
func _update_attribute_id() -> void:
	_attribute_id = (_fixture.get_uuid() if _fixture else "") + _zone + _parameter
