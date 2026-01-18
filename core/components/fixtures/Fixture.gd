# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Fixture extends EngineComponent
## Engine class to control parameters of fixtures

@warning_ignore_start("unused_signal")

## Emitted when parameters are changed
signal parameter_changed(zone: String, parameter: String, function: String, value: Variant)

## Emitted when a parameter is erased
signal parameter_erased(zone: String, parameter: String)

## Emited when a parameter override is changed or added
signal override_changed(zone: String, parameter: String, function: String, value: Variant)

## Emitted when a parameter override is removed
signal override_erased(zone: String, parameter: String)

## Emitted when all overrides are removed
signal all_override_removed()


## Enum for ControlType
enum ControlType {
	INTENSITY,  # % based, blackout/full
	POSITION,   # homeable, spatial
	SELECT,     # discrete choices
	VALUE,      # continuous, non-% 
	SPEED,      # rate-based
	SYSTEM      # non-show controls
}


## Root Zone
static var RootZone: String = "root"


## init
func _init(p_uuid: String = UUID_Util.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_self_class("Fixture")
	_set_name("Fixture")
	
	_settings_manager.register_networked_callbacks({
		"on_parameter_changed": _set_parameter,
		"on_parameter_erased": _erase_parameter,
		"on_override_changed": _set_override,
		"on_override_erased": _erase_override,
		"on_all_override_removed": _erase_all_overrides,
	})


## Sets a parameter to a float value
func set_parameter(p_parameter: String, p_function: String, p_value: float, p_layer_id: String, p_zone: String = "root") -> Promise:
	return rpc("set_parameter", [p_parameter, p_function, p_value, p_layer_id, p_zone])


## Erases the parameter on the given layer
func erase_parameter(p_parameter: String, p_layer_id: String, p_zone: String = "root") -> Promise:
	return rpc("erase_parameter", [p_parameter, p_layer_id, p_zone])


## Sets a parameter override to a float value
func set_override(p_parameter: String, p_function: String, p_value: float, p_zone: String = "root") -> Promise:
	return rpc("set_override", [p_parameter, p_function, p_value, p_zone])


## Erases the parameter override 
func erase_override(p_parameter: String, p_zone: String = "root") -> Promise:
	return rpc("erase_override", [p_parameter, p_zone])


## Erases all overrides
func erase_all_overrides() -> Promise:
	return rpc("erase_all_overrides")


## Internal: Erases all overrides
func _erase_all_overrides() -> void:
	return 


## Gets all the override values
func get_all_override_values() -> Dictionary:
	return {}


## Gets all the values
func get_all_values_layered() -> Dictionary:
	return {}


## Gets all the values
func get_all_values() -> Dictionary:
	return {}


## Gets all the parameters and there category from a zone
func get_parameter_categories(p_zone: String) -> Dictionary:
	return {}


## Gets all the parameter functions
func get_parameter_functions(p_zone: String, p_parameter: String) -> Array:
	return []


## Gets all the parameter functions
func get_function_control_type(p_zone: String, p_parameter: String, p_function: String) -> ControlType:
	return ControlType.VALUE


## Gets the default value of a parameter
func get_default(p_zone: String, p_parameter: String, p_function: String = "", p_raw_dmx: bool = false) -> float:
	return 0.0


## Gets the default function for a zone and parameter, or the first function if none can be found
func get_default_function(p_zone: String, p_parameter: String) -> String:
	return ""


## Gets the current value, or the default
func get_current_value(p_zone: String, p_parameter: String, p_allow_default: bool = true, p_allow_override: bool = true) -> float:
	return 0.0


## Gets the current value, or the default
func get_current_function(p_zone: String, p_parameter: String, p_allow_default: bool = true, p_allow_override: bool = true) -> String:
	return ""


## Gets the current value, or the default
func get_current_value_or_force_default(p_zone: String, p_parameter: String) -> float:
	return 0.0


## Gets all the zones
func get_zones() -> Array[String]:
	return []


## Checks if this Fixture has any overrides
func has_overrides() -> bool:
	return false


## Returns true if this Fixture has an override value
func has_override(p_zone: String, p_parameter: String) -> bool:
	return false


## Checks if this fixture has a parameter
func has_parameter(p_zone: String, p_parameter: String, p_function: String = "") -> bool:
	return false


## Checks if a parameter is a force default
func has_force_default(p_parameter: String) -> bool:
	return false


## Checks if this Fixture has a function that can fade
func function_can_fade(p_zone: String, p_parameter: String, p_function: String) -> bool:
	return false


## Subscribes to a parameter on the given zone
func subscribe_to_parameter(p_zone: String, p_parameter: String, p_callable: Callable) -> bool:
	return false


## Removes a subscription from the parameter in the given zone
func remove_subscription(p_zone: String, p_parameter: String, p_callable: Callable) -> bool:
	return false


## Internal: Sets a parameter to a float values
func _set_parameter(p_zone: String, p_parameter: String, p_function: String, p_value: Variant) -> void:
	return 


## Internal: Erases the parameter on the given layer
func _erase_parameter(p_zone: String, p_parameter: String) -> void:
	return 


## Internal: Sets a parameter override to a float value
func _set_override(p_zone: String, p_parameter: String, p_function: String, p_value: float) -> void:
	return


## Internal: Erases the parameter override 
func _erase_override(p_zone: String, p_parameter: String) -> void:
	return
