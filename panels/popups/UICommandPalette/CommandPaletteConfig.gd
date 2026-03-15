# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CommandPaletteEntry extends Object
## A configuration for items shown in the CommandPalette.


## Reference to the settings manager when _object_type is GLOBAL.
var _settings: SettingsManager

## The class name for the class
var _class_name: String = ""


## Init
func _init(p_settings_manager: SettingsManager, p_class_name: String) -> void:
	_settings = p_settings_manager
	_class_name = p_class_name


## Gets the settings manager
func get_settings_manager() -> SettingsManager:
	return _settings


## Gets the class name
func get_class_name() -> String:
	return _class_name


## Sets the settings manager
func set_settings_manager(p_settings_manager: SettingsManager) -> CommandPaletteEntry:
	_settings = p_settings_manager
	return self


## Sets the class name
func set_class_name(p_class_name: String) -> CommandPaletteEntry:
	_class_name = p_class_name
	return self
