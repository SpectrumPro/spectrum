# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputCustomPanel extends DataInput
## DataInput for Data.Type.CUSTOMPANEL


## The current panel
var _current_panel: Control


## Ready
func _ready() -> void:
	_data_type = Data.Type.PACKEDSCENE
	_outline = $Outline
	_focus_node = self


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	if p_value is PackedScene:
		_current_panel = p_value.instantiate()
		add_child(_current_panel)
		_outline.move_to_front()
		
		if _module.get_custom_panel_entry_point():
			(_current_panel.get(_module.get_custom_panel_entry_point()) as Callable).call(_module.get_owner())


## Override for a reset function
func _reset() -> void:
	if is_instance_valid(_current_panel):
		remove_child(_current_panel)
		_current_panel.queue_free()
		_current_panel = null
