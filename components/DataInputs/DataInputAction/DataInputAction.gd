 # Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputAction extends DataInput
## DataInput for Data.Type.ACTION


## The LineEdit
var _button: Button


## Ready
func _ready() -> void:
	_data_type = Data.Type.ACTION
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Resets this DataInputString
func _reset() -> void:
	_button.set_toggle_mode(false)
	_button.set_pressed_no_signal(false)
	_button.set_text("Action")


## Override this function to provide a SettingsModule to display
func _settings_module_changed(p_module: SettingsModule) -> void:
	_button.set_text(p_module.get_name())
	_button.set_toggle_mode(p_module.get_action_mode() == SettingsModule.ActionMode.TOGGLE)


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when the button is pressed down
func _on_button_button_down() -> void:
	set_value()


## Called when the button is pressed up
func _on_button_button_up() -> void:
	for module: SettingsModule in _modules:
		if module.get_action_mode() == SettingsModule.ActionMode.HOLD and module.get_hold_release_callable().is_valid():
			module.get_hold_release_callable().call()
