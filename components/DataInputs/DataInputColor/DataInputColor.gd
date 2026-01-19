 # Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputColor extends DataInput
## DataInput for Data.Type.COLOR


## The LineEdit
var _button: ColorPickerButton


## Ready
func _ready() -> void:
	_data_type = Data.Type.COLOR
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Resets this DataInputString
func _reset() -> void:
	_button.set_pick_color(Color.WHITE)


## Override this function to provide a SettingsModule to display
func _settings_module_changed(p_module: SettingsModule) -> void:
	_button.set_pick_color(p_module.get_getter().call())


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when the button is pressed down
func _on_button_button_down() -> void:
	_update_outline_feedback(_module.get_setter().call())


## Called when the color is changed on the color picker
func _on_button_color_changed(p_color: Color) -> void:
	_update_outline_feedback(_module.get_setter().call(p_color))
