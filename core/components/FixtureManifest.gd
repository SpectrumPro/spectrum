# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name FixtureManifest extends EngineComponent
## Defines a manifest for a DMXFixture, specifying its channels, capabilities, and behavior.


## Manifest: This FixtureManifest contains a whole fixture description. 
## Info: This FixtureManifest contains basic info for a given manifest file.
enum Type {Manifest, Info}


## Current type of this FixtureManifest
var type: Type = Type.Manifest

## The manufacturer of this fixture
var manufacturer: String = ""

## The ManifestImport script that imported this manifest
var importer: String = "Unknown"

## The file path of this manifest on disk
var file_path: String = ""

## Contains all modes and the parameters
var _modes: Dictionary = {}

## Contains all the parameter categorys, sorted by mode
var _categorys: Dictionary = {}

## List of parameters whos default values should always be used
var _force_defaults: Array[String]


## init
func _init(p_uuid: String = UUID_Util.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_self_class("FixtureManifest")
	set_name("FixtureManifest")


## Creates a new mode
func create_mode(p_mode: String, p_dmx_length: int) -> bool:
	if _modes.has(p_mode):
		return false
	
	_modes[p_mode] = {
		"name": p_mode,
		"zones": {},
		"dmx_length": p_dmx_length
	}

	return true


## Creates a new zone in the given mode
func create_zone(p_mode: String, p_zone: String) -> bool:
	if not _modes.has(p_mode) or _modes[p_mode].zones.has(p_zone):
		return false
	
	_modes[p_mode].zones[p_zone] = {}

	return true


## Creates a parameter in the given mode and zone
func add_parameter(p_mode: String, p_zone: String, p_parameter: String, p_channels: Array[int], p_category: String = "", p_default_function: String = "") -> bool:
	if not _modes.has(p_mode) or not _modes[p_mode].zones.has(p_zone):
		return false
	
	_modes[p_mode].zones[p_zone][p_parameter] = {
		"attribute": p_parameter,
		"offsets": p_channels.duplicate(),
		"default_function": p_default_function,
		"functions": {}
	}
	
	_categorys.get_or_add(p_mode, {}).get_or_add(p_zone, {})[p_parameter] = p_category

	return true


## Duplicates a parameter to another zone
func duplicate_parameter(p_mode: String, p_parameter: String, p_from_zone: String, p_to_zone: String, p_channels: Array[int]) -> bool:
	if not _modes.has(p_mode) or not _modes[p_mode].zones.has(p_from_zone):
		return false

	var new_parameter: Dictionary = _modes[p_mode].zones[p_from_zone][p_parameter].duplicate(true)
	create_zone(p_mode, p_to_zone)

	new_parameter.offsets = p_channels
	_modes[p_mode].zones[p_to_zone][p_parameter] = new_parameter

	return true


## Removes a parameter
func remove_parameter(p_mode: String, p_zone: String, p_parameter: String) -> bool:
	if not _modes.has(p_mode) or not _modes[p_mode].zones.has(p_zone):
		return false
	
	return _modes[p_mode].zones[p_zone].erase(p_parameter)


## Adds a funtion to the given parameter
func add_parameter_function(p_mode: String, p_zone: String, p_parameter: String, p_function: String, p_name: String, p_default: int, p_range: Array[int], p_can_fade: bool, p_vdim_effected: bool, p_control_type: Fixture.ControlType) -> bool:
	if not _modes.has(p_mode) or not _modes[p_mode].zones.has(p_zone) or not _modes[p_mode].zones[p_zone].has(p_parameter):
		return false
	
	_modes[p_mode].zones[p_zone][p_parameter].functions[p_function] = {
		"attribute": p_function,
		"name": p_name,
		"default": p_default,
		"can_fade": p_can_fade,
		"vdim_effected": p_vdim_effected,
		"control_type": p_control_type,
		"dmx_range": p_range.duplicate(),
		"sets": []
	}

	return true


## Adds a channel set to the given function
func add_function_set(p_mode: String, p_zone: String, p_parameter: String, p_function: String, p_name: String, p_from: int) -> bool:
	if not _modes.has(p_mode) or not _modes[p_mode].zones.has(p_zone) or not _modes[p_mode].zones[p_zone].has(p_parameter):
		return false
	
	_modes[p_mode].zones[p_zone][p_parameter].functions[p_function].sets.append({
		"name": p_name,
		"from": p_from
	})

	return true


## Returns the DMX length of the given mode
func get_mode_length(p_mode: String) -> int:
	return _modes.get(p_mode, {}).get("dmx_length", 0)


## Sets the DMX length of the given mode
func set_mode_length(p_mode: String, p_dmx_length: int) -> void:
	_modes.get(p_mode, {}).dmx_length = p_dmx_length


## Checks if this FixtureManifest has a given mode
func has_mode(p_mode: String) -> bool:
	return _modes.has(p_mode)


## Checks if this FixtureManifest has a given parameter
func has_parameter(p_mode: String, p_zone: String, p_parameter: String) -> bool:
	return _modes.get(p_mode, {}).get("zones", {}).get(p_zone, {}).has(p_parameter)


## Checks if this FixtureManifest has a function in the given parameter and mode
func has_function(p_mode: String, p_zone: String, p_parameter: String, p_function: String) -> bool:
	return _modes.get(p_mode, {}).get("zones", {}).get(p_zone, {}).get(p_parameter, {}).get("functions", {}).has(p_function)


## Checks if this FixtureManifest has a function that can fade
func function_can_fade(p_mode: String, p_zone: String, p_parameter: String, p_function: String) -> bool:
	return _modes.get(p_mode, {}).get("zones", {}).get(p_zone, {}).get(p_parameter, {}).get("functions", {}).get(p_function, {}).get("can_fade", false)


## Checks if this FixtureManifest has a function that can vdim
func function_can_vdim(p_mode: String, p_zone: String, p_parameter: String, p_function: String) -> bool:
	return _modes.get(p_mode, {}).get("zones", {}).get(p_zone, {}).get(p_parameter, {}).get("functions", {}).get(p_function, {}).get("vdim_effected", false)


## Checks if this FixtureManifest has a function that can vdim
func function_control_type(p_mode: String, p_zone: String, p_parameter: String, p_function: String) -> Fixture.ControlType:
	return _modes.get(p_mode, {}).get("zones", {}).get(p_zone, {}).get(p_parameter, {}).get("functions", {}).get(p_function, {}).get("control_type", Fixture.ControlType.VALUE)


## Returns the given mode
func get_mode(p_mode: String) -> Dictionary:
	return _modes.get(p_mode, {})


## Returns all the modes in this manifest
func get_modes() -> Array[String]:
	return Array(_modes.keys(), TYPE_STRING, "", null)


## Returns all zones in this manifest
func get_zones(p_mode) -> Array[String]:
	return Array(_modes[p_mode].zones.keys(), TYPE_STRING, "", null)


## Gets all the categorys in a mode and zone
func get_categorys(p_mode: String, p_zone: String) -> Dictionary:
	return _categorys.get(p_mode, {}).get(p_zone, {})


## Gets all the parameter functions
func get_parameter_functions(p_mode: String, p_zone: String, p_parameter: String) -> Array:
	if not _modes.has(p_mode) or not _modes[p_mode].zones.has(p_zone) or not _modes[p_mode].zones[p_zone].has(p_parameter):
		return []
	
	return _modes[p_mode].zones[p_zone][p_parameter].functions.keys()


## Adds a force default
func add_force_default(p_parameter: String) -> bool:
	if p_parameter not in _force_defaults:
		_force_defaults.append(p_parameter)
		return true
	else:
		return false


## Removes a force default
func remove_force_default(p_parameter: String) -> bool:
	if p_parameter in _force_defaults:
		_force_defaults.erase(p_parameter)
		return true
	else:
		return false


## Gets all force defaults
func get_force_defaults() -> Array[String]:
	return _force_defaults.duplicate()


## Checks if a parameter is a force_default
func has_force_default(p_parameter) -> bool:
	return _force_defaults.has(p_parameter)


## Overide this function to serialize your object
func serialize() -> Dictionary:
	return super.serialize().merged({
		"type": type,
		"manufacturer": manufacturer,
		"importer": importer,
		"file_path": file_path,
		"modes": _modes,
		"categorys": _categorys,
		"force_defaults": _force_defaults
	})


## Overide this function to handle load requests
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	type = type_convert(p_serialized_data.get("type"), TYPE_INT)
	manufacturer = type_convert(p_serialized_data.get("manufacturer"), TYPE_STRING)
	importer = type_convert(p_serialized_data.get("importer"), TYPE_STRING)
	file_path = type_convert(p_serialized_data.get("file_path"), TYPE_STRING)
	
	_modes = type_convert(p_serialized_data.get("modes"), TYPE_DICTIONARY)
	_categorys = type_convert(p_serialized_data.get("categorys"), TYPE_DICTIONARY)
	_force_defaults = Array(type_convert(p_serialized_data.get("force_defaults"), TYPE_ARRAY), TYPE_STRING, "", null)
