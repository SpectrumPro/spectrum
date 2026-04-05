# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIFunctions extends UIPanel
## GUI element for managing Functions


## The ComponentManagerView
@onready var _component_manager: ComponentManagerView = %ComponentManagerView


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIFunctions")


## ready
func _ready() -> void:
	super._ready()
	
	_component_manager.set_new_button(%NewComponent)
	_component_manager.set_delete_button(%DeleteComponent)
	_component_manager.set_duplicate_button(%DuplicateComponent)
	_component_manager.mode_gbc_index("EngineComponent", "Function")
