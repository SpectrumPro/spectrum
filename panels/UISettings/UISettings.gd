# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.


class_name UISetting extends UIPanel
## Settings Panel


## Container for tab buttons
@export var _tab_button_container: HBoxContainer

## The SettingsManagerView for Interface settings
@export var _interface_settings: SettingsManagerView

## Enum for each tab
enum Tab {InterfaceSettings, ServerSettings, NetworkManager, Shortcuts}


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UISettings")


## ready
func _ready() -> void:
	_interface_settings.set_manager(Interface.get_settings())


## Switched to the given tab
func switch_to_tab(p_tab: Tab) -> void:
	_tab_button_container.get_child(p_tab).button_pressed = true
