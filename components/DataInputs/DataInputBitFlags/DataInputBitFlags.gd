# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputBitFlags extends DataInput
## DataInput for Data.Type.BITFLAGS


## The Buttons
var _buttons: Dictionary[int, CheckBox]

## The ButtonContainer node
var _button_container: VBoxContainer

## The label to display the flags
var _flag_label: Label

## The expand button
var _expand_button: Button


## Ready
func _ready() -> void:
	_data_type = Data.Type.BITFLAGS
	_button_container = $VBox/ButtonContainer
	_label = $VBox/HBoxContainer/Label
	_flag_label = $VBox/HBoxContainer/FlagLabel
	_outline = $Outline
	_expand_button = $VBox/HBoxContainer/Expand
	_focus_node = _expand_button


## Called when the module is changed
func _settings_module_changed(p_module: SettingsModule) -> void:
	var enum_dict: Dictionary = p_module.get_enum_dict()
	
	for item_name: String in enum_dict:
		var new_button: CheckBox = CheckBox.new()
		
		new_button.set_text(item_name.capitalize())
		new_button.set_flat(true)
		new_button.toggled.connect(_on_button_toggled.bind(enum_dict[item_name]))
		
		_buttons[enum_dict[item_name]] = new_button
		_button_container.add_child(new_button)


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is int and not _unsaved:
		for bit: int in _module.get_enum_dict().values():
			_buttons[bit].set_pressed_no_signal(p_value & bit)
		
		_flag_label.set_text(Data.flags_to_string(p_value, _module.get_enum_dict()))


## Resets this DataInputString
func _reset() -> void:
	for button: CheckBox in _buttons.values():
		_button_container.remove_child(button)
		button.queue_free()
	
	_buttons.clear()


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	for button: CheckBox in _buttons.values():
		button.set_disabled(not p_editable)


## Called when an item is selected
func _on_button_toggled(p_toggled_on: bool, p_mask: int) -> void:
	var value: int = _module.get_getter().call()
	
	if p_toggled_on:
		value |= p_mask
	else:
		value &= ~p_mask
	
	set_value(value)


## Called when the expand button is pressed
func _on_expand_toggled(p_toggled_on: bool) -> void:
	_expand_button.set_button_icon(preload("res://assets/icons/UnfoldLess.svg") if p_toggled_on else preload("res://assets/icons/UnfoldMore.svg"))
	_button_container.set_visible(p_toggled_on)
