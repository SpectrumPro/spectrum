# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CoreProgrammer extends Node
## Engine class for programming lights, colors, positions, etc.


## Emitted when the programmer is cleared
signal cleared()


## Save Modes
enum SaveMode {
	MODIFIED,		## Only save fixtures that have been changed in the programmer
	ALL,			## Save all values of the fixtures
	ALL_NONE_ZERO	## Save all values of the fixtures, as long as they are not the zero value for that channel
}

## Random parameter modes
enum RandomMode {
	All,			## Sets all fixture's parameter to the same random value
	Individual		## Uses a differnt random value for each fixture
}

## Mix Mode 
enum MixMode {
	Additive,		## Uses Additive Mixing
	Subtractive		## Uses Subtractive Mixing
}

## Enum for Category
enum Category {
	DIMMER,
	COLOR,
	GOBO,
	POSITION,
	BEAM,
	FOCUS,
	SHAPERS,
	CONTROL,
	OTHER,
}

## Enum for Layer
enum Layer {
	VALUE,
	START,
	STOP,
	CANFADE
}


## Stores the order of all parameters
var _parameter_order: Dictionary[Category, Variant] = {
	Category.DIMMER: 	["Dimmer"],
	Category.COLOR: 	[
		"ColorAdd_R", "ColorAdd_G", "ColorAdd_B", 
		"ColorAdd_W", "ColorSub_R", "ColorSub_G", "ColorSub_B", "ColorSub_C", "ColorSub_M", "ColorSub_Y", 
		"ColorRGB_Red", "ColorRGB_Green", "ColorRGB_Blue",
		"CTC", "Color"
	],
	Category.POSITION: 	["Pan", "Tilt"]
}


## Current store mode state
var _store_mode_state: bool = false

## Callback for store mode
var _store_mode_callback: Callable

## The SettingsManager for this Programmer
var settings_manager: SettingsManager = SettingsManager.new()


## init
func _init() -> void:
	settings_manager.set_owner(self)
	settings_manager.set_inheritance_array(["Programmer"])
	
	settings_manager.register_networked_callbacks({
		"on_cleared": _clear,
	})
	
	_convert_order_array_to_dict()


## Gets a Category enum as a string
func get_category_as_string(p_category: Category) -> String:
	return Category.keys()[p_category].capitalize()


## Gets a Category from a string
func get_category_from_string(p_category: String) -> Category:
	var index: int = Category.keys().find(p_category.to_upper())
	
	return (index as Category) if index != -1 else Category.OTHER


## Gets the order index of a given parameter, or -1
func get_parameter_index(p_category: Category, p_parameter: String) -> int:
	var number_result: Dictionary = Utils.remove_numbers(p_parameter)
	var index: int = _parameter_order.get(p_category, {}).get(number_result.string, -1)
	
	if number_result.numbers:
		index += number_result.numbers[0]
	
	return index


## Clears the programmer
func clear() -> Promise: 
	return Network.send_command("Programmer", "clear")


## Function to set the fixture data at the given chanel key
func set_parameter(p_fixtures: Array, p_parameter: String, p_function: String, p_value: float, p_zone: String) -> Promise:
	return Network.send_command("Programmer", "set_parameter", [p_fixtures, p_parameter, p_function, p_value, p_zone])


## Sets a fixture parameter to a random value
func set_parameter_random(p_fixtures: Array, p_parameter: String, p_function: String, p_zone: String, p_mode: RandomMode) -> Promise:
	return Network.send_command("Programmer", "set_parameter_random", [p_fixtures, p_parameter, p_function, p_zone, p_mode])


## Erases a parameter
func erase_parameter(p_fixtures: Array, p_parameter: String, p_zone: String) -> Promise:
	return Network.send_command("Programmer", "erase_parameter", [p_fixtures, p_parameter, p_zone])


## Shortcut to set the color of fixtures
func shortcut_set_color(p_fixtures: Array, p_color: Color, p_mode: MixMode) -> Promise:
	return Network.send_command("Programmer", "shortcut_set_color", [p_fixtures, p_color, p_mode])


## Converts the parameter order array to a dictonary for faster lookup
func _convert_order_array_to_dict() -> void:
	for category: Category in _parameter_order:
		var array_order: Array = _parameter_order[category]
		var dict_order: Dictionary[String, int]
		
		for index: int in range(0, array_order.size()):
			dict_order[array_order[index]] = index
		
		_parameter_order[category] = dict_order


## Called when the programmer is cleared on the server
func _clear() -> void:
	cleared.emit()
