# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Table extends UIComponent
## Class to create a spreadsheet like table


## Emitted when the cell selection is changed
signal selection_changed()

## Emitted when the expand option is changed
signal expand_changed(expand: bool)

## Emitted when the column freeze number is changed
signal column_freeze_changed(column_freeze: int)

## Emitted when an edit is requested on data that is not of type SettingsModule
signal edit_request_none_module(p_selected_items: Dictionary[Row, Array])


## The CoreTree for all data
@onready var _core_tree: Tree = %CoreTree

## The FreezeTree for Columns that don't move
@onready var _freeze_tree: Tree = %FreezeTree

## The CoreTitleContainer node 
@onready var _core_title_container: HBoxContainer = %CoreTitleContainer

## The FreezeTitleContainer node 
@onready var _freeze_title_container: HBoxContainer = %FreezeTitleContainer

## The Container that contains the FreezeTree
@onready var _freeze_tree_container: Control = %FreezeTreeContainer

## The TemplateTitleButton
@onready var _template_title_button: TableTitleButton = %TemplateTitleButton

## The TitleScroll on the title
@onready var _title_scroll: ScrollContainer = %TitleScroll

## The Control node that contains the SelectBox
@onready var _select_container: Control = %SelectContainer

## The SelectBox
@onready var _select_box: SelectBox = %SelectBox


## All columns in the tree
var _columns: Array[Column] 

## RefMap for Row: TreeItem
var _rows: Array[Row]

## RefMap for CoreTree Row: TreeItem
var _core_rows: RefMap = RefMap.new()

## RefMap for FreezeTree Row: TreeItem
var _freeze_rows: RefMap = RefMap.new()

## The HScrollBar on the CoreTree
var _core_tree_h_scroll_bar: HScrollBar

## The VScrollBar on the CoreTree
var _core_tree_v_scroll_bar: VScrollBar

## The HScrollBar on the FreezeTree
var _freeze_tree_h_scroll_bar: HScrollBar

## The VScrollBar on the FreezeTree
var _freeze_tree_v_scroll_bar: VScrollBar

## All selected TreeItems, and thier selected columns
var _selected_items: Dictionary[Row, Array]

## History of current selected items
var _selection_history: Dictionary[Array, Variant]

## A 320bit hash of the previous selection
var _previous_selection_hash: int = -1

## All TreeItems that have a theme select color tint for a selection
var _active_row_tints: Array[Row]

## Enabled or disabled the table to expand
var _expand: bool = true

## Number of columns to freeze so they wont scroll
var _column_freeze: int = 0

## Saved column sizes from seralize
var _saved_column_sizes: Dictionary[int, int]

## If true, the next scroll event will be ignored
var _ignore_next_v_scroll: bool = false

## If true, the next tree selection will be ignored
var _ignore_next_tree_select: bool = false


## Init
func _init() -> void:
	super._init()
	
	_set_class_name("Table")
	
	_settings_manager.register_setting("Expand", Data.Type.BOOL, set_expand, get_expand, [expand_changed])
	_settings_manager.register_setting("ColumnFreeze", Data.Type.INT, set_column_freeze, get_column_freeze, [column_freeze_changed]).set_min_max(0, INF)


## Ready
func _ready() -> void:
	_core_tree.create_item()
	_freeze_tree.create_item()
	
	_core_tree_h_scroll_bar = _core_tree.get_children(true)[1]
	_core_tree_v_scroll_bar = _core_tree.get_children(true)[2]
	_freeze_tree_h_scroll_bar = _freeze_tree.get_children(true)[1]
	_freeze_tree_v_scroll_bar = _freeze_tree.get_children(true)[2]
	
	_freeze_tree_h_scroll_bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	_freeze_tree_v_scroll_bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	
	_core_tree_v_scroll_bar.value_changed.connect(_on_core_tree_v_scroll_bar_value_changed)
	_freeze_tree_v_scroll_bar.value_changed.connect(_on_freeze_tree_v_scroll_bar_value_changed)
	
	_core_tree_h_scroll_bar.value_changed.connect(_title_scroll.set_h_scroll)
	_title_scroll.get_h_scroll_bar().value_changed.connect(_core_tree_h_scroll_bar.set_value)
	
	_template_title_button.get_parent().remove_child(_template_title_button)
	queue(_update_column_min_size_next_frame)


