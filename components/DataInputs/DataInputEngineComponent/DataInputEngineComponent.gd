# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputEngineComponent extends DataInput
## DataInput for Data.Type.ENGINECOMPONENT


## The LineEdit
var _button: Button

## The current EngineComponent
var _current_component: EngineComponent


## Ready
func _ready() -> void:
	_data_type = Data.Type.ENGINECOMPONENT
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if is_instance_valid(_current_component):
		_current_component.name_changed.disconnect(_on_component_name_changed)
	
	_current_component = p_value
	
	if _current_component is EngineComponent and is_instance_valid(_current_component):
		_current_component.node_name_changed.connect(_on_component_name_changed)
		
		_button.set_text(_current_component.get_node_name())
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


## Called when the component name is changed
func _on_component_name_changed(p_name: String) -> void:
	_button.set_text(p_name)


## Called when the button is pressed
func _on_button_pressed() -> void:
	Interface.prompt_object_picker(self, EngineComponent, _module.get_class_filter().get_global_name()).then(func (p_component: EngineComponent):
		set_value(p_component)
	)
