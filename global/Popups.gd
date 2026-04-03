# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name InterfacePopups extends CorePopups
## Collection of shortcuts for opening UIPopups


## init 
func _init() -> void:
	super._init()
	
	_settings.register_control("OpenMainMenu", Data.Type.ACTION, MainMenu.bind(self), Callable(), [])
	_settings.register_control("OpenSettings", Data.Type.ACTION, Settings.bind(self), Callable(), [])
	_settings.register_control("OpenSaveLoad", Data.Type.ACTION, SaveLoad.bind(self), Callable(), [])
	_settings.register_control("ComponentSettings", Data.Type.ACTION, search_component_then_settings.bind(self))
	_settings.register_control("CreateComponent", Data.Type.ACTION, create_component_then_rename.bind(self))


## Shows UIMainMenue
func MainMenu(p_source: Node) -> Promise:
	return Interface.show_window_popup(UIMainMenu, p_source, null)


## Shows UISettings
func Settings(p_source: Node) -> Promise:
	return Interface.show_window_popup(UISettings, p_source, null)


## Shows UISaveLoad
func SaveLoad(p_source: Node) -> Promise:
	return Interface.show_window_popup(UISaveLoad, p_source, null)


## Prompts the user with UIManifestPicker
func ManifestSelector(p_source: Node) -> Promise:
	var promise: Promise = Interface.show_window_popup(UIManifestSelector, p_source, null)
	
	return promise


## Prompts the user with UIParameterFunctionList
func ParameterList(p_source: Node, p_fixtures: Array[Fixture]) -> Promise:
	(Interface.get_window_popup(UIParameterList, p_source) as UIParameterList).search_mode_combined(p_fixtures)
	return Interface.show_window_popup(UIParameterList, p_source, null)


## Prompts the user with UIParameterFunctionList
func ParameterList_zone(p_source: Node, p_fixtures: Array[Fixture]) -> Promise:
	(Interface.get_window_popup(UIParameterList, p_source) as UIParameterList).search_mode_zone(p_fixtures)
	return Interface.show_window_popup(UIParameterList, p_source, null)


## Prompts the user with UIParameterFunctionList
func ParameterList_zone_parameter(p_source: Node, p_fixtures: Array[Fixture]) -> Promise:
	(Interface.get_window_popup(UIParameterList, p_source) as UIParameterList).search_mode_zone_parameter(p_fixtures)
	return Interface.show_window_popup(UIParameterList, p_source, null)


## Prompts the user with UIParameterFunctionList
func ParameterList_parameter(p_source: Node, p_fixtures: Array[Fixture], p_zone: String) -> Promise:
	(Interface.get_window_popup(UIParameterList, p_source) as UIParameterList).search_mode_parameter(p_fixtures, p_zone)
	return Interface.show_window_popup(UIParameterList, p_source, null)


## Prompts the user with UIParameterFunctionList
func ParameterList_function(p_source: Node, p_fixtures: Array[Fixture], p_zone: String, p_parameter: String) -> Promise:
	(Interface.get_window_popup(UIParameterList, p_source) as UIParameterList).search_mode_function(p_fixtures, p_zone, p_parameter)
	return Interface.show_window_popup(UIParameterList, p_source, null)


## Prompts the user with UIObjectPicker, creates the component, and Prompts the user with the name dialog
func create_component_then_rename(p_source: Node) -> Promise:
	return ObjectSelector_class(p_source, EngineComponent, "EngineComponent").then(func (p_classname: String):
		Core.create_component(p_classname).then(func (p_component: EngineComponent):
			show_settings_module(p_source, p_component.get_settings().get_entry("name"))
		)
	)


## Prompts the user with UIObjectPicker to search for a component to view settings for
func search_component_then_settings(p_source: Node) -> Promise:
	return ObjectSelector(p_source, EngineComponent, EngineComponent).then(func (p_component: EngineComponent):
		ComponentSettings(p_source, p_component)
	)
