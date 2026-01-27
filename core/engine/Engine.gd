# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CoreEngine extends Node
## The client side engine that powers Spectrum


## Emitted when components are added to the engine
signal components_added(components: Array[EngineComponent])

## Emitted when components are removed from the engine
signal components_removed(components: Array[EngineComponent])

## Emitted when this engine is about to reset
signal resetting()

## Emitted when the client is synchronizing with the server
signal synchronizing()

## Emited when the file name is changed
signal file_name_changed()

## Emitted when this engine has finished loading
signal load_finished()


## The current file name
var _current_file_name: String = ""

## The EngineConfig
var _config: EngineConfig

## The SettingsManager for CoreEngine
var _settings_manager: SettingsManager = SettingsManager.new()


## Internal engine config options
class EngineConfig extends Object:
	## Network objects will be auto added to the servers networked objects index
	var network_objects: Array[Dictionary] = [
		{
			"object": (Core),
			"name": "engine"
		},
		{
			"object": (Programmer),
			"name": "Programmer"
		},
		{
			"object": (FixtureLibrary),
			"name": "FixtureLibrary"
		},
		{
			"object": (CIDManager),
			"name": "CIDManager"
		},
	]
	
	## Root classes are the primary classes that will be seralized and loaded 
	var root_classes: Array[String] = [
		"Fixture",
		"Universe",
		"Function",
		"FixtureGroup",
		"TriggerBlock"
	]


## Init
func _init() -> void:
	OS.set_low_processor_usage_mode(false)
	Details.print_startup_detils()
	
	_settings_manager.set_owner(self)
	_settings_manager.set_inheritance_array(["CoreEngine"])
	_settings_manager.register_networked_callbacks({
		"on_components_added": _add_components,
		"on_components_removed": _remove_components,
		"on_resetting": _reset,
		"on_file_name_changed": _set_file_name,
	})
	
	_settings_manager.set_callback_allow_deserialize("on_components_added")


## Init
func _ready() -> void:
	_config = EngineConfig.new()
	
	Network.start_all()
	
	(Network.get_active_handler_by_name("Constellation").get_local_node() as ConstellationNode).connected_to_session_master.connect(_load_from_server)
	_add_auto_network_classes.call_deferred()


## Gets the SettingsManager
func settings() -> SettingsManager:
	return _settings_manager


## Returns a serialized copy of the engine from the server
func serialize() -> Promise: 
	return Network.send_command("engine", "serialize")


## Saves this file to disk on the server
func save_to_file(file_name: String = _current_file_name) -> Promise: 
	return Network.send_command("engine", "save_to_file", [file_name])


## Loads a file on the server
func load_from_file(file_name: String) -> Promise: 
	return Network.send_command("engine", "load_from_file", [file_name])


## Resets and loads from a new file
func reset_and_load(file_name: String) -> Promise:
	return Network.send_command("engine", "reset_and_load", [file_name])


## Gets all the save files from the library
func get_all_saves_from_library() -> Promise: 
	return Network.send_command("engine", "get_all_saves_from_library")


## Gets the current file name
func get_file_name() -> String: 
	return _current_file_name


## Sets the current file name, this does not change the name of the file on disk, only in memory
func set_file_name(p_file_name: String) -> Promise:
	return Network.send_command("engine", "set_file_name", [p_file_name])


## Renames a save file
func rename_file(p_orignal_name: String, p_new_name: String) -> Promise:
	return Network.send_command("engine", "rename_file", [p_orignal_name, p_new_name])


## Deletes a save file
func delete_file(p_file_name: String) -> Promise:
	return Network.send_command("engine", "delete_file", [p_file_name])


## Resets the server engine to the default state
func reset() -> Promise: 
	return Network.send_command("engine", "reset")


## Creates and adds a new component using the classname to get the type, will return null if the class is not found
func create_component(p_classname: String, p_name: String = "") -> Promise: 
	return Network.send_command("engine", "create_component", [p_classname, p_name])


## Duplicates a component
func duplicate_component(p_component: EngineComponent) -> Promise: 
	return Network.send_command("engine", "duplicate_component", [p_component])


## Server: Adds a component to the engine
func add_component(p_component: EngineComponent) -> Promise: 
	return Network.send_command("engine", "add_component", [p_component])


