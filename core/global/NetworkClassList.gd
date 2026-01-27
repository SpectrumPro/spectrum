# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name NetworkItemClassList extends ClassListDB
## Contains a list of all the classes that can be networked, stored here so they can be found when deserializing a network request


## Init
func _init() -> void:
	_global_class_tree = {
		"NetworkItem": {
			"NetworkHandler": {
				"Constellation": Constellation,
				"NetworkHandler": NetworkHandler
			},
			"NetworkSession": {
				"NetworkSession": NetworkSession,
				"ConstellationSession": ConstellationSession
			},
			"NetworkNode": {
				"NetworkNode": NetworkNode,
				"ConstellationNode": ConstellationNode,
			},
			"NetworkItem": NetworkItem
		}
	}
