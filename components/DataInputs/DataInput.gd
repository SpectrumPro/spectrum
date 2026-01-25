# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInput extends Control
## DataInput base class


## Emitted when the value changed sucessfulley
signal value_change_sucess()


## The main Label
var _label: Label

## The LineEdit outline
var _outline: Panel

## The Control node to focus
var _focus_node: Control = self

## The currentl SettingsModle
var _module: SettingsModule

## All settings modules when multi editing
var _modules: Array[SettingsModule]

## Currently value unsaved state
var _unsaved: bool = false

## The DataType of this DataInput
var _data_type: Data.Type = Data.Type.NULL

## Editable state
var _editable: bool = true


## Resets this DataInput
func reset() -> void:
	if _module:
		_module.unsubscribe(_module_value_changed)
	
	if _outline:
		_outline.set_modulate(Color.TRANSPARENT)
	
	_unsaved = false
	_module = null
	_modules = []
	
	_reset()


## Takes focus to the input
func focus() -> void:
	if is_instance_valid(_module) and _module.is_editable():
		_focus_node.grab_focus()


## Sets the SettingsMoudle to edit, accepts either a SettingsModule or Array[SettingsModule]
func set_module(p_modules: Variant) -> bool:
	reset()
	
	if p_modules is Array and p_modules[0] is SettingsModule:
		_module = p_modules[0]
		
		for module: Variant in p_modules:
			if module is SettingsModule and Data.do_types_match_base(module.get_data_type(), _data_type):
				_modules.append(module)
		
		if not _modules:
			return false
		
	elif p_modules is SettingsModule and is_instance_valid(p_modules):
		_module = p_modules
	else:
		return false
	
	_module.subscribe(_module_value_changed)
	_settings_module_changed(_module)
	
	if _module.get_getter().is_valid():
		_module_value_changed(_module.get_getter().call())
	
	set_editable(_module.is_editable())
	return true


## Shows or hides the label
func set_show_label(p_show_label: bool) -> void:
	if is_instance_valid(_label):
		_label.set_visible(p_show_label)


## Sets the label text
func set_label_text(p_label_text: String) -> void:
	if is_instance_valid(_label):
		_label.set_text(p_label_text) 


## Sets the editable state
func set_editable(p_editable: bool) -> void:
	_editable = p_editable
	_set_editable(_editable)


## Sets the value on the settings modules
func set_value(...p_args: Array) -> void:
	_update_outline_feedback(_module.get_setter().callv(p_args))
	
	for module: SettingsModule in _modules:
		module.get_setter().callv(p_args)


## Gets the SettingsMoudle
func get_module() -> SettingsModule:
	return _module


## Gets the label is_visible state
func get_show_label() -> bool:
	return _label.is_visible()


## Gets the label tetx
func get_label_text() -> String:
	return _label.get_text()


## Gets the data type
func get_data_type() -> Data.Type:
	return _data_type


## Gets the editable state
func get_editable() -> bool:
	return _editable


## Updates the outline to match the return value of the setter
func _update_outline_feedback(p_state: Variant) -> void:
	_unsaved = false
	Interface.kill_fade(_outline, "modulate")
	
	match typeof(p_state):
		TYPE_BOOL when p_state:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Normal)
			value_change_sucess.emit()
		
		TYPE_BOOL when not p_state:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Error)
		
		TYPE_OBJECT when p_state is Promise:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Standby)
			p_state.then(_update_outline_feedback)
		
		_:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Normal)
			value_change_sucess.emit()
	
	await get_tree().create_timer(ThemeManager.Constants.Times.DataInputOutlineWait).timeout
	
	if not _unsaved:
		Interface.fade_property(_outline, "modulate", Color.TRANSPARENT, Callable(), ThemeManager.Constants.Times.DataInputOutlineFade)


## Marks this DataInput as unsaved
func _make_unsaved() -> void:
	if not _unsaved:
		_unsaved = true
		_outline.set_modulate(ThemeManager.Colors.Statuses.UnsavedData)


## Override this function to provide a SettingsModule to display
func _settings_module_changed(p_module: SettingsModule) -> void:
	pass


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	pass


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	pass


## Override for a reset function
func _reset() -> void:
	pass