## Server: Adds mutiple componets to this engine at once
func add_components(p_components: Array[EngineComponent]) -> Promise: 
	return Network.send_command("engine", "add_components", [p_components])


## Server: Removes a component from this engine
func remove_component(p_component: EngineComponent) -> Promise: 
	return Network.send_command("engine", "remove_component", [p_component])


## Server: Removes mutiple components at once
func remove_components(p_components: Array[EngineComponent]) -> Promise: 
	return Network.send_command("engine", "remove_components", [p_components])


## Internal: Adds a new component to this engine
func _add_component(p_component: EngineComponent, p_no_signal: bool = false) -> bool:
	
	# Check if this component is not already apart of this engine
	if not ComponentDB.has_component(p_component):
		ComponentDB.register_component(p_component)
		
		if not p_no_signal:
			components_added.emit([p_component])
		
		return true
		
	else:
		print("Component: ", p_component.uuid, " is already in this engine")
		return false


## Internal: Adds mutiple components to this engine at once
func _add_components(p_components: Array, p_no_signal: bool = false) -> Array[EngineComponent]:
	var just_added_components: Array[EngineComponent]
	
	# Loop though all the components requeted, and check there type
	for component: Variant in p_components:
		if component is EngineComponent and _add_component(component):
			just_added_components.append(component)
	
	if not p_no_signal and just_added_components:
		components_added.emit(just_added_components)
	
	return just_added_components


## Internal: Removes a universe from this engine
func _remove_component(p_component: EngineComponent, p_no_signal: bool = false) -> bool:
	# Check if this universe is part of this engine
	if ComponentDB.has_component(p_component):
		ComponentDB.deregister_component(p_component)
		
		if not p_no_signal:
			components_removed.emit([p_component])
		
		return true
		
	# If not return false
	else:
		print("Component: ", p_component.uuid, " is not part of this engine")
		return false


## Internal: Removes mutiple universes at once from this engine
func _remove_components(p_components: Array, p_no_signal: bool = false) -> void:
	var just_removed_components: Array = []
	
	for component in p_components:
		if component is EngineComponent and _remove_component(component, true):
			just_removed_components.append(component)
	
	if not p_no_signal and just_removed_components:
		components_removed.emit(just_removed_components)


## Adds all objects from _config.network_objects to the Network
func _add_auto_network_classes() -> void:
	for config: Dictionary in _config.network_objects:
		Network.register_network_object(config.name, config.object.settings())


## Requests the current state from the server and loads it localy
func _load_from_server(...p_args) -> void:
	_reset()
	synchronizing.emit()
	Network.send_command("engine", "serialize", []).then(func (responce: Dictionary):
		_load_from(responce)
	)


## Loads this engine from serialized data
func _load_from(serialized_data: Dictionary) -> void:
	_set_file_name(str(serialized_data.get("file_name", "")))

	# Array to keep track of all the components that have just been added, allowing them all to be networked to the client in the same message
	var just_added_components: Array[EngineComponent] = []

	# Loops throught all the classes we have been told to seralize, and check if they are present in the saved data
	for object_class_name: String in _config.root_classes:
		for component_uuid: String in serialized_data.get(object_class_name, {}):
			var serialized_component: Dictionary = serialized_data[object_class_name][component_uuid]
			var classname: String = type_convert(serialized_component.get("class_name", ""), TYPE_STRING)

			# Check if the components class name is a valid class type in the engine
			if not ClassList.has_class(classname):
				continue
			
			var new_component: EngineComponent = ClassList.get_class_script(serialized_component.class_name).new(component_uuid)
			new_component.deserialize(serialized_component)
			
			if _add_component(new_component, true):
				just_added_components.append(new_component)
	
	components_added.emit.call_deferred(just_added_components)
	load_finished.emit()


## Sets the current file name
func _set_file_name(p_file_name: String) -> void:
	_current_file_name = p_file_name
	file_name_changed.emit(_current_file_name)


## Internal: Resets this engine to its default state
func _reset():
	print("Performing Engine Reset!")
	_set_file_name("")
	resetting.emit()  
	
	for object_class_name: String in _config.root_classes:
		for component: EngineComponent in ComponentDB.get_components_by_classname(object_class_name):
			component.delete()
