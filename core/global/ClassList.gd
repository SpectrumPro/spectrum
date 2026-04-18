# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CoreComponentClassList extends CoreClassListDB
## Contains a list of all the classes that can be networked, stored here so they can be found when deserializing a network request


## Init
func _init(p_uuid: String = "", ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("CoreComponentClassList")
	
	_global_class_tree = {
		"EngineComponent": {
			"DataContainer": {
				"Cue": Cue,
				"DataContainer": DataContainer,
				"DataPaletteItem": DataPaletteItem,
			},
			"Fixture": {
				"Fixture": Fixture,
				"DMXFixture": DMXFixture
			},
			"Function": {
				"CueList": CueList,
				"DataPalette": DataPalette,
				"Function": Function,
				"Scene": Scene,
				"FunctionGroup": FunctionGroup
			},
			"DMXOutput": {
				"ArtNetOutput": ArtNetOutput,
				"DMXOutput": DMXOutput,
			},
			"ContainerItem": ContainerItem,
			"EngineComponent": EngineComponent,
			"FixtureGroup": FixtureGroup,
			"FixtureGroupItem": FixtureGroupItem,
			"FixtureManifest": FixtureManifest,
			"TriggerBlock": TriggerBlock,
			"Universe": Universe,
		}
	}
	
	_hidden_classes = [
		"Cue",
		"FixtureGroupItem",
		"DataContainer",
		"DataPaletteItem",
		"FixtureManifest",
		"ContainerItem"
	]
	
	_always_searlize_classes = [
		"ContainerItem"
	]
