# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DMXFixture extends Fixture
## Dmx Fixture


## Emitted when the channel is changed
signal channel_changed(channel: int)

## Emitted when the universe is changed
signal universe_changed(universe: Universe)

## Emitted when the manifest is changed
signal manifest_changed(manifest: FixtureManifest, mode: String)

## Emitted when the mode is changed
signal mode_changed(mode: String)


## The DMX channel of this fixture
var _channel: int = 0

## The current universe this fixture is patched to
var _universe: Universe

## The mode of this fixture
var _mode: String = ""

## Stores all active values per parameter
## { "zone": { "parameter": { value: float, function: String } } }
var _active_values: Dictionary[String, Dictionary]

## All the input value overrides as raw values
## { "zone": { "parameter": { "value": float, "function": String } } }
var _raw_override_layers: Dictionary[String, Dictionary] = {}

## The FixtureManifest for this fixture
var _manifest: FixtureManifest = null

## Stores all parameter subscriptions { "zone": { "parameter": Array[Callable] } }
var _parameter_subscriptions: Dictionary[String, Dictionary]


## init
func _init(p_uuid: String = UUID_Util.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("DMXFixture")
	_set_self_class("DMXFixture")
	
	_settings_manager.register_setting("channel", Data.Type.INT, set_channel, get_channel, [channel_changed]).set_min_max(1, 512)
	_settings_manager.register_setting("universe", Data.Type.ENGINECOMPONENT, set_universe, get_universe, [universe_changed]).set_class_filter(Universe)
	_settings_manager.register_setting("manifest", Data.Type.FIXTUREMANIFEST, set_manifest, get_manifest, [manifest_changed])
	_settings_manager.register_status("mode", Data.Type.STRING, get_mode, [mode_changed])
	
	_settings_manager.register_networked_callbacks({
		"on_channel_changed": _set_channel,
		"on_universe_changed": _set_universe,
		"on_manifest_changed": _set_manifest,
	})
	
	_settings_manager.set_callback_allow_unresolved("on_manifest_changed")


## Gets the channel
func get_channel() -> int:
	return _channel


## Gets the universe this fixture is patched to
func get_universe() -> Universe:
	return _universe


## Gets the FixtureManifest
func get_manifest() -> FixtureManifest:
	return _manifest


## Gets the manifest mode this fixture is in
func get_mode() -> String:
	return _mode


## Sets the channel
func set_channel(p_channel: int) -> Promise:
	return rpc("set_channel", [p_channel])


## Sets the universe
func set_universe(p_universe: Universe) -> Promise:
	return rpc("set_universe", [p_universe])


## Sets the FixtureManifest
func set_manifest(p_manifest: Variant, p_mode: String) -> Promise:
	if p_manifest is FixtureManifest:
		p_manifest = p_manifest.uuid()
	
	return rpc("set_manifest", [type_convert(p_manifest, TYPE_STRING), p_mode])


## Gets all the override values
func get_all_override_values() -> Dictionary:
	return _raw_override_layers.duplicate(true)


## Gets all the values
func get_all_values() -> Dictionary:
	return _active_values.duplicate(true)


## Gets all the parameters and there category from a zone
func get_parameter_categories(p_zone: String) -> Dictionary:
	return _manifest.get_categorys(_mode, p_zone)


## Gets all the parameter functions
func get_parameter_functions(p_zone: String, p_parameter: String) -> Array:
	return _manifest.get_parameter_functions(_mode, p_zone, p_parameter)


## Gets all the parameter functions
func get_function_control_type(p_zone: String, p_parameter: String, p_function: String) -> ControlType:
	return _manifest.function_control_type(_mode, p_zone, p_parameter, p_function)


## Gets the default value of a parameter
func get_default(p_zone: String, p_parameter: String, p_function: String = "", p_raw_dmx: bool = false) -> float:
	if p_function == "":
		p_function = get_default_function(p_zone, p_parameter)
	
	var dmx_value: int = _manifest.get_mode(_mode).zones[p_zone][p_parameter].functions[p_function].default
	var range: Array = _manifest.get_mode(_mode).zones[p_zone][p_parameter].functions[p_function].dmx_range
	
	if p_raw_dmx:
		return dmx_value
	else:
		return remap(dmx_value, range[0], range[1], 0.0, 1.0)


## Gets the default function for a zone and parameter, or the first function if none can be found
func get_default_function(p_zone: String, p_parameter: String) -> String:
	var default_function: String = _manifest.get_mode(_mode).zones[p_zone][p_parameter].default_function
	var functions: Dictionary = _manifest.get_mode(_mode).zones[p_zone][p_parameter].functions

	if functions.has(default_function):
		return default_function
	else:
		return functions.keys()[0]


## Gets the current value, or the default
func get_current_value(p_zone: String, p_parameter: String, p_allow_default: bool = true, p_allow_override: bool = true) -> float:
	if has_override(p_zone, p_parameter):
		return _raw_override_layers[p_zone][p_parameter].value
	else:
		return _active_values.get(p_zone, {}).get(p_parameter, {}).get("value", get_default(p_zone, p_parameter) if p_allow_default else 0.0)


## Gets the current function, or the default
func get_current_function(p_zone: String, p_parameter: String, p_allow_default: bool = true, p_allow_override: bool = true) -> String:
	if has_override(p_zone, p_parameter):
		return _raw_override_layers[p_zone][p_parameter].function
	else:
		return _active_values.get(p_zone, {}).get(p_parameter, {}).get("function", get_default_function(p_zone, p_parameter) if p_allow_default else "")


## Gets the current value, or the default
func get_current_value_or_force_default(p_zone: String, p_parameter: String) -> float:
	var value: float = _active_values.get(p_zone, {}).get(p_parameter, {}).get("value", -1)

	if value == -1:
		if has_force_default(p_parameter):
			return get_default(p_zone, p_parameter)
		else:
			return 0.0
	else:
		return value


## Gets all the zones
func get_zones() -> Array[String]:
	if not is_instance_valid(_manifest):
		return []
	
	return _manifest.get_zones(_mode)


## Checks if this DMXFixture has any overrides
func has_overrides() -> bool:
	return _raw_override_layers != {}


## Returns true if this Fixture has an override value
func has_override(p_zone: String, p_parameter: String) -> bool:
	return _raw_override_layers.has(p_zone) and _raw_override_layers[p_zone].has(p_parameter)


## Checks if this fixture has a parameter
func has_parameter(p_zone: String, p_parameter: String, p_function: String = "") -> bool:
	if not _manifest:
		return false
	
	if p_function:
		return _manifest.has_function(_mode, p_zone, p_parameter, p_function)
	else:
		return _manifest.has_parameter(_mode, p_zone, p_parameter)


## Checks if a parameter is a force default
func has_force_default(p_parameter: String) -> bool:
	return _manifest.has_force_default(p_parameter)


## Returns True if the given callable is subscribed to the given parameter
func has_parameter_subscription(p_zone: String, p_parameter: String, p_callable: Callable) -> bool:
	return _parameter_subscriptions.get(p_zone, {}).get(p_parameter, {}).has(p_callable)


## Checks if this DMXFixture has a function that can fade
func function_can_fade(p_zone: String, p_parameter: String, p_function: String) -> bool:
	return _manifest.function_can_fade(_mode, p_zone, p_parameter, p_function)


## Subscribes to a parameter on the given zone
func subscribe_to_parameter(p_zone: String, p_parameter: String, p_callable: Callable) -> bool:
	if has_parameter_subscription(p_zone, p_parameter, p_callable):
		return false
	
	_parameter_subscriptions.get_or_add(p_zone, {}).get_or_add(p_parameter, []).append(p_callable)
	return true


## Removes a subscription from the parameter in the given zone
func remove_subscription(p_zone: String, p_parameter: String, p_callable: Callable) -> bool:
	if not has_parameter_subscription(p_zone, p_parameter, p_callable):
		return false
	
	_parameter_subscriptions[p_zone][p_parameter].erase(p_callable)
	return true


## Internl: Sets the channel
func _set_channel(p_channel: int, p_no_signal: bool = false) -> void:
	_channel = p_channel
	
	if not p_no_signal:
		channel_changed.emit(_channel)


## Called when the universe is changed
func _set_universe(p_universe: Universe, p_no_signal: bool = false) -> void:
	_universe = p_universe
	
	if not p_no_signal:
		universe_changed.emit(_universe)


## Sets the FixtureManifest
func _set_manifest(p_manifest: Variant, p_mode: String, p_no_signal: bool = false) -> void:
	if p_manifest and p_manifest is String:
		FixtureLibrary.request_manifest(type_convert(p_manifest, TYPE_STRING)).then(_set_manifest.bind(p_mode))
		return
	
	elif not is_instance_valid(p_manifest):
		return
	
	_mode = p_mode
	_manifest = p_manifest
	
	if not p_no_signal:
		manifest_changed.emit(_manifest, _mode)
		mode_changed.emit(_mode)


## Internal: Sets a parameter to a float value
func _set_parameter(p_zone: String, p_parameter: String, p_function: String, p_value: Variant) -> void:
	_active_values.get_or_add(p_zone, {})[p_parameter] = {"value": p_value, "function": p_function}
	parameter_changed.emit(p_zone, p_parameter, p_function, p_value)
	
	if has_override(p_zone, p_parameter):
		return
	
	_emit_parameter_subs(p_zone, p_parameter, p_function, p_value, false)


## Internal: Erases the parameter on the given layer
func _erase_parameter(p_zone: String, p_parameter: String) -> void:
	_active_values.get_or_add(p_zone, {}).erase(p_parameter)
	parameter_erased.emit(p_parameter, p_zone)
	
	if has_override(p_zone, p_parameter):
		return
	
	_emit_parameter_subs(p_zone, p_parameter, get_default_function(p_zone, p_parameter), get_default(p_zone, p_parameter), false)


## Internal: Sets a parameter override to a float value
func _set_override(p_zone: String, p_parameter: String, p_function: String, p_value: float) -> void:
	_raw_override_layers.get_or_add(p_zone, {})[p_parameter] = {"value": p_value, "function": p_function}
	override_changed.emit(p_zone, p_parameter, p_function, p_value)
	
	_emit_parameter_subs(p_zone, p_parameter, p_function, p_value, true)


## Internal: Erases the parameter override 
func _erase_override(p_zone: String, p_parameter: String) -> void:
	if _raw_override_layers.get_or_add(p_zone, {}).erase(p_parameter) and not _raw_override_layers[p_zone]:
		_raw_override_layers.erase(p_zone)
		
	override_erased.emit(p_zone, p_parameter)
	
	_emit_parameter_subs(p_zone, p_parameter, get_current_function(p_zone, p_parameter), get_current_value(p_zone, p_parameter), false)


## Calls back all parameter subscripptions
func _emit_parameter_subs(p_zone: String, p_parameter: String, p_function: String, p_value: float, p_override: bool) -> void:
	for callable: Callable in _parameter_subscriptions.get(p_zone, {}).get(p_parameter, []).duplicate():
		if not callable.is_valid():
			_parameter_subscriptions[p_zone][p_parameter].erase(callable)
		else:
			callable.call(p_value, p_function, p_override)


## Internal: Erases all overrides
func _erase_all_overrides() -> void:
	_raw_override_layers.clear()
	all_override_removed.emit()


## Saves this DMXFixture to a dictonary
func serialize() -> Dictionary:
	return super.serialize().merged({
		 "channel": _channel
	})


## Loads this DMXFixture from a dictonary
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	_channel = type_convert(p_serialized_data.get("channel"), TYPE_INT)
	_set_manifest(type_convert(p_serialized_data.get("manifest_uuid"), TYPE_STRING), type_convert(p_serialized_data.get("mode", ""), TYPE_STRING), true)
	
	_raw_override_layers = Dictionary(type_convert(p_serialized_data.get("raw_override_layers", {}), TYPE_DICTIONARY), TYPE_STRING, "", null, TYPE_DICTIONARY, "", null)
	_active_values = Dictionary(type_convert(p_serialized_data.get("active_values", {}), TYPE_DICTIONARY), TYPE_STRING, "", null, TYPE_DICTIONARY, "", null)
