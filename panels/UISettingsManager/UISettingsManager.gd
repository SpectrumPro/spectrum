# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UISettingsManager extends UIPanel
## UISettingsManager


## The ComponentButton
@export var component_button: ComponentButton

## The SettingsManagerView
@export var settings_manager_view: SettingsManagerView


## The current selected component
var _manager: SettingsManager


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIComponentSettings")


## Sets the component
func set_manager(p_manager: SettingsManager) -> void:
	_manager = p_manager
	component_button.set_text(_manager.get_inheritance_child())
	
	if not is_instance_valid(_manager):
		settings_manager_view.reset()
		return
	
	settings_manager_view.set_manager(_manager)


## Gets the current component
func get_component() -> SettingsManager:
	return _manager
