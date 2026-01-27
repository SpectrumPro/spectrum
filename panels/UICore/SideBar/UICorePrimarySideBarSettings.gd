# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICorePrimarySideBarSettings extends Control
## UICorePrimarySideBarSettings


## The table
@export var table: Table

## The SettingsManagerView
@export var settings_manager_view: SettingsManagerView

## The OpenTabButton
@export var open_tab_button: Button

## The DeleteTab Button
@export var delete_tab_button: Button


## Enum for table columns
enum Column {TITLE, INDEX}


## The UICorePrimarySideBar
var _side_bar: UICorePrimarySideBar

## RefMap for Table.Row: UICorePrimarySideBar.TabItem
var _table_rows: RefMap = RefMap.new()

## Column datatypes
var _column_data_types: Dictionary[Column, Data.Type] = {
	Column.TITLE: Data.Type.STRING,
	Column.INDEX: Data.Type.INT,
}

## SignalGroup for UICorePrimarySideBar
var _signal_group: SignalGroup = SignalGroup.new([], {
	"tab_added": _add_tab_item,
	"tab_deleted": _remove_tab_item,
})


## Ready
func _ready() -> void:
	for column: String in Column:
		table.add_column(column.capitalize(), _column_data_types[Column[column]])
	
	table.get_column(Column.INDEX).set_allow_expand(false)


## Sets the side bar
func set_side_bar(p_side_bar: UICorePrimarySideBar) -> void:
	table.clear()
	settings_manager_view.reset()
	_table_rows.clear()
	
	_signal_group.disconnect_object(_side_bar)
	_side_bar = p_side_bar
	_signal_group.connect_object(_side_bar)
	
	for tab: UICorePrimarySideBar.TabItem in _side_bar.get_tabs():
		_add_tab_item(tab)


## Adds a tab item
func _add_tab_item(p_tab_item: UICorePrimarySideBar.TabItem) -> void:
	_table_rows.map(table.add_row({
		Column.TITLE: p_tab_item.settings().get_entry("title"),
		Column.INDEX: p_tab_item.settings().get_entry("index"),
	}), p_tab_item)


## Removes a tab item
func _remove_tab_item(p_tab_item: UICorePrimarySideBar.TabItem) -> void:
	table.remove_row(_table_rows.right(p_tab_item))
	_update_selection()


## Called when an item is selected in the table
func _update_selection() -> void:
	if table.is_any_selected():
		settings_manager_view.set_manager(_table_rows.left(table.get_selected_row()).settings())
	else:
		settings_manager_view.reset()
	
	open_tab_button.set_disabled(not table.is_any_selected())
	delete_tab_button.set_disabled(not table.is_any_selected())


## Called when the add tab button is pressed
func _on_create_tab_pressed() -> void:
	Interface.prompt_panel_picker(self).then(func (p_panel_class: String):
		var panel: UIPanel = UIDB.instance_panel(p_panel_class)
		var item: UICorePrimarySideBar.TabItem = _side_bar.create_tab(panel, _side_bar.get_next_empty_tab())
		
		Interface.prompt_data_input(self, Data.Type.STRING, panel.get_ui_name(), "Tab Name").then(func (p_name: String):
			item.set_title(p_name)
		)
	)


## Called when the open tab button is pressed
func _on_open_tab_pressed() -> void:
	_side_bar.switch_to_tab(_table_rows.left(table.get_selected_row()))


## Called when the delete tab button is pressed
func _on_delete_tab_pressed() -> void:
	_side_bar.delete_tab(_table_rows.left(table.get_selected_row()))
