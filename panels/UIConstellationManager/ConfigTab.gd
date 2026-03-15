# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIConstellationManagerConfigTab extends PanelContainer
## UIConstellationManagerConfigTab


## The SettingsManagerView
@export var _settings_manager_view: SettingsManagerView

## The Constellation network instance
var _constellation: Constellation

## The Constellation Local Node
var _local_node: ConstellationNode


## Ready
func _ready() -> void:
	_constellation = Network.get_active_handler_by_name("Constellation")
	_local_node = _constellation.get_local_node()
	
	_settings_manager_view.set_manager(_local_node.get_settings())
