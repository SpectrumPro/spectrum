# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputIPAddr extends DataInput
## DataInput for Data.Type.IP


## The LineEdit
var _button: Button


## Ready
func _ready() -> void:
	_data_type = Data.Type.IP
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is IPAddr and not _unsaved:
		_button.set_text(p_value.to_string())


## Resets this DataInputString
func _reset() -> void:
	_button.set_text("")


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when the button is pressed
func _on_button_pressed() -> void:
	Interface.prompt_interface_selector(self).then(func (p_address: IPAddr):
		set_value(p_address)
	)
