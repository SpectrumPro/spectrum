# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputFloat extends DataInput
## DataInput for Data.Type.FLOAT


## The LineEdit
var _spin_box: SpinBox

## Bool to ignore next change in the spinbox
var _ignore_next_update: bool = false


## Ready
func _ready() -> void:
	_data_type = Data.Type.FLOAT
	_spin_box = $HBox/SpinBox
	_label = $HBox/Label
	_outline = $HBox/SpinBox/Outline
	_spin_box.get_line_edit().text_changed.connect(func (x): _make_unsaved())
	_spin_box.get_line_edit().set_select_all_on_focus(true)
	_focus_node = _spin_box


## Sets the prefix
func set_prefix(p_prefix: String) -> void:
	_spin_box.set_prefix(p_prefix)


## Sets the prefix
func set_suffix(p_suffix: String) -> void:
	_spin_box.set_suffix(p_suffix)


## Grabs focus
func focus() -> void:
	_spin_box.get_line_edit().grab_focus()


## Called when the SettingModule is changed
func _settings_module_changed(p_module: SettingsModule) -> void:
	_ignore_next_update = true
	_spin_box.min_value = p_module.get_min()
	_ignore_next_update = true
	_spin_box.max_value = p_module.get_max()
	_ignore_next_update = false


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is float and not _unsaved:
		_spin_box.set_value_no_signal(p_value)


## Resets this DataInputString
func _reset() -> void:
	_spin_box.set_value_no_signal(0)


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_spin_box.set_editable(p_editable)


## Called when the value is changed
func _on_spin_box_value_changed(value: float) -> void:
	if _ignore_next_update:
		_ignore_next_update = false
		return
	
	set_value(value)
	_ignore_next_update = false
