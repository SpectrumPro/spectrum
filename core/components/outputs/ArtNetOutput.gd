# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ArtNetOutput extends DMXOutput
## Art-Net DMX Output


## Emitted when the ip is changed
signal ip_changed(ip: String)

## Emitted when the broadcast state is changed
signal broadcast_state_changed(use_broadcast: bool)

## Emitted when the universe number is changed
signal universe_number_changed(universe_number: int)


## IP address of node to connect to
var _ip_address: String = "127.0.0.1"

## Art-Net _port number
var _port: int = 6454

## Broadcast state
var _use_broadcast: bool = false

## Art-Net universe number
var _universe_number: int = 0


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_name("ArtNetOutput")
	_set_class_name("ArtNetOutput")
	
	_settings.register_setting("ip_address", Data.Type.STRING, set_ip, get_ip, [ip_changed])
	_settings.register_setting("use_broadcast", Data.Type.BOOL, set_use_broadcast, get_use_broadcast, [broadcast_state_changed])
	_settings.register_setting("universe_number", Data.Type.INT, set_universe_number, get_universe_number, [universe_number_changed])
	
	_settings.register_networked_callbacks({
		"on_ip_changed": _set_ip,
		"on_broadcast_state_changed": _set_use_broadcast,
		"on_universe_number_changed": _set_universe_number,
	})


## Sets the ip address
func set_ip(p_ip: String) -> Promise: return rpc("set_ip", [p_ip])

## Internal: Sets the ip address
func _set_ip(p_ip: String) -> void:
	_ip_address = p_ip
	ip_changed.emit(_ip_address)

## Gets the ip address
func get_ip() -> String:
	return _ip_address


## Sets the broadcast state
func set_use_broadcast(p_use_broadcast: bool) -> Promise: return rpc("set_use_broadcast", [p_use_broadcast])

## Internl: Sets the broadcast state
func _set_use_broadcast(p_use_broadcast: bool) -> void:
	_use_broadcast = p_use_broadcast
	broadcast_state_changed.emit(_use_broadcast)

## Gets the broadcast state
func get_use_broadcast() -> bool:
	return _use_broadcast


## Sets the universe number
func set_universe_number(p_universe_number: int) -> Promise: return rpc("set_universe_number", [p_universe_number])

## Internal: Sets the universe number
func _set_universe_number(p_universe_number: int) -> void:
	_universe_number = p_universe_number
	universe_number_changed.emit()


## Gets the universe number
func get_universe_number() -> int:
	return _universe_number


## Saves this component to a dictonary
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"ip_address": _ip_address,
		"port": _port,
		"use_broadcast": _use_broadcast,
		"universe_number": _universe_number,
		"auto_start": _auto_start
	})


## Loads this component from a dictonary
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	_ip_address = type_convert(p_serialized_data.get("ip_address", _ip_address), TYPE_STRING)
	_port = type_convert(p_serialized_data.get("port", _port), TYPE_INT)
	_use_broadcast = type_convert(p_serialized_data.get("use_broadcast"), TYPE_BOOL)
	_universe_number = type_convert(p_serialized_data.get("universe_number", _universe_number), TYPE_INT)
	_auto_start = type_convert(p_serialized_data.get("auto_start", _auto_start), TYPE_BOOL)
	
	_connection_state = type_convert(p_serialized_data.get("connection_state", _connection_state), TYPE_BOOL)
	_previous_note = type_convert(p_serialized_data.get("connection_note", _connection_state), TYPE_STRING)
