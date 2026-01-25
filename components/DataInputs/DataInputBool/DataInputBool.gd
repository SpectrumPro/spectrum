# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputBool extends DataInput
## DataInput for Data.Type.BOOL


## The LineEdit
var _button: CheckButton


## Ready
func _ready() -> void:
	_data_type = Data.Type.BOOL
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is bool and not _unsaved:
		if p_value:
			_button.set_pressed_no_signal(p_value)
			_button.set_text("TRUE")
		else:
			_button.set_pressed_no_signal(p_value)
			_button.set_text("FALSE")


## Resets this DataInputString
func _reset() -> void:
	_button.set_pressed_no_signal(false)
	_button.set_text("FALSE")


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when the button is toggled
func _on_button_toggled(p_toggled_on: bool) -> void:
	set_value(p_toggled_on)