## Adds a new column to the table
func add_column(p_name: String, p_data_type: Data.Type) -> Column:
	var column_id: int = len(_columns)
	var min_width: int = _saved_column_sizes.get(column_id, 0)
	var new_column: Column = Column.new(self, column_id, p_name, _column_freeze, min_width, p_data_type, _core_tree, _freeze_tree, _rows, _template_title_button.duplicate())
	
	_columns.append(new_column)
	queue(_update_column_min_size_next_frame)
	
	return new_column


## Adds a new row to the table
func add_row(p_data: Dictionary[int, Variant], p_icon: Texture2D = null) -> Row:
	var new_row: Row = Row.new(self, _column_freeze, _columns, p_data, _core_tree, _freeze_tree, p_icon)
	
	_rows.append(new_row)
	_core_rows.map(new_row, new_row.get_core_item())
	_freeze_rows.map(new_row, new_row.get_freeze_item())
	
	return new_row


## Removes a row from the table
func remove_row(p_row: Row) -> bool:
	if p_row in _selected_items:
		_selected_items.erase(p_row)
	
	_rows.erase(p_row)
	queue(_update_selection)
	
	p_row._delete()
	p_row.free()
	
	return true


## Clears all rows
func clear() -> void:
	for row: Row in _rows:
		row._delete()
		row.free()
	
	_rows.clear()
	_selected_items.clear()
	_active_row_tints.clear()
	
	_core_tree.clear()
	_freeze_tree.clear()
	
	_core_tree.create_item()
	_freeze_tree.create_item()


## Clears all columns
func clear_columns() -> void:
	for column: Column in _columns:
		column._delete()
		column.free()
	
	_columns.clear()
	_core_tree.set_columns(1)
	_freeze_tree.set_columns(1)


## Deselects all items
func deselect_all() -> void:
	_core_tree.deselect_all()
	_freeze_tree.deselect_all()
	
	_selected_items.clear()
	_selection_history.clear()
	
	queue(_update_selection)


## Edits the selected items, if they are SettingsModules
func edit_selected() -> void:
	if not is_any_selected():
		return
	
	var latest_selected: Array = _selection_history.keys()[-1]
	var cell_data: Variant = latest_selected[0].get_cell_data(latest_selected[1])
	
	if cell_data is SettingsModule:
		var modules_to_edit: Array[SettingsModule] = _deselect_type_without_match(cell_data.get_data_type())
		
		if modules_to_edit:
			Utils.array_move_to_start(modules_to_edit, cell_data)
			Interface.prompt_settings_module(self, modules_to_edit)
	else:
		var result: Dictionary[Row, Array] = _deselect_all_settings_modules()
		edit_request_none_module.emit(result)


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


## Sets the column freeze number
func set_column_freeze(p_column_freeze: int) -> void:
	if _column_freeze == p_column_freeze:
		return
	
	_column_freeze = p_column_freeze
	_freeze_tree_container.set_visible(bool(_column_freeze))
	
	column_freeze_changed.emit(_column_freeze)


## Gets the expand state
func get_expand() -> bool:
	return _expand


## Returns the column freeze number
func get_column_freeze() -> int:
	return _column_freeze


## Returns the last selected row
func get_selected_row() -> Row:
	if not is_any_selected():
		return null
	
	return _selection_history.keys()[-1][0]


## Returns the first selected row
func get_first_selected_row() -> Row:
	if not is_any_selected():
		return null
	
	return _selection_history.keys()[0][0]


## Returns all selected rows
func get_selected_rows() -> Array:
	var result: Dictionary[Row, Variant]
	
	for entry: Array in _selection_history:
		var row: Row = entry[0]
		
		if not result.has(row):
			result[row] = null
	
	return result.keys()


## Returns the current selection
func get_selection() -> Dictionary[Row, Array]:
	return _selected_items.duplicate(true)


## Gets the column from an ID
func get_column(p_id) -> Column:
	if p_id > _columns.size():
		return null
	else:
		return _columns[p_id]


