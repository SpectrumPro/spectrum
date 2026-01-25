# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputUIPanel extends DataInput
## DataInput for Data.Type.UIPANEL


## The LineEdit
var _button: Button


## Ready
func _ready() -> void:
	_data_type = Data.Type.UIPANEL
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	_button.set_text(p_value.get_class_name() if p_value is UIPanel else "")


## Resets this DataInputString
func _reset() -> void:
	_button.set_text("")


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when the button is pressed
func _on_button_pressed() -> void:
	Interface.prompt_panel_picker(self).then(func (p_panel_class: String):
		set_value(UIDB.instance_panel(p_panel_class))
	)


## Called when the settings button is pressed
func _on_settings_pressed() -> void:
	var panel: UIPanel = _module.get_getter().call()
	
	if panel:
		Interface.prompt_panel_settings(self, panel)
