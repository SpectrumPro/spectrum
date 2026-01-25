# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputString extends DataInput
## DataInput for Data.Type.STRING


## The LineEdit
var _line_edit: LineEdit


## Ready
func _ready() -> void:
	_data_type = Data.Type.STRING
	_line_edit = $HBox/LineEdit
	_label = $HBox/Label
	_outline = $HBox/LineEdit/Outline
	_focus_node = _line_edit


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is String and not _unsaved:
		_line_edit.set_text(_module.get_value_string())


## Resets this DataInputString
func _reset() -> void:
	_line_edit.clear()


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_line_edit.set_editable(p_editable)


## Called when the text is submitted in the LineEdit
func _on_line_edit_text_submitted(new_text: String) -> void:
	set_value(new_text)
