# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsManagerModuleView extends PanelContainer


## Title label
@export var _title: Label

## ExpandHide button
@export var _expand_hide_button: Button

## SettingsContainer VBox
@export var _settings_container: VBoxContainer


## Disables this settings module
func set_disabled(state: bool) -> void:
	_on_expand_hide_toggled(state)
	_expand_hide_button.disabled = state


## Sets the title
func set_title(title: String) -> void:
	_title.text = title


## Shows a setting
func show_module(p_module: SettingsModule) -> void:
	var data_input: DataInput = UIDB.instance_data_input(p_module.get_data_type(), p_module.get_sub_type())
	
	if data_input is not DataInputNull:
		data_input.ready.connect(func ():
			data_input.set_module(p_module)
			data_input.set_show_label(true)
			data_input.set_label_text(p_module.get_name())
		, CONNECT_ONE_SHOT)
	
	_settings_container.add_child(data_input)


## Called when the ExpandHide button is toggled
func _on_expand_hide_toggled(toggled_on: bool) -> void:
	_settings_container.visible = not toggled_on
	_expand_hide_button.icon = preload("res://assets/icons/UnfoldMore.svg") if toggled_on else preload("res://assets/icons/UnfoldLess.svg") 
