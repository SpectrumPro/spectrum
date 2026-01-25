# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Table extends UIComponent
## Class to create a spreadsheet like table


## Emitted when the cell selection is changed
signal selection_changed()

## Emitted when the expand option is changed
signal expand_changed()


## The Tree Node
@onready var _tree: Tree = %Tree

## The TitleContainer node 
@onready var _title_container: HBoxContainer = %TitleContainer

## The TemplateTitleButton
@onready var _template_title_button: TableTitleButton = %TemplateTitleButton

## The TitleScroll on the title
@onready var _title_scroll: ScrollContainer = %TitleScroll


## All columns in the tree
var _columns: Array[Column] 

## RefMap for Row: TreeItem
var _rows: RefMap = RefMap.new()

## The Tree Root
var _root: TreeItem

## HScrollBar on the tree
var _tree_h_scroll_bar: HScrollBar

## All selected TreeItems, and thier selected columns
var _selected_items: Dictionary[TreeItem, Array]

## History of current selected items
var _selection_history: Dictionary[Array, Variant]

## All TreeItems that have a theme select color tint for a selection
var _active_row_tints: Array[TreeItem]

## Enabled or disabled the table to expand
var _expand: bool = true

## Saved column sizes from seralize
var _saved_column_sizes: Dictionary[int, int]


## Init
func _init() -> void:
	super._init()
	
	_set_class_name("Table")
	
	settings_manager.register_setting("Expand", Data.Type.BOOL, set_expand, get_expand, [expand_changed])


## Ready
func _ready() -> void:
	_root = _tree.create_item()
	_template_title_button.get_parent().remove_child(_template_title_button)
	
	_tree_h_scroll_bar = _tree.get_children(true)[1]
	_tree_h_scroll_bar.value_changed.connect(_title_scroll.set_h_scroll)
	_title_scroll.get_h_scroll_bar().value_changed.connect(_tree_h_scroll_bar.set_value)
	
	queue(_update_column_min_size_next_frame)


## Adds a new column to the table
func add_column(p_name: String, p_data_type: Data.Type) -> Column:
	var column_id: int = len(_columns)
	var min_width: int = _saved_column_sizes.get(column_id, 0)
	
	_tree.columns = max(column_id + 1, 1)
	var new_column: Column = Column.new(self, column_id, p_name, min_width, p_data_type, _tree, _rows, _template_title_button.duplicate())
	
	_columns.append(new_column)
	_title_container.add_child(new_column.get_title_button())
	
	return new_column


## Adds a new row to the table
func add_row(p_data: Dictionary[int, Variant], p_icon: Texture2D = null) -> Row:
	var new_item: TreeItem = _root.create_child()
	var new_row: Row = Row.new(self, new_item, _columns, p_data, _tree)
	
	if is_instance_valid(p_icon):
		new_item.set_icon(0, p_icon)
	
	_rows.map(new_row, new_item)
	return new_row


## Removes a row from the table
func remove_row(p_row: Row) -> bool:
	var item: TreeItem = _rows.left(p_row)
	
	if not item:
		return false
	
	if item in _selected_items:
		_selected_items.erase(item)
	
	_rows.erase_left(p_row)
	queue(_update_selection)
	
	p_row.free()
	item.free()
	return true


## Clears all rows
func clear() -> void:
	for row: Row in _rows.get_left():
		row.get_tree_item().free()
		row.free()
	
	_rows.clear()
	_selected_items.clear()
	_active_row_tints.clear()
	
	_tree.clear()
	_root = _tree.create_item()


## Clears all columns
func clear_columns() -> void:
	for column: Column in _columns:
		column.get_title_button().queue_free()
		column.free()
	
	_columns.clear()
	_tree.set_columns(1)


## Deselects all items
func deselect_all() -> void:
	_tree.deselect_all()
	_selected_items.clear()
	_selection_history.clear()
	queue(_update_selection)


## Edits the selected items, if they are SettingsModules
func edit_selected() -> void:
	if not is_any_selected():
		return
	
	var latest_selected: Array = _selection_history.keys()[-1]
	var cell_data: Variant = _rows.right(latest_selected[0]).get_cell_data(latest_selected[1])
	
	if not cell_data is SettingsModule:
		deselect_all()
		return
	
	var modules_to_edit: Array[SettingsModule] = _deselect_type_without_match(cell_data.get_data_type())
	
	if modules_to_edit:
		Utils.array_move_to_start(modules_to_edit, cell_data)
		Interface.prompt_settings_module(self, modules_to_edit)


