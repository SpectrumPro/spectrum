# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICueSheet extends UIPanel
## UICueSheet for showing cues in a cuelist


## Enum for Columns
enum Columns {IDX, QID, NAME, FADE_TIME, PRE_WAIT, TRIGGER_MODE}


## The ComponentButton
@export var component_button: ComponentButton

## The Previous Button
@export var previous_button: Button

## The Go Button
@export var go_button: Button

## The Next Button
@export var next_button: Button

## The FunctionPlaybackControls
@export var function_playback_controls: FunctionPlaybackControls

## The AddCue Button
@export var add_cue_button: Button

## The Delete Button
@export var delete_button: Button

## The Table
@export var table: Table


## The current CueList
var _cue_list: CueList

## RefMap for Cue: TableRow
var _cues: RefMap = RefMap.new()

## SignalGroup for CueList
var _cue_list_connection: SignalGroup = SignalGroup.new([
	_on_delete_requested,
],{
	"cues_added": _add_cues,
	"cues_removed": _remove_cues,
	"cue_order_changed": _set_cue_position,
})

## Config for each column
var _column_config: Dictionary[Columns, Data.Type] = {
	Columns.IDX: Data.Type.INT,
	Columns.QID: Data.Type.STRING,
	Columns.NAME: Data.Type.STRING,
	Columns.FADE_TIME: Data.Type.FLOAT,
	Columns.PRE_WAIT: Data.Type.FLOAT,
	Columns.TRIGGER_MODE: Data.Type.ENUM,
}


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UICueSheet")


## ready
func _ready() -> void:
	super._ready()
	
	for column_name: String in Columns.keys():
		var column: Columns = Columns[column_name]
		table.add_column(column_name.capitalize(), _column_config[column])
	
	_settings.require("Table", table.get_settings())


## Sets the CueList
func set_cue_list(p_cue_list: CueList) -> void:
	_cue_list_connection.disconnect_object(_cue_list)
	_cue_list = p_cue_list
	
	function_playback_controls.set_function(_cue_list)
	_cue_list_connection.connect_object(_cue_list)
	
	var is_valid: bool = is_instance_valid(_cue_list)
	
	previous_button.set_disabled(not is_valid)
	next_button.set_disabled(not is_valid)
	add_cue_button.set_disabled(not is_valid)
	delete_button.set_disabled(true)
	
	_cues.clear()
	table.clear()
	
	if not is_valid:
		return
	
	_add_cues(_cue_list.get_cues())


## Gets the CueList
func get_cue_list() -> CueList:
	return _cue_list


## Serializes this UICueSheet
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"cue_list": component_button.get_component_uuid(),
		"table": table.serialize()
	})


## Deserializes this UICueSheet
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	component_button.look_for(type_convert(p_serialized_data.get("cue_list"), TYPE_STRING))
	table.deserialize(type_convert(p_serialized_data.get("table"), TYPE_DICTIONARY))


## Adds mutiple cues
func _add_cues(p_cues: Array) -> void:
	for cue: Cue in p_cues:
		if _cues.has_left(cue):
			continue
		
		var manager: SettingsManager = cue.get_settings()
		_cues.map(cue, table.add_row({
			Columns.IDX: manager.get_entry("Position"),
			Columns.QID: manager.get_entry("QID"),
			Columns.NAME: manager.get_entry("Name"),
			Columns.FADE_TIME: manager.get_entry("FadeTime"),
			Columns.PRE_WAIT: manager.get_entry("PreWait"),
			Columns.TRIGGER_MODE: manager.get_entry("TriggerMode"),
		}))


## Removes the given cues
func _remove_cues(p_cues: Array) -> void:
	for cue: Cue in p_cues:
		if not _cues.has_left(cue):
			continue
		
		table.remove_row(_cues.left(cue))
		_cues.erase_left(cue)


## Sets the position of a cue in the list
func _set_cue_position(p_cue: Cue, p_position: int) -> void:
	if _cues.has_left(p_cue):
		_cues.left(p_cue).set_position(p_position)


## Gets the selected cues
func _get_selected_cues() -> Array[Cue]:
	var selected_cues: Array[Cue]
	
	for row: Table.Row in table.get_selected_rows():
		selected_cues.append(_cues.right(row))
	
	return selected_cues


## Called when the CueList is to be deleted
func _on_delete_requested(_p_cue_list: CueList) -> void:
	set_cue_list(null)


## Called when the previous button is pressed
func _on_previous_pressed() -> void:
	_cue_list.go_previous()


## Called when the next button is pressed
func _on_next_pressed() -> void:
	_cue_list.go_next()


## Called when the selection is changed on the Table
func _on_table_selection_changed() -> void:
	var is_selected: bool = table.is_any_selected()
	
	delete_button.set_disabled(not is_selected)
	go_button.set_disabled(not is_selected)


## Called when the go button is pressed
func _on_go_pressed() -> void:
	var cue: Cue = _cues.right(table.get_selected_row())
	_cue_list.seek_to(cue)


## Called when the AddCue button is pressed
func _on_add_cue_pressed() -> void:
	_cue_list.create_cue().then(func (p_cue: Cue):
		if not is_instance_valid(p_cue):
			return
		
		Popups.USettingsModule(self, p_cue.get_settings().get_entry("name"))
	)


## Called when then DeleteCue button is pressed
func _on_delete_cue_pressed() -> void:
	Popups.confirm_delete_components(self, _get_selected_cues())
