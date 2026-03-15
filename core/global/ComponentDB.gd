# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name EngineComponentDB extends ObjectDB
## Extends ObjectDB to auto add and remove components from NetworkManager


## init
func _init() -> void:
	component_added.connect(func (p_component: EngineComponent):
		Network.register_network_object(p_component.get_uuid(), p_component.get_settings())
	)
	
	component_removed.connect(func (p_component: EngineComponent):
		Network.deregister_network_object(p_component.get_settings())
	)


## Returns true if the given component is allowed in this ObjectDB
func is_component_allowed(p_component: Object) -> bool:
	return p_component is EngineComponent
