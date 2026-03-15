# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Scene extends Function
## Engine class for creating and recalling saved data


## Emitted when the fade in time has changed
signal fade_in_speed_changed(fade_in_speed: float)

## Emitted when the fade out time has changed
signal fade_out_speed_changed(fade_out_speed: float)


## Fade in time in seconds, defaults to 2 seconds
var _fade_in_speed: float = 2

## Fade out time in seconds, defaults to 2 seconds
var _fade_out_speed: float = 2


## Called when this EngineComponent is ready
func _init(p_uuid: String = UUID.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("Scene")
	_set_class_name("Scene")
	
	_settings.register_setting("fade_in", Data.Type.FLOAT, set_fade_in_speed, get_fade_in_speed, [fade_in_speed_changed])
	_settings.register_setting("fade_out", Data.Type.FLOAT, set_fade_out_speed, get_fade_out_speed, [fade_out_speed_changed])
	
	_settings.register_networked_callbacks({
		"on_fade_in_speed_changed": _set_fade_in_speed,
		"on_fade_out_speed_changed": _set_fade_out_speed,
	})


## Sets the fade in speed in seconds
func set_fade_in_speed(p_fade_in: float) -> void: 
	rpc("set_fade_in_speed", [p_fade_in])


## Gets the current fade speed
func get_fade_in_speed() -> float: 
	return _fade_in_speed


## Sets the fade out speed in seconds
func set_fade_out_speed(p_fade_out: float) -> void: 
	rpc("set_fade_out_speed", [p_fade_out])


## Gets the fade out speed
func get_fade_out_speed() -> float: 
	return _fade_out_speed


## Called when the fade in time is changed on the server
func _set_fade_in_speed(p_fade_in_speed: float) -> void:
	_fade_in_speed = p_fade_in_speed
	fade_in_speed_changed.emit(_fade_in_speed)


## Called whem the fade out time is changed on the server
func _set_fade_out_speed(p_fade_out_speed: float) -> void:
	_fade_out_speed = p_fade_out_speed
	fade_out_speed_changed.emit(_fade_out_speed)


## Serializes this scene and returnes it in a dictionary
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"fade_in_speed": _fade_in_speed,
		"fade_out_speed": _fade_out_speed,
		"save_data": _data_container.serialize()
	})


func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	_fade_in_speed = type_convert(p_serialized_data.get("fade_in_speed", _fade_in_speed), TYPE_FLOAT)
	_fade_out_speed = type_convert(p_serialized_data.get("fade_out_speed", _fade_out_speed), TYPE_FLOAT)
	
	Network.deregister_network_object(_data_container.get_settings())
	_data_container.deserialize(p_serialized_data.get("save_data", {}))
	Network.register_network_object(_data_container.get_uuid(), _data_container.get_settings())
