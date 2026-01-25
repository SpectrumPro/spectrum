# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputEngineComponent extends DataInput
## DataInput for Data.Type.ENGINECOMPONENT


## The LineEdit
var _button: Button


## Ready
func _ready() -> void:
	_data_type = Data.Type.ENGINECOMPONENT
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is EngineComponent:
		_button.set_text(p_value.name())
		_button.add_theme_color_override("font_color", ThemeManager.Colors.FontColor)
	else:
		_button.set_text("null")
		_button.add_theme_color_override("font_color", ThemeManager.Colors.FontDisabledColor)


## Resets this DataInputString
func _reset() -> void:
	_module_value_changed("")


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when the button is pressed
func _on_button_pressed() -> void:
	Interface.prompt_object_picker(self, EngineComponent, _module.get_class_filter().get_global_name()).then(func (p_component: EngineComponent):
		set_value(p_component)
	)
