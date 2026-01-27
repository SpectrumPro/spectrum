# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIWindowManagerMainTab extends Control
## UIWindowManagerMainTab


## Enum for table columns
enum Columns {NAME}


## The Table to display all windows
@export var window_table: Table

## SettingsManagerView for the selected window
@export var settings_manager_view: SettingsManagerView

## The CloseWindow Button
@export var close_window_button: Button

## The OpenWindow button
@export var open_window_button: Button

## The DeleteWindowButton
@export var delete_window_button: Button


## RefMap for Table.Row: Window 
var _window_rows: RefMap = RefMap.new()

## The current selected window
var _selected_window: UIWindow

## Column DataTypes
var _column_data_types: Dictionary[int, Data.Type] = {
	Columns.NAME: 		Data.Type.STRING,
}


## Ready
func _ready() -> void:
	for column: String in Columns:
		window_table.add_column(column.capitalize(), _column_data_types[Columns[column]])
	
	Interface.window_added.connect(_add_window)
	Interface.window_removed.connect(_remove_window)
	
	for window: UIWindow in Interface.get_all_windows():
		_add_window(window)


## Called when a window is added
func _add_window(p_window: UIWindow) -> void:
	_window_rows.map(window_table.add_row({
		Columns.NAME:	p_window.settings().get_entry("title"),
	}), p_window)


## Called when an item is removed
func _remove_window(p_window: UIWindow) -> void:
	window_table.remove_row(_window_rows.right(p_window))
	_window_rows.erase_right(p_window)


## Updates buttons disabled state
func _update_buttons() -> void:
	var state: bool = _selected_window == null
	if _selected_window and _selected_window.is_window_root():
		state = true
	
	close_window_button.set_disabled(state)
	open_window_button.set_disabled(state or _selected_window.visible)
	delete_window_button.set_disabled(state)


## Called when the selection is changed in the Table
func _on_table_selection_changed() -> void:
	if not window_table.is_any_selected():
		_selected_window = null
		_update_buttons()
		settings_manager_view.reset()
		return
	
	_selected_window = _window_rows.left(window_table.get_selected_row())
	settings_manager_view.set_manager(_selected_window.settings())
	_update_buttons()


## Called when the AddWindow button is pressed
func _on_add_window_pressed() -> void:
	window_table.deselect_all()
	_window_rows.right(Interface.add_window()).select()


## Called when the CloseWindow button is presse
func _on_close_window_pressed() -> void:
	if _selected_window:
		Interface.close_window(_selected_window)
		_update_buttons()


## Called when the DeleteWindow button is pressed
func _on_delete_window_pressed() -> void:
	if _selected_window:
		Interface.prompt_delete_confirmation(self, str("Delete: ", _selected_window.get_window_title(), "?")).then(func ():
			Interface.remove_window(_selected_window)
			_update_buttons()
		)


## Called when the open window button is pressed
func _on_open_window_pressed() -> void:
	if _selected_window:
		Interface.show_window(_selected_window)
		_update_buttons()


## Called when the IdentifyWindows button is pressed
func _on_identify_windows_toggled(p_toggled_on: bool) -> void:
	if p_toggled_on:
		Interface.show_window_id()
	else:
		Interface.hide_window_id()