## Gets all the rows in the tree
func get_rows() -> Array[Row]:
	return _rows


## Returns the TitleContainer HBox for the CoreTable
func get_core_title_container() -> HBoxContainer:
	return _core_title_container


## Returns the TitleContainer HBox for the FreezeTable
func get_freeze_title_container() -> HBoxContainer:
	return _freeze_title_container


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
func _set_item_selected(p_row: Row, p_column: Column, p_selected: bool) -> void:
	if p_selected:
		p_row.get_tree_item(p_column).select(p_column.get_tree_id())
	else:
		p_row.get_tree_item(p_column).deselect(p_column.get_tree_id())
	
	_handle_item_selected(p_row, p_column, p_selected)


## Updates all the row selection, adding a light blue tint to selected rows
func _update_selection() -> void:
	var current_selection_hash: int = _selected_items.hash()
	
	if current_selection_hash == _previous_selection_hash:
		return
	
	_previous_selection_hash = current_selection_hash
	var rows_to_reset: Array[Row] = _active_row_tints.duplicate()
	_active_row_tints.clear()
	
	for row: Row in _selected_items:
		rows_to_reset.erase(row)
		_active_row_tints.append(row)
		
		for column: Column in _columns:
			match column.get_tree():
				_core_tree:
					row.get_core_item().set_custom_bg_color(column.get_tree_id(), ThemeManager.Colors.Selections.SelectedDimmed)
				_freeze_tree:
					row.get_freeze_item().set_custom_bg_color(column.get_tree_id(), ThemeManager.Colors.Selections.SelectedDimmed)
	
	for row: Row in rows_to_reset:
		if not is_instance_valid(row):
			continue
		
		for column: Column in _columns:
			match column.get_tree():
				_core_tree:
					row.get_core_item().set_custom_bg_color(column.get_tree_id(), Color.TRANSPARENT)
				_freeze_tree:
					row.get_freeze_item().set_custom_bg_color(column.get_tree_id(), Color.TRANSPARENT)
	
	selection_changed.emit()


## Deselects all items unless they contain SettingsModule with a Data.Type that matches the one given
func _deselect_type_without_match(p_type: Data.Type) -> Array[SettingsModule]:
	var selected_items: Dictionary = _selected_items.duplicate(true)
	var result: Array[SettingsModule]
	
	for row: Row in selected_items:
		for column: Column in selected_items[row]:
			var data: Variant = row.get_cell_data(column)
			
			if data is SettingsModule and data.get_data_type() == p_type:
				result.append(data)
			else:
				_set_item_selected(row, column, false)
	
	return result


## Deselects all none SettingsModule types
func _deselect_all_settings_modules() -> Dictionary[Row, Array]:
	var selected_items: Dictionary[Row, Array] = _selected_items.duplicate(true)
	var result: Dictionary[Row, Array]
	
	for row: Row in selected_items:
		for column: Column in selected_items[row]:
			var data: Variant = row.get_cell_data(column)
			
			if data is SettingsModule:
				_set_item_selected(row, column, false)
			else:
				result.get_or_add(row, []).append(column)
	
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
func _handle_item_selected(p_item: Variant, p_column: Variant, p_selected: bool) -> void:
	var row: Row
	var column: Column
	
	if p_item is Row:
		row = p_item
	
	elif p_item is TreeItem:
		if _ignore_next_tree_select:
			p_item.select.call_deferred(p_column)
			return
		
		if _core_rows.has_right(p_item):
			row = _core_rows.right(p_item)
			p_column += _column_freeze
		else:
			row = _freeze_rows.right(p_item)
	
	if typeof(p_column) == TYPE_OBJECT and p_column is Column:
		column = p_column
	
	elif typeof(p_column) == TYPE_INT:
		column = _columns[p_column]
	
	if not is_instance_valid(row) or not is_instance_valid(column):
		return
	
	var history_entry: Array = [row, column] 
	
	if _selection_history.has(history_entry):
		_selection_history.erase(history_entry)
	
	if p_selected:
		var columns: Array = _selected_items.get_or_add(row, [])
		
		if p_column not in columns:
			columns.append(column)
		
		_selection_history[history_entry] = null
	
	else:
		var columns: Array = _selected_items.get(row, [])
		columns.erase(column)
		
		if not columns:
			_selected_items.erase(row)
	
	queue(_update_selection)


