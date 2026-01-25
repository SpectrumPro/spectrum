# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIPopupSettingsModule extends UIPopup
## UIPopupSettingsModule Displays a SettingsModule


## The title button
@export var title: Button

## The Container to hold the DataInput
@export var module_container: Container


## The current DataInput node
var _current_data_input: DataInput

## Should the data input be focused once ready
var _focus_on_ready: bool = false


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIPopupSettingsModule")


## Sets the SettingsModule to be shown
func set_module(p_modules: Variant) -> void:
	if is_instance_valid(_current_data_input):
		_current_data_input.queue_free()
	
	var module: SettingsModule
	if p_modules is Array and p_modules[0] is SettingsModule:
		module = p_modules[0]
	elif p_modules is SettingsModule and is_instance_valid(p_modules):
		module = p_modules
	else:
		return
	
	var new_data_input: DataInput = UIDB.instance_data_input(module.get_data_type())
	new_data_input.ready.connect(func ():
		new_data_input.set_module(p_modules)
		new_data_input.set_label_text(module.get_name())
		new_data_input.set_show_label(true)
		
		if _focus_on_ready:
			new_data_input.focus()
	)
	
	var title_text: PackedStringArray = []
	var show_quantity: bool = p_modules is Array and p_modules.size() > 1
	
	if module.is_editable():
		title_text.append("Edit" + ("" if show_quantity else ":"))
	else:
		title_text.append("View" + ("" if show_quantity else ":"))
	
	if show_quantity:
		title_text.append("x" + str(p_modules.size()) + ":")
	
	title_text.append(module.get_name())
	
	new_data_input.value_change_sucess.connect(accept)
	module_container.add_child(new_data_input)
	
	title.set_text(" ".join(title_text))
	_current_data_input = new_data_input


## Focuses the input
func focus() -> void:
	if _current_data_input and _current_data_input.is_node_ready():
		_current_data_input.focus()
	elif _current_data_input:
		_focus_on_ready = true
