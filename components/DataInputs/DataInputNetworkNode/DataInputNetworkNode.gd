# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputNetworkNode extends DataInput
## DataInput for Data.Type.NETWORKNODE


## The LineEdit
var _button: Button

## The current network node
var _current_node: NetworkNode


## Ready
func _ready() -> void:
	_data_type = Data.Type.NETWORKNODE
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if is_instance_valid(_current_node):
		_current_node.node_name_changed.disconnect(_on_node_name_changed)
	
	_current_node = p_value
	
	if _current_node is NetworkNode and is_instance_valid(_current_node):
		_current_node.node_name_changed.connect(_on_node_name_changed)
		_button.set_text(_current_node.get_node_name())
		_button.add_theme_color_override("font_color", ThemeManager.Colors.FontColor)
		
	else:
		_button.set_text("null")
		_button.add_theme_color_override("font_color", ThemeManager.Colors.FontDisabledColor)


## Resets this DataInputString
func _reset() -> void:
	_button.set_text("")


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when a nodes name is changed
func _on_node_name_changed(p_name: String) -> void:
	_button.set_text(p_name)


## Called when the button is pressed
func _on_button_pressed() -> void:
	Interface.prompt_object_picker(self, NetworkItem, _module.get_class_filter().get_global_name()).then(func (p_session: NetworkNode):
		set_value(p_session)
	)