## Handles a right click on a tree
func _handle_tree_right_click(p_tree: Tree) -> void:
	var mouse_pos: Vector2 = p_tree.get_local_mouse_position()
	var item: TreeItem = p_tree.get_item_at_position(mouse_pos)
	var p_column: int = p_tree.get_column_at_position(mouse_pos)
	
	if not is_instance_valid(item):
		return
	
	if _selected_items and _selected_items.keys().size() == 1 and _selected_items.values()[0].size() == 1:
		deselect_all()
	
	var row: Row
	var column: Column
	match p_tree:
		_core_tree:
			row = _core_rows.right(item)
			column = _columns[p_column + _column_freeze]
		_freeze_tree:
			row = _freeze_rows.right(item)
			column = _columns[p_column]
		
	_set_item_selected(row, column, true)
	edit_selected()


## Called when nothing is selected in the tree
func _on_tree_nothing_selected() -> void:
	deselect_all()


## Called for each GUI input on the CoreTree
func _on_core_tree_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.button_index == MOUSE_BUTTON_RIGHT and p_event.is_pressed():
		_handle_tree_right_click(_core_tree)


## Callef for each GUI input on the FreezeTree
func _on_freeze_tree_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.button_index == MOUSE_BUTTON_RIGHT and p_event.is_pressed():
		_handle_tree_right_click(_freeze_tree)


## Called when the CoreTree has its size changed
func _on_core_tree_resized() -> void:
	queue(_update_column_min_size)


## Called when the FreezeTree has its size changed
func _on_freeze_tree_resized() -> void:
	queue(_update_column_min_size)


## Called when the sroll distance is changed on the VScrollBar inside of the CoreTree
func _on_core_tree_v_scroll_bar_value_changed(p_value: float) -> void:
	if _ignore_next_v_scroll:
		_ignore_next_v_scroll = false
		return 
	
	_freeze_tree_v_scroll_bar.set_value(p_value)
	_ignore_next_v_scroll = true


## Called when the sroll distance is changed on the VScrollBar inside of the FreezeTree
func _on_freeze_tree_v_scroll_bar_value_changed(p_value: float) -> void:
	if _ignore_next_v_scroll:
		_ignore_next_v_scroll = false
		return 
	
	_core_tree_v_scroll_bar.set_value(p_value)
	_ignore_next_v_scroll = true


## Called when the visibility is changed on the FreezeTree HScrollBar
func _on_freeze_tree_h_scroll_bar_visibility_changed() -> void:
	_freeze_tree_h_scroll_bar.hide()


## Called when the selection changes
func _on_select_box_selection_updated(p_selection: Rect2) -> void:
	get_viewport().set_input_as_handled()
	
	if not Input.is_key_label_pressed(KEY_CTRL):
		deselect_all()

	for row: Row in _rows:
		for column: Column in _columns:
			var tree: Tree = column.get_tree()
			var selection: Rect2 = p_selection
			
			selection.position += _select_container.get_global_rect().position - tree.get_global_rect().position
			
			if tree.get_item_area_rect(row.get_tree_item(column), column.get_tree_id()).intersects(selection):
				_set_item_selected(row, column, true)


## Called when the select box is releases
func _on_select_box_released() -> void:
	_ignore_next_tree_select = true
	(func ():
		_ignore_next_tree_select = false
	).call_deferred()


## Called when the visability is changed on this Table
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		queue(_update_column_min_size_next_frame)


