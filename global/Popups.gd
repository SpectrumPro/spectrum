# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name InterfacePopups extends Node
## Collection of shortcuts for opening UIPopups


## The SettingsManager for this IntefacePopups object
var _settings: SettingsManager = SettingsManager.new()


## init 
func _init() -> void:
	_settings.set_owner(self)
	_settings.set_inheritance_array(["Popups"])
	
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


## Prompts the user to select a UIPanel
func PanelSelector(p_source: Node) -> Promise:
	return Interface.show_window_popup(UIPanelSelector, p_source, null)


## Promps the user with UIPaneSettings
func PanelSettings(p_source: Node, p_panel: UIPanel) -> Promise:
	return Interface.show_window_popup(UIPanelSettings, p_source, p_panel)


## Promps the user with UIComponentSettings
func ComponentSettings(p_source: Node, p_component: EngineComponent) -> Promise:
	return Interface.show_window_popup(UIComponentSettings, p_source, p_component)


## Promps the user with UIPaneSettings
func ObjectSelector(p_source: Node, p_index: Script, p_class_filter: Variant) -> Promise:
	var promise: Promise = Interface.show_window_popup(UIObjectSelector, p_source, null)
	var object_picker: UIObjectSelector = promise.get_object_refernce()
	
	if p_class_filter is Script:
		p_class_filter = p_class_filter.get_global_name()
	
	p_class_filter = type_convert(p_class_filter, TYPE_STRING)
	
	object_picker.set_select_mode(UIObjectSelector.SelectMode.OBJECT)
	object_picker.set_index(p_index, p_class_filter)
	
	return promise


## Promps the user with UIObjectPicker
func ObjectSelector_class(p_source: Node, p_class_filter: String) -> Promise:
	var promise: Promise = Interface.show_window_popup(UIObjectSelector, p_source, null)
	var object_picker: UIObjectSelector = promise.get_object_refernce()
	
	object_picker.set_select_mode(UIObjectSelector.SelectMode.CLASS)
	object_picker.set_index(EngineComponent, p_class_filter)
	
	return promise


## Prompts the user with UIManifestPicker
func ManifestSelector(p_source: Node) -> Promise:
	var promise: Promise = Interface.show_window_popup(UIManifestSelector, p_source, null)
	
	return promise


## Prompts the user with UIInterfaceSelector
func NetworkSelector(p_source: Node) -> Promise:
	var promise: Promise = Interface.show_window_popup(UINetworkSelector, p_source, null)
	
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


## Creates and adds a blank UIPopupDialog
func PopupDialog(p_source: Node, p_title: String = "") -> UIPopupDialog:
	return Interface.create_popup_dialog(p_source, p_title)


## Prompts the user with UIObjectPicker, creates the component, and Prompts the user with the name dialog
func create_component_then_rename(p_source: Node) -> Promise:
	return ObjectSelector_class(p_source, "EngineComponent").then(func (p_classname: String):
		Core.create_component(p_classname).then(func (p_component: EngineComponent):
			show_settings_module(p_source, p_component.get_settings().get_entry("name"))
		)
	)


## Prompts the user with UISettingsManager
func show_settings_manager(p_source: Node, p_manager: SettingsManager) -> void:
	Interface.show_window_popup(UISettingsManager, p_source, p_manager)


## Promps the user with SettingsModule
func show_settings_module(p_source: Node, p_modules: Variant) -> Promise:
	return Interface.show_window_popup(UIPopupSettingsModule, p_source, p_modules)


## Promps the user with a DataInput
func show_data_input(p_source: Node, p_data_type: Data.Type, p_default: Variant, p_label: String) -> Promise:
	var promise: Promise = Interface.show_window_popup(UIPopupSettingsModule, p_source, null)
	var module_view: UIPopupSettingsModule = promise.get_object_refernce()
	var dummy_module: SettingsModule = SettingsModule.new(p_label, p_label, p_data_type, SettingsModule.Type.SETTING, promise.resolvev, func (): return p_default, [], p_source)
	
	module_view.set_module(dummy_module)
	module_view.focus()
	return promise


## Prompts the user with a delete confirmation dialog
func show_delete_confirmation(p_source: Node, p_title: String = "Confirm Deletion?") -> Promise:
	return PopupDialog(p_source, p_title).preset(UIPopupDialog.Preset.DELETE, p_title).promise()


## Prompts the user to delete the given engine components
func confirm_delete_components(p_source: Node, p_components: Array, p_auto_delete: bool = true) -> Promise:
	var title: PackedStringArray
	title.append("Delete")
	
	if p_components.size() > 1:
		title.append(": " + str(p_components.size()) + " Components?")
	elif p_components.size() and p_components[0] is EngineComponent:
		title.append(" Selected " + p_components[0].get_class_name() + "?")
	else:
		return
	
	return PopupDialog(p_source, "").preset(UIPopupDialog.Preset.DELETE, "".join(title)).promise().then(func ():
		if not p_auto_delete:
			return
		
		for component: Variant in p_components:
			if not component is EngineComponent:
				continue
			
			component.delete_rpc()
	)


## Prompts the user with a custom panel popup
func create_panel_popup(p_source: Node, p_panel_class: Variant) -> UIPanel:
	return Interface.create_panel_popup(p_source, p_panel_class)


## Prompts the user with UIObjectPicker to search for a component to view settings for
func search_component_then_settings(p_source: Node) -> Promise:
	return ObjectSelector(p_source, EngineComponent, EngineComponent).then(func (p_component: EngineComponent):
		ComponentSettings(p_source, p_component)
	)


## Returns the SettingsManager for this InterfacePopups object
func get_settings() -> SettingsManager:
	return _settings