## Sets the expand flag
func set_expand(p_expand: bool, p_no_signal: bool = false) -> void:
	if p_expand == _expand:
		return
	
	_expand = p_expand
	queue(_update_column_min_size_next_frame)
	
	for column: Column in _columns:
		var flag: ConfirmationBox.SizeFlags
		
		if not column.get_allow_expand():
			flag = Control.SIZE_SHRINK_BEGIN
		else:
			flag = Control.SIZE_EXPAND_FILL if p_expand else Control.SIZE_SHRINK_BEGIN
		
		column.get_title_button().set_h_size_flags(flag)
	
	if not p_no_signal:
		expand_changed.emit(_expand)


## Gets the expand state
func get_expand() -> bool:
	return _expand


## Returns the last selected row
func get_selected_row() -> Row:
	if not is_any_selected():
		return null
	
	return _rows.right(_selection_history.keys()[-1][0])


## Returns all selected rows
func get_selected_rows() -> Array:
	var result: Dictionary[Row, Variant]
	
	for entry: Array in _selection_history:
		var row: Row = _rows.right(entry[0])
		
		if not result.has(row):
			result[row] = null
	
	return result.keys()


## Gets the column from an ID
func get_column(p_id) -> Column:
	if p_id > _columns.size():
		return null
	else:
		return _columns[p_id]


## Gets all the rows in the tree
func get_rows() -> Array:
	return _rows.get_left()


## Returns True if there are selected items in the tree
func is_any_selected() -> bool:
	return not _selected_items.is_empty()


## Serializes this Table
func serialize() -> Dictionary:
	var column_sizes: Dictionary[int, int]
	
	for column: Column in _columns:
		column_sizes[column.get_id()] = column.get_min_size()
	
	return super.serialize().merged({
		"column_sizes": column_sizes,
		"expand": _expand
	})



## Deserializes this Table
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	var column_sizes: Dictionary = type_convert(p_serialized_data.get("column_sizes"), TYPE_DICTIONARY)
	set_expand(type_convert(p_serialized_data.get("expand"), TYPE_BOOL), true)
	
	for column_id: Variant in column_sizes:
		var column_width: Variant = column_sizes[column_id]
		
		if typeof(column_id) == TYPE_STRING and typeof(column_width) == TYPE_FLOAT:
			_saved_column_sizes[int(column_id)] = int(column_width)
	
	for column: Column in _columns:
		column.get_title_button().set_min_width(_saved_column_sizes.get(column.get_id(), 0))


## Sets an item selected
func _set_item_selected(p_item: TreeItem, p_column: int, p_selected: bool) -> void:
	if p_selected:
		p_item.select(p_column)
	else:
		p_item.deselect(p_column)
	
	_on_tree_multi_selected(p_item, p_column, p_selected)


## Updates all the row selection, adding a light blue tint to selected rows
func _update_selection() -> void:
	var rows_to_reset: Array[TreeItem] = _active_row_tints.duplicate()
	_active_row_tints.clear()
	
	for item: TreeItem in _selected_items:
		rows_to_reset.erase(item)
		_active_row_tints.append(item)
		
		for column: Column in _columns:
			item.set_custom_bg_color(column._id, ThemeManager.Colors.Selections.SelectedDimmed)
	
	for item: TreeItem in rows_to_reset:
		if not is_instance_valid(item):
			continue
		
		for column: Column in _columns:
			item.set_custom_bg_color(column._id, Color.TRANSPARENT)
	
	selection_changed.emit()


## Deselects all items unless they contain SettingsModule with a Data.Type that matches the one given
func _deselect_type_without_match(p_type: Data.Type) -> Array[SettingsModule]:
	var selected_items: Dictionary = _selected_items.duplicate(true)
	var result: Array[SettingsModule]
	
	for item: TreeItem in selected_items:
		for column: int in selected_items[item]:
			var row: Row = _rows.right(item)
			var data: Variant = row.get_cell_data(column)
			
			if data is SettingsModule and data.get_data_type() == p_type:
				result.append(data)
			else:
				_set_item_selected(item, column, false)
	
	return result


## Updates the min size on the next frame
func _update_column_min_size_next_frame() -> void:
	await get_tree().process_frame
	_update_column_min_size.call_deferred()


