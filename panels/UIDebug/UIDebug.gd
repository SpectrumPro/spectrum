# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIDebug extends UIPanel
## UI Panel use for debugging


## Message for object input
@export var message_for: LineEdit

## Message object method
@export var message_method: LineEdit

## Message method args
@export var message_args: LineEdit

## OptionButton for the local / remote option
@export var local_remote_option: OptionButton


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIDebug")


## Sets the text in the output
func set_output(output: Variant) -> void:
	var result: String = ""
	
	if output is Dictionary:
		result = JSON.stringify(output, "\t")
	else:
		result = str(output)
	
	$VBoxContainer/PanelContainer/HBoxContainer/Output.text = result


## Saves this panel into a dictonary
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"message": {
			"for": message_for.text,
			"method": message_method.text,
			"args": message_args.text
		}
	})


## Loads this panel from a dictonary
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	var message: Dictionary = type_convert(p_serialized_data.get("message", {}), TYPE_DICTIONARY)
	
	message_for.text = type_convert(message.get("for", {}), TYPE_STRING)
	message_method.text = type_convert(message.get("method", {}), TYPE_STRING)
	message_args.text = type_convert(message.get("args", {}), TYPE_STRING)


## Resets the engine
func _on_reset_pressed() -> void: Network.send_command("debug", "reset")

## Quits the engine
func _on_stop_pressed() -> void: Network.send_command("debug", "quit")

## Crash the server
func _on_crash_pressed() -> void: Network.send_command("debug", "crash")


### Sets the output to the selected component uuid
#func _on_get_component_uuid_pressed() -> void:
	#Interface.show_object_picker(ObjectPicker.SelectMode.Single, func (objects: Array):
		#set_output(objects[0].uuid)
	#)


## Dumps the servers networkd objects to a file
func _on_dump_networked_objects_pressed() -> void:
	Network.send_command("debug", "dump_networked_objects").then(func (file_path: String):
		set_output("Networked Objects dumped to (on-server): " + file_path)
	)

## Shows the device id, obtained from OS.get_unique_id()
func _on_get_unique_id_pressed() -> void: set_output(OS.get_unique_id())


## Sets the output to a list containing all the functions
func _on_list_functions_pressed() -> void:
	var output: Dictionary = {}
	
	for function: Function in ComponentDB.get_components_by_classname("Function"):
		output[function.uuid] = str(function) + " | " + function.name()
	
	set_output(output)

#
### Shows an objectpicker then a ComponentNamePopup
#func _on_change_name_pressed() -> void:
	#Interface.show_object_picker(ObjectPicker.SelectMode.Single, func(objects: Array):
		#Interface.show_name_prompt(objects[0])
	#)
#
#
### Dumps fixture data
#func _on_dump_fixture_data_pressed() -> void:
	#Interface.show_object_picker(ObjectPicker.SelectMode.Single, func (fixtures: Array):
		#Network.send_command("debug", "dump_fixture_data", [fixtures[0]]).then(func (path: String):
			#OS.shell_open(path)
			#set_output(path)
		#)
	#, "Fixture")
#
#
### Gets a Serialized Component
#func _on_get_serialized_component_pressed() -> void:
	#Interface.show_object_picker(ObjectPicker.SelectMode.Single, func (components: Array):
		#Network.send_command(components[0].uuid, "serialize").then(func (data: Dictionary):
			#set_output(data)
		#)
	#, "")
#
### Gets a Serialized Component, local
#func _on_get_serialized_component_local_pressed() -> void:
	#Interface.show_object_picker(ObjectPicker.SelectMode.Single, func (components: Array):
		#set_output(components[0].serialize())
	#, "")

#
#func _on_send_message_to_server_pressed() -> void:
	#var args: Variant = str_to_var(message_args.text)
	#
	#if args is Array:
		#if local_remote_option.get_selected_id():
			#var component: EngineComponent = ComponentDB.get_component(message_for.text)
			#
			#if component and component.has_method(message_method.text):
				#var method: Callable = component.get(message_method.text)
				#
				#if method.get_argument_count() == len(args):
					#set_output(method.callv(args))
		#
		#else:
			#Network.send_command(message_for.text, message_method.text, args).then(
				#func (result: Variant = null):
					#set_output(result)
			#)


## Called when the prompt parameter list button is pressed
func _on_prompt_parameter_list_pressed() -> void:
	Popups.ObjectSelector(self, EngineComponent, Fixture).then(func (p_fixture: Fixture):
		Popups.ParameterList(self, [p_fixture]).then(func (p_zone: String, p_parameter: String, p_function: String):
			set_output([p_zone, p_parameter, p_function])
		)
	)


func _on_prompt_parameter_list_zone_pressed() -> void:
	Popups.ObjectSelector(self, EngineComponent, Fixture).then(func (p_fixture: Fixture):
		Popups.ParameterList_zone(self, [p_fixture]).then(func (p_zone: String):
			set_output(p_zone)
		)
	)


func _on_prompt_parameter_list_zone_parameter_pressed() -> void:
	Popups.ObjectSelector(self, EngineComponent, Fixture).then(func (p_fixture: Fixture):
		Popups.ParameterList_zone_parameter(self, [p_fixture]).then(func (p_zone: String, p_parameter: String):
			set_output([p_zone, p_parameter])
		)
	)


func _on_prompt_parameter_list_parameter_pressed() -> void:
	Popups.ObjectSelector(self, EngineComponent, Fixture).then(func (p_fixture: Fixture):
		Popups.ParameterList_zone(self, [p_fixture]).then(func (p_zone: String):
			Popups.ParameterList_parameter(self, [p_fixture], p_zone).then(func (p_parameter: String):
				set_output(p_parameter)
			)
		)
	)


func _on_prompt_parameter_list_function_pressed() -> void:
	Popups.ObjectSelector(self, EngineComponent, Fixture).then(func (p_fixture: Fixture):
		Popups.ParameterList_zone_parameter(self, [p_fixture]).then(func (p_zone: String, p_parameter: String):
			Popups.ParameterList_function(self, [p_fixture], p_zone, p_parameter).then(func (p_function: String):
				set_output(p_function)
			)
		)
	)


func _on_object_picker_pressed() -> void:
	Popups.ObjectSelector_gbc_index(self).then(func (p_gbc_index: GBCIndexConfig):
		if not is_instance_valid(p_gbc_index):
			return
		
		Popups.ObjectSelector(self, p_gbc_index.get_base_class(), "").then(func (p_object: Object):
			set_output(p_object)
		)
	)


func _on_object_selector_gbc_index_pressed() -> void:
	Popups.ObjectSelector_gbc_index(self).then(func (p_gbc_index: GBCIndexConfig):
		set_output(p_gbc_index)
	)


func _on_object_selector_gbc_object_pressed() -> void:
	Popups.ObjectSelector_gbc_object(self).then(func (p_object: Object):
		set_output(p_object)
	)


func _on_object_selector_gbc_class_pressed() -> void:
	Popups.ObjectSelector_gbc_class(self).then(func (p_class: String):
		set_output(p_class)
	)


func _on_object_picker_class_pressed() -> void:
	Popups.ObjectSelector_gbc_index(self).then(func (p_gbc_index: Variant):
		if not is_instance_valid(p_gbc_index):
			return
		
		Popups.ObjectSelector_class(self, p_gbc_index.get_base_class(), "").then(func (p_class: String):
			set_output(p_class)
		)
	)
