# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputEnum extends DataInput
## DataInput for Data.Type.ENUM


## The LineEdit
var _button: OptionButton


## Ready
func _ready() -> void:
	_data_type = Data.Type.ENUM
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the module is changed
func _settings_module_changed(p_module: SettingsModule) -> void:
	var enum_dict: Dictionary = p_module.get_enum_dict()
	
	for item_name: String in enum_dict:
		_button.add_item(item_name)


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is int and not _unsaved:
		_button.select(_module.get_enum_dict().values().find(p_value))


## Resets this DataInputString
func _reset() -> void:
	_button.clear()


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when an item is selected
func _on_button_item_selected(p_index: int) -> void:
	set_value(_module.get_enum_dict().values()[p_index])
