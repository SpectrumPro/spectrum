# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputVector2 extends DataInput
## DataInput for Data.Type.VECTOR2


## The LineEdit for the X axis
var x_axis: SpinBox

## The LineEdit for the Y axis
var y_axis: SpinBox


## Ready
func _ready() -> void:
	_data_type = Data.Type.VECTOR2
	
	_label = $HBox/Label
	_outline = $HBox/PanelContainer/Outline
	x_axis = $HBox/PanelContainer/HBoxContainer/XAxis
	y_axis = $HBox/PanelContainer/HBoxContainer/YAxis
	
	x_axis.value_changed.connect(func (x): _make_unsaved())
	x_axis.get_line_edit().text_changed.connect(func (x): _make_unsaved())
	x_axis.get_line_edit().gui_input.connect(_on_axis_gui_input)
	
	y_axis.value_changed.connect(func (x): _make_unsaved())
	y_axis.get_line_edit().text_changed.connect(func (x): _make_unsaved())
	y_axis.get_line_edit().gui_input.connect(_on_axis_gui_input)
	
	_focus_node = x_axis


## Grabs focus
func focus() -> void:
	x_axis.get_line_edit().grab_focus()


## Called when the SettingModule is changed
func _settings_module_changed(p_module: SettingsModule) -> void:
	var min: Vector2 = type_convert(p_module.get_min(), TYPE_VECTOR2)
	var max: Vector2 = type_convert(p_module.get_max(), TYPE_VECTOR2)
	
	x_axis.min_value = min.x
	x_axis.max_value = max.x
	
	y_axis.min_value = min.y
	y_axis.max_value = max.y
	
	var step: float = 1.0 if p_module.get_data_type() == Data.Type.VECTOR2I else 0.001
	
	x_axis.set_step(step)
	y_axis.set_step(step)


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is Vector2 or p_value is Vector2i and not _unsaved:
		x_axis.set_value_no_signal(p_value.x)
		y_axis.set_value_no_signal(p_value.y)


## Resets this DataInputVector2
func _reset() -> void:
	x_axis.set_value_no_signal(0)
	y_axis.set_value_no_signal(0)


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	x_axis.set_editable(p_editable)
	y_axis.set_editable(p_editable)


## Called for each input on the spinboxes
func _on_axis_gui_input(p_event: InputEvent) -> void:
	if p_event.is_action_pressed("ui_accept"):
		(func ():
			var value: Variant
			
			if _module.get_data_type() == Data.Type.VECTOR2:
				value = Vector2(x_axis.get_value(), y_axis.get_value())
			else:
				value = Vector2i(x_axis.get_value(), y_axis.get_value())
			
			set_value(_module.get_setter().call(value))
		).call_deferred()