## Class to repersent a row in the tree
class Row extends Object:
	## The Table that hold this Row
	var _table: Table
	
	## The CoreTree TreeItem
	var _core_item: TreeItem
	
	## The FreezeTree TreeItem
	var _freeze_item: TreeItem
	
	## The tree this column is in
	var _core_tree: Tree 
	
	## The FreezeTree in the table
	var _freeze_tree: Tree
	
	## The ColumnFreeze number
	var _column_freeze: int 
	
	## The Icon for this row
	var _icon: Texture2D
	
	## All the Columns in the table
	var _columns: Array[Column] 
	
	## Data for each cell in this row
	var _cells: Dictionary[Table.Column, Variant]
	
	## All bound callables for when a SettingsModule's data is changed
	var _module_bound_change_methods: Dictionary[Table.Column, Callable]
	
	## All bound methods when using a SettingsMoudle with Data.Type.OBJECT
	var _module_bound_name_methods: Dictionary[Table.Column, Callable]
	
	
	## Init
	func _init(p_table: Table, p_column_freeze: int, p_columns: Array[Column], p_data: Dictionary[int, Variant], p_core_tree: Tree, p_freeze_tree: Tree, p_icon: Texture2D) -> void:
		_table = p_table
		_columns = p_columns
		_column_freeze = p_column_freeze
		_icon = p_icon
		
		_core_tree = p_core_tree
		_freeze_tree = p_freeze_tree
		_core_item = _core_tree.create_item()
		_freeze_item = _freeze_tree.create_item()
		
		if p_column_freeze:
			_freeze_item.set_icon(0, _icon)
		else:
			_core_item.set_icon(0, _icon)
		
		for column: int in p_data:
			set_cell_data(_columns[column], p_data[column])
	
	
	## Selects this row
	func select(p_column: Column = null) -> void:
		if is_instance_valid(p_column):
			_table._set_item_selected(self, p_column, true)
		else:
			for column: Column in _columns:
				_table._set_item_selected(self, column, true)
	
	
	## Deselects a column in this row
	func deselect(p_column: Column = null) -> void:
		if is_instance_valid(p_column):
			_table._set_item_selected(self, p_column, false)
		else:
			for column: Column in _columns:
				_table._set_item_selected(self, column, false)
	
	
	## Sets the data with in a cell
	func set_cell_data(p_column: Column, p_value: Variant) -> void:
		if not is_instance_valid(p_column) or p_column.get_id() > len(_columns):
			return
		
		if _module_bound_change_methods.has(p_column):
			(_cells[p_column] as SettingsModule).unsubscribe(_module_bound_change_methods[p_column])
			_module_bound_change_methods.erase(p_column)
		
		if _module_bound_name_methods.has(p_column):
			(_cells[p_column] as SettingsModule).disconnect_name_signal(_module_bound_name_methods[p_column])
			_module_bound_name_methods.erase(p_column)
		
		if p_value is SettingsModule:
			if p_value.get_data_type() != p_column.get_data_type() and p_column.get_data_type() != Data.Type.NULL:
				_cells.erase(p_column)
				get_tree_item(p_column).set_text(p_column.get_tree_id(), "")
				return
			
			_module_bound_name_methods[p_column] = p_value.connect_name_signal(_on_cell_data_object_name_changed.bind(p_column))
			_module_bound_change_methods[p_column] = p_value.subscribe(_set_cell_data_module.bind(p_column))
			
			_cells[p_column] = p_value
			get_tree_item(p_column).set_text(p_column.get_tree_id(), p_value.get_value_string())
		
		else:
			var data: Variant = p_value
			
			if p_column.get_data_type() != Data.Type.NULL:
				data = Data.data_type_convert(p_value, p_column.get_data_type())
			
			_cells[p_column] = data
			get_tree_item(p_column).set_text(p_column.get_tree_id(), str(_cells[p_column]))
	
	
	## Sets the index of this row in the tree
	func set_position(p_position: int) -> void:
		var core_children: Array[TreeItem] = _core_tree.get_root().get_children()
		var freeze_children: Array[TreeItem] = _freeze_tree.get_root().get_children()
		p_position = clampi(p_position, 0, core_children.size() - 1)
		
		if p_position < get_position():
			_core_item.move_before(core_children[p_position])
			_freeze_item.move_before(freeze_children[p_position])
		else:
			_core_item.move_after(core_children[p_position])
			_freeze_item.move_after(freeze_children[p_position])
	
	
	## Gets the data in a cell
	func get_cell_data(p_column: Table.Column) -> Variant:
		return _cells.get(p_column, null)
	
	
	## Gets the position of this Row
	func get_position() -> int:
		return _core_item.get_index()
	
	
	## Returns the correct Tree based on the ColumnFreeze number
	func get_tree_item(p_column: Column) -> TreeItem:
		if not is_instance_valid(p_column):
			return null
		
		if p_column.get_id() >= _column_freeze:
			return _core_item
		else:
			return _freeze_item
	
	
	## Returns the CoreTree TreeItem
	func get_core_item() -> TreeItem:
		return _core_item
	
	
	## Returns the FreezeTree TreeItem
	func get_freeze_item() -> TreeItem:
		return _freeze_item
	
	
	## Free the TreeItems
	func _delete() -> void:
		_core_item.free()
		_freeze_item.free()
	
	
	## Sets the cell data from a SettingsModule callback
	func _set_cell_data_module(p_data: Variant, p_column: Column) -> void:
		var item: TreeItem = get_tree_item(p_column)
		if not is_instance_valid(item):
			return
		
		item.set_text(p_column.get_tree_id(), _cells[p_column].get_value_string())
	
	
	## Called when an Object's name is changed on a SettingsModule with Data.Type.OBJECT
	func _on_cell_data_object_name_changed(p_name: String, p_column: Column) -> void:
		var item: TreeItem = get_tree_item(p_column)
		if not is_instance_valid(item):
			return
		
		item.set_text(p_column.get_tree_id(), p_name)


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
	var _core_tree: Tree 
	
	## The FreezeTree in the table
	var _freeze_tree: Tree
	
	## The RefMap containing all rows
	var _rows: Array[Row]
	
	## The Button for the title
	var _title_button: TableTitleButton
	
	## Allows this column to expand
	var _allow_expand: bool = true
	
	## The ColumnFreeze number
	var _column_freeze: int = 0
	
	## The min size of this column
	var _min_size: int = 0
	
	
	## Init
	func _init(p_table: Table, p_id: int, p_name: String, p_column_freeze: int, p_min_width: int, p_data_type: Data.Type, p_core_tree: Tree, p_freeze_tree: Tree, p_rows: Array[Row], p_title_button: TableTitleButton) -> void:
		_table = p_table
		_id = p_id
		_column_freeze = p_column_freeze
		_data_type = p_data_type
		_core_tree = p_core_tree
		_freeze_tree = p_freeze_tree
		_rows = p_rows
		_title_button = p_title_button
		
		get_tree().set_columns(max(get_tree_id() + 1, 1))
		get_tree().set_column_expand(get_tree_id(), false)
		
		set_min_size(p_min_width)
		set_title(p_name)
		
		if get_tree() == _core_tree:
			_table.get_core_title_container().add_child(_title_button)
		else:
			_table.get_freeze_title_container().add_child(_title_button)
		
		_title_button.size_changed.connect(_on_title_button_size_changed)
		_title_button.button_down.connect(_on_title_button_down)
		_title_button.right_clicked.connect(edit_column)
		
		(func ():
			_title_button.set_min_width(p_min_width)
		).call_deferred()
	
	
	## Selects all items in this column
	func select() -> void:
		for row: Row in _table.get_rows():
			row.select(self)
	
	
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
		
		for row: Row in _rows:
			row.set_cell_data(self, row.get_cell_data(self))
	
	
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
		get_tree().set_column_custom_minimum_width(get_tree_id(), _min_size)
	
	
	## Gets the column title
	func get_title() -> String:
		return _name
	
	
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
	
	
	## Returns the correct Tree based on the ColumnFreeze number
	func get_tree() -> Tree:
		if _id >= _column_freeze:
			return _core_tree
		else:
			return _freeze_tree
	
	
	## Returns the correct Column ID based on the correct tree
	func get_tree_id() -> int:
		if _id >= _column_freeze:
			return _id - _column_freeze
		else:
			return _id
	
	
	## Frees nodes
	func _delete() -> void:
		_title_button.queue_free()
	
	
	## Called when the size is changed on the title button
	func _on_title_button_size_changed(p_size: int) -> void:
		if _table.get_expand():
			_table._update_column_min_size()
		else:
			set_min_size(p_size)
		
		_table._saved_column_sizes[_id] = p_size
	
	
	## Called when the title button is pressed
	func _on_title_button_down() -> void:
		if not Input.is_key_pressed(KEY_CTRL):
			_table.deselect_all()
		
		select()