## Updates the min size of all columns, to match the button
func _update_column_min_size() -> void:
	for column: Column in _columns:
		column.set_min_size(column.get_title_button().get_size().x)


## Called when a cell in the tree is selected
func _on_tree_multi_selected(p_item: TreeItem, p_column: int, p_selected: bool) -> void:
	var history_entry: Array = [p_item, p_column] 
	
	if _selection_history.has(history_entry):
		_selection_history.erase(history_entry)
	
	if p_selected:
		var columns: Array = _selected_items.get_or_add(p_item, [])
		
		if p_column not in columns:
			columns.append(p_column)
		
		_selection_history[history_entry] = null
	
	else:
		var columns: Array = _selected_items.get(p_item, [])
		columns.erase(p_column)
		
		if not columns:
			_selected_items.erase(p_item)
	
	queue(_update_selection)


## Called when nothing is selected in the tree
func _on_tree_nothing_selected() -> void:
	deselect_all()


## Called for each GUI input on the tree
func _on_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		var mouse_pos: Vector2 = _tree.get_local_mouse_position()
		var item: TreeItem = _tree.get_item_at_position(mouse_pos)
		var column: int = _tree.get_column_at_position(mouse_pos)
		
		if not is_instance_valid(item):
			return
		
		if _selected_items and _selected_items.keys().size() == 1 and _selected_items.values()[0].size() == 1:
			deselect_all()
		
		_set_item_selected(item, column, true)
		edit_selected()


## Called when the select box is dragged
func _on_select_box_selection_updated(p_selection: Rect2) -> void:
	get_viewport().set_input_as_handled()
	
	if not Input.is_key_label_pressed(KEY_CTRL):
		deselect_all()
	
	var root: TreeItem = _tree.get_root()
	
	for index: int in root.get_child_count():
		var item: TreeItem = root.get_child(index)
		
		for column: int in _tree.get_columns():
			var cell_rect: Rect2 = _tree.get_item_area_rect(item, column)
			if cell_rect.intersects(p_selection):
				_set_item_selected(item, column, true)


## Called when the visability is changed on this Table
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		queue(_update_column_min_size_next_frame)


## Class to repersent a row in the tree
class Row extends Object:
	## The Table that hold this Row
	var _table: Table
	
	## The TreeItem
	var _item: TreeItem
	
	## The tree this Row is in
	var _tree: Tree
	
	## All the Columns in the table
	var _columns: Array[Column] 
	
	## Data for each cell in this row
	var _cells: Dictionary[int, Variant]
	
	## All bound callables for a SettingsModule
	var _module_bound_methods: Dictionary[int, Callable]
	
	
	## Init
	func _init(p_table: Table, p_item: TreeItem, p_columns: Array[Column], p_data: Dictionary[int, Variant], p_tree: Tree) -> void:
		_table = p_table
		_item = p_item
		_columns = p_columns
		_tree = p_tree
		
		for column: int in p_data:
			set_cell_data(column, p_data[column])
	
	
	## Sets the data with in a cell
	func set_cell_data(p_column: int, p_value: Variant) -> void:
		if p_column > len(_columns):
			return
		
		if _module_bound_methods.has(p_column):
			(_cells[p_column] as SettingsModule).unsubscribe(_module_bound_methods[p_column])
			_module_bound_methods.erase(p_column)
		
		if p_value is SettingsModule:
			if p_value.get_data_type() != _columns[p_column]._data_type:
				_cells.erase(p_column)
				_item.set_text(p_column, "")
				
				return
			
			_module_bound_methods[p_column] = p_value.subscribe(_set_cell_data_module.bind(p_column))
			
			_cells[p_column] = p_value
			_item.set_text(p_column, p_value.get_value_string())
		
		else:
			_cells[p_column] = Data.data_type_convert(p_value, _columns[p_column]._data_type)
			_item.set_text(p_column, str(_cells[p_column]))
	
	
	## Sets the index of this row in the tree
	func set_position(p_position: int) -> void:
		var children: Array[TreeItem] = _tree.get_root().get_children()
		p_position = clampi(p_position, 0, children.size() - 1)
		
		if p_position < get_position():
			_item.move_before(children[p_position])
		else:
			_item.move_after(children[p_position])
	
	
	## Gets the data in a cell
	func get_cell_data(p_column: int) -> Variant:
		return _cells.get(p_column, null)
	
	
	## Gets the TreeItem
	func get_tree_item() -> TreeItem:
		return _item
	
	
	## Gets the position of this Row
	func get_position() -> int:
		return _item.get_index()
	
	
	## Selects this row
	func select(p_column: int = 0) -> void:
		_table._set_item_selected(_item, p_column, true)
	
	
	## Sets the cell data from a SettingsModule callback
	func _set_cell_data_module(p_data: Variant, p_column: int) -> void:
		if is_instance_valid(_item):
			_item.set_text(p_column, _cells[p_column].get_value_string())


