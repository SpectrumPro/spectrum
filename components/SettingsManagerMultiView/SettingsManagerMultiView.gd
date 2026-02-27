# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsManagerMultiView extends UIComponent
## SettingsManagerMultiView


## Emitted when a SettingsManager is selected
signal manager_selected(manager: SettingsManager)


## Table columns made up of SettingsManager
@export var table_column_names: Array[String]

## True if icons should be auto added based on an object type
@export var display_icons: bool = true


@export_group("Nodes")

## The Table
@export var table: Table

## The SettingsManagerView
@export var settings_manager_view: SettingsManagerView


## RefMap for Table.Column: String
var _table_columns: RefMap = RefMap.new()

## RefMap for Table.Row: SettingsManager
var _manager_rows: RefMap = RefMap.new()

## The current selected manager
var _selected_manager: SettingsManager


## Init
func _init() -> void:
	super._init()
	
	_set_class_name("SettingsManagerMultiView")


## Ready
func _ready() -> void:
	reset()


## Adds a manager
func add_manager(p_manager: SettingsManager) -> void:
	if _manager_rows.has_right(p_manager):
		return
	
	var rows: Dictionary[int, Variant]
	var icon: Texture2D
	
	for column_name: String in _table_columns.get_right():
		if not p_manager.get_entry(column_name):
			continue
		
		var entry: SettingsModule = p_manager.get_entry(column_name)
		var column: Table.Column = _table_columns.right(column_name)
		
		if entry.get_data_type() == column.get_data_type():
			rows[column.get_id()] = entry
		elif column.get_data_type() == Data.Type.NULL:
			column.set_data_type(entry.get_data_type())
			rows[column.get_id()] = entry
	
	if display_icons:
		icon = UIDB.get_class_icon(p_manager.get_inheritance_child())
	
	_manager_rows.map(table.add_row(rows, icon), p_manager)


## Removes a manager
func remove_manager(p_manager: SettingsManager) -> void:
	if not _manager_rows.has_right(p_manager):
		return
	
	if table.get_selected_row() == _manager_rows.right(p_manager):
		settings_manager_view.reset()
	
	table.remove_row(_manager_rows.right(p_manager))
	_manager_rows.erase_right(p_manager)


## Selects a manager
func select_manager(p_manager: SettingsManager) -> void:
	if not _manager_rows.has_right(p_manager):
		return
	
	_manager_rows.right(p_manager).select()


## Resets 
func reset() -> void:
	_table_columns.clear()
	_manager_rows.clear()
	_selected_manager = null
	
	table.clear()
	table.clear_columns()
	settings_manager_view.reset()
	
	for column_name: String in table_column_names:
		_table_columns.map(table.add_column(column_name.capitalize(), Data.Type.NULL), column_name)


## Gets the current selected SettingsManager
func get_selected_manager() -> SettingsManager:
	return _selected_manager


## Gets the owner of the selected SettingsManager
func get_selected_owner() -> Object:
	var selected_manager: SettingsManager = get_selected_manager()
	
	if is_instance_valid(selected_manager):
		return selected_manager.get_owner()
	else:
		return null


## Called when the selection is changed on the table
func _on_table_selection_changed() -> void:
	if table.get_selected_row():
		_selected_manager = _manager_rows.left(table.get_selected_row())
		
		settings_manager_view.set_manager(_selected_manager)
		manager_selected.emit(_selected_manager)
	
	else:
		_selected_manager = null
		settings_manager_view.reset()
		manager_selected.emit(null)
