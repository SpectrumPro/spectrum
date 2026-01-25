# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIComponentSettings extends UIPanel
## UIComponentSettings


## The ComponentButton
@export var component_button: ComponentButton

## The SettingsManagerView
@export var settings_manager_view: SettingsManagerView


## The current selected component
var _component: EngineComponent


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIComponentSettings")


## Sets the component
func set_component(p_component: EngineComponent) -> void:
	_component = p_component
	component_button.set_component(_component)
	
	if not is_instance_valid(_component):
		settings_manager_view.reset()
		return
	
	settings_manager_view.set_manager(_component.settings())


## Gets the current component
func get_component() -> EngineComponent:
	return _component
