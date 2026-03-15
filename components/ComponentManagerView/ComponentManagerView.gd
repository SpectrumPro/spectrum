# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ComponentManagerView extends UIComponent
## ComponentManagerView


## Emitted when the create button is pressed and a classname is selected
signal create_requested(classname: String)

## Emitted when the duplicate button is pressed
signal duplicate_requested(component: EngineComponent)


## Enum for mode
enum Mode {
	STANDALONE, 	## Standalone mode operates using ComponentDB for global components
	MANUAL,			## MANUAL mode operates on subcomponents of a EngineComponent
}


## The EngineComponent classname to use
@export var classname: String

## Table columns made up of SettingsManager
@export var table_column_names: Array[String]

## The current Mode
@export var component_mode: Mode = Mode.STANDALONE

## Nodes group
@export_group("Nodes")

## The SettingsManagerMultiView
@export var settings_manager_multi_view: SettingsManagerMultiView

## The NewComponent Button
@export var new_button: Button

## The DeleteComponent Button
@export var delete_button: Button

## The DuplicateComponent Button
@export var duplicate_button: Button


## Current mode
var _mode: Mode = Mode.STANDALONE


## init
func _init() -> void:
	super._init()
	
	_set_class_name("ComponentManagerView")


## Ready
func _ready() -> void:
	settings_manager_multi_view.manager_selected.connect(_on_manager_selected)
	new_button.pressed.connect(_on_new_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	
	delete_button.set_disabled(true)
	duplicate_button.set_disabled(true)
	
	set_mode(component_mode)


## Sets the Mode to Mode.STANDALONG
func set_mode(p_mode: Mode) -> void:
	_mode = p_mode
	
	reset()
	
	match _mode:
		Mode.STANDALONE:
			ComponentDB.request_class_callback(classname, class_callback)
			class_callback(ComponentDB.get_components_by_classname(classname), [])
		Mode.MANUAL:
			ComponentDB.remove_class_callback(classname, class_callback)


## Resets the UI
func reset() -> void:
	settings_manager_multi_view.table_column_names = table_column_names.duplicate()
	settings_manager_multi_view.reset()


## Called each time a Universe is added or removed from ComponentDB
func class_callback(p_added: Array, p_removed: Array) -> void:
	for component: EngineComponent in p_added:
		settings_manager_multi_view.add_manager(component.get_settings())
	
	for component: EngineComponent in p_removed:
		settings_manager_multi_view.remove_manager(component.get_settings())


## Called when a SettingsManager is selected
func _on_manager_selected(p_manager: SettingsManager) -> void:
	var state: bool = is_instance_valid(p_manager)
	
	delete_button.set_disabled(not state)
	duplicate_button.set_disabled(not state)


## Called when the NewComponent Button is pressed
func _on_new_button_pressed() -> void:
	Popups.ObjectPicker_class(self, classname).then(func (p_classname: String):
		match _mode:
			Mode.STANDALONE:
				Core.create_component(p_classname).then(func (p_component: EngineComponent):
					if not is_instance_valid(p_component):
						return
					
					Popups.show_settings_module(self, p_component.get_settings().get_entry("name"))
				)
			Mode.MANUAL:
				create_requested.emit(p_classname)
	)


## Called when the DeleteComponent Button is presse
func _on_delete_button_pressed() -> void:
	settings_manager_multi_view.get_selected_manager().get_owner().delete_rpc()


## Called when the DuplicateComponent Button is pressed
func _on_duplicate_button_pressed() -> void:
	match _mode:
		Mode.STANDALONE:
			Core.duplicate_component(settings_manager_multi_view.get_selected_manager().get_owner())
		Mode.MANUAL:
			duplicate_requested.emit(settings_manager_multi_view.get_selected_manager().get_owner())
