# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIPlaybacks extends UIPanel
## Ui panel for controling scenes, with sliders and extra buttons


## Emitted when the visable colum count is changed
signal columns_changed(columns: int)


## The NewPlaybackRowComponent container for columns
@export var _container: HBoxContainer 

## Object Picker button
@export var _object_picker_button: ObjectPickerButton


## Mode Enum
enum Mode {ASIGN, DELETE, EDIT}

## Default number of columns to show
const _default_columns: int = 10

## Dialog text for changeing column count
const _change_column_count_text: String = "Are you sure you want to change the column count to: $columns? This may be destructive."


## The function group
var _trigger_block: TriggerBlock

## All UI columns
var _columns: Dictionary[int, UIPlaybackColumn]

## Flag for if columns have been loaded from _load()
var _columns_set_from_load: bool = false

## Total number of columns to show, defaults to _default_columns
var _visable_columns: int = _default_columns

## The current mode
var _mode: Mode = Mode.ASIGN

## Signals to connect to the TriggerBlock
var _trigger_block_connections: Dictionary[String, Callable] = {
	"trigger_added": _add_trigger,
	"trigger_removed": _remove_trigger,
	"trigger_name_changed": _rename_trigger,
	"column_reset": _reset_column
}


## Init
func _init() -> void:
	super._init()
	_set_class_name("UIPlaybacks")
	
	_settings_manager.register_setting("columns", Data.Type.INT, set_columns_ui, get_columns, [columns_changed]
	).display("UIPlaybacks", 1).set_min_max(0, 100)


## Load Default Columns
func _ready() -> void:
	set_edit_mode_disabled(true)
	
	if not _columns_set_from_load:
		_set_columns(_visable_columns)


## Sets the trigger block
func set_trigger_block(trigger_block: TriggerBlock) -> void:
	if trigger_block == _trigger_block:
		return
		
	Utils.disconnect_signals(_trigger_block_connections, _trigger_block)
	_trigger_block = trigger_block
	Utils.connect_signals(_trigger_block_connections, _trigger_block)
	
	set_edit_mode_disabled(false)
	
	for playback: UIPlaybackColumn in _columns.values():
		playback.set_trigger_block(_trigger_block)
		
	var triggers: Dictionary[int, Dictionary] = _trigger_block.get_triggers()
	for row: int in triggers:
		for column: int in triggers[row]:
			_add_trigger(
				triggers[row][column].component,
				triggers[row][column].id,
				triggers[row][column].name,
				row,
				column,
			)


## Sets the mode
func set_mode(p_mode: Mode) -> void:
	_mode = p_mode
	
	for column: UIPlaybackColumn in _columns.values():
		column.set_mode(_mode)


## Sets the number of columns to show
func set_columns(p_column: int) -> bool:
	if p_column == _visable_columns:
		return false
	
	_visable_columns = p_column
	_set_columns(_visable_columns)
	columns_changed.emit(_visable_columns)
	
	return true


## Sets the number of columns to show. But showing a confirmation dialog box first
func set_columns_ui(p_columns: int) -> bool:
	if p_columns == _visable_columns:
		return false
	
	Interface.show_confirmation_dialog(_change_column_count_text.replace("$columns", str(p_columns)), self).then(func () -> void:
		set_columns(p_columns)
	)
	return true


## Gets the current number of columns
func get_columns() -> int:
	return _visable_columns


## Called when editmode state is changed
func _edit_mode_toggled(state: bool) -> void:
	if not _trigger_block:
		return
	
	for column: UIPlaybackColumn in _columns.values():
		column.set_edit_mode(state)


## Called when a trigger is added to the TriggerBlock
func _add_trigger(component: EngineComponent, id: String, p_name: String,  row: int, column: int) -> void:
	if _columns.has(column):
		_columns[column].set_component(component, true)
		_columns[column].set_row_name(row, p_name)


## Called when a trigger is removed from the TriggerBlock
func _remove_trigger(row: int, column: int) -> void:
	if _columns.has(column):
		_columns[column].set_row_name(row, "")


## Resets a column
func _reset_column(column: int) -> void:
	if _columns.has(column):
		_columns[column].reset()


## Called when a trigger is renamed
func _rename_trigger(row: int, column: int, name: String) -> void:
	if _columns.has(column):
		_columns[column].set_row_name(row, "")


## Loads the default number of columns
func _set_columns(p_columns: int) -> void:
	if p_columns > _columns.size():
		for column: int in range(_columns.size(), p_columns):
			var new_column: UIPlaybackColumn = load("uid://clead72nsry6n").instantiate()
			
			new_column.set_column(column)
			new_column.set_trigger_block(_trigger_block)
			new_column.set_edit_mode(_edit_mode)
			new_column.set_mode(_mode)
			new_column.control_pressed_edit_mode.connect(_on_column_control_pressed_edit_mode)
			
			_columns[column] = new_column
			_container.add_child(new_column)
			
			for button: Button in new_column.get_buttons():
				if button:
					add_button(button)
	
	elif p_columns < _columns.size():
		var columns: Dictionary[int, UIPlaybackColumn] = _columns.duplicate()
		
		for column: int in range(p_columns, _columns.size()):
			var column_item: UIPlaybackColumn = columns[column]
			_columns.erase(column)
			
			for button: Button in column_item.get_buttons():
				if button:
					remove_all_button_actions(button)
					remove_button(button)
			
			_container.remove_child(column_item)
			column_item.queue_free()


## Called when a control is pressed when in Mode.EDIT
func _on_column_control_pressed_edit_mode(control: Control) -> void:
	if control is Button:
		show_settings()
		Interface.get_panel_settings().get_shortcut_settings().set_buton(control)


## Called when a function group is selected
func _on_object_picker_button_object_selected(object: EngineComponent) -> void:
	set_trigger_block(object)


## Serializes this into a dict
func serialize() -> Dictionary:
	return super.serialize().merged({ 
			"trigger_block": _trigger_block.uuid() if _trigger_block else "",
			"columns": _visable_columns,
		})


## Loads this from a dict
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	_object_picker_button.look_for(type_convert(p_serialized_data.get("trigger_block", ""), TYPE_STRING))
	_visable_columns = type_convert(p_serialized_data.get("columns", _visable_columns), TYPE_INT)
	
	_columns_set_from_load = true
	_set_columns(_visable_columns)
