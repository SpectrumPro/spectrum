# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name EngineComponentDB extends ObjectDB
## Extends ObjectDB to auto add and remove components from NetworkManager


## init
func _init() -> void:
	components_added.connect(func (p_components: Array):
		for component: EngineComponent in p_components:
			Network.register_network_object(component.get_uuid(), component.get_settings())
	)
	
	components_removed.connect(func (p_components: Array):
		for component: EngineComponent in p_components:
			Network.deregister_network_object(component.get_settings())
	)


## Returns true if the given component is allowed in this ObjectDB
func is_component_allowed(p_component: Object) -> bool:
	return p_component is EngineComponent