## Class to repersent a column in the tree
class Column extends Object:
	## The Table that hold this Column
	var _table: Table
	
	## Column number
	var _id: int = 0
	
	## Name of this column
	var _name: String = ""
	
	## DataType for this column
	var _data_type: Data.Type = Data.Type.NULL
	
	## The tree this column is in
	var _tree: Tree 
	
	## The RefMap containing all rows
	var _rows: RefMap
	
	## The Button for the title
	var _title_button: TableTitleButton
	
	## Allows this column to expand
	var _allow_expand: bool = true
	
	## The min size of this column
	var _min_size: int = 0
	
	
	## Init
	func _init(p_table: Table, p_id: int, p_name: String, p_min_width: int, p_data_type: Data.Type, p_tree: Tree, p_rows: RefMap, p_title_button: TableTitleButton) -> void:
		_table = p_table
		_id = p_id
		_name = p_name
		_data_type = p_data_type
		_tree = p_tree
		_rows = p_rows
		_title_button = p_title_button
		
		_title_button.size_changed.connect(_on_title_button_size_changed)
		_title_button.button_down.connect(_on_title_button_down)
		_title_button.right_clicked.connect(edit_column)
		
		_tree.set_column_expand(_id, false)
		set_min_size(p_min_width)
		set_title(p_name)
		
		(func ():
			_title_button.set_min_width(p_min_width)
		).call_deferred()
	
	
	## Selects all items in this column
	func select() -> void:
		for row: Row in _table.get_rows():
			row.select(_id)
	
	
	## Selects and edits all items in this column
	func edit_column() -> void:
		_table.deselect_all()
		select()
		_table.edit_selected()
	
	
	## Sets the column title
	func set_title(p_title: String) -> void:
		_name = p_title
		_title_button.set_text(p_title)
		
		(func ():
			set_min_size(max(_title_button.get_size().x, _min_size))
		).call_deferred()
	
	
	## Sets this columns datatype
	func set_data_type(p_data_type: Data.Type) -> void:
		if p_data_type == _data_type:
			return
		
		_data_type = p_data_type
		
		for row: Row in _rows.get_left():
			row.set_cell_data(_id, row.get_cell_data(_id))
	
	
	## Allows the column to expand
	func set_allow_expand(p_allow_expand: bool) -> void:
		_allow_expand = p_allow_expand
		
		if not _allow_expand:
			_title_button.set_h_size_flags(Control.SIZE_SHRINK_BEGIN)
		else:
			_title_button.set_h_size_flags(Control.SIZE_EXPAND_FILL if _table.get_expand() else Control.SIZE_SHRINK_BEGIN)
	
	
	## Sets the min size of this column
	func set_min_size(p_min_size: int) -> void:
		_min_size = p_min_size
		_tree.set_column_custom_minimum_width(_id, _min_size)
	
	
	## Gets the column title
	func get_title() -> String:
		return _tree.get_column_title(_id)
	
	
	## Gets the titlebar button
	func get_title_button() -> Button:
		return _title_button
	
	
	## Gets the column Data.Type
	func get_data_type() -> Data.Type:
		return _data_type
	
	
	## Gets the id of this column
	func get_id() -> int:
		return _id
	
	
	## Gets the allow expand state
	func get_allow_expand() -> bool:
		return _allow_expand
	
	
	## Gets the min size of this Column
	func get_min_size() -> int:
		return _min_size
	
	
	## Called when the size is changed on the title button
	func _on_title_button_size_changed(p_size: int) -> void:
		if _table.get_expand():
			_table._update_column_min_size()
		else:
			set_min_size(p_size)
	
	
	## Called when the title button is pressed
	func _on_title_button_down() -> void:
		if not Input.is_key_pressed(KEY_CTRL):
			_table.deselect_all()
		
		select()
