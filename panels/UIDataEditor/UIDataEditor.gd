# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIDataEditor extends UIPanel
## UI panel for editing DataContainers


## The Table
@export var table: Table

## The ComponentButton
@export var component_button: ComponentButton

## The AddItems button
@export var add_items_button: Button

## The RemoveItems button
@export var remove_items_button: Button

## The OptionButton for selecting the Programer.Layer
@export var view_layer_option: OptionButton


## The current Function
var _function: Function

## The current DataContainer
var _container: DataContainer

## RefMap for Parameter: Table.Column
var _columns: RefMap = RefMap.new()

## RefMap for {Fixture: RefMap("zone", Table.Row)}
var _rows: Dictionary[Fixture, RefMap]

## Stores each fixture and row
var _fixture_rows: Dictionary[Table.Row, Fixture]

## Current view layer
var _view_layer: Programmer.Layer

## SignalGroup for Function
var _function_connections: SignalGroup = SignalGroup.new([
	_on_function_delete_requested
], {
	"active_cue_changed": _on_cuelist_active_cue_changed
}).set_prefix("_on_function_")

## SignalGroup for DataContainer
var _container_connections: SignalGroup = SignalGroup.new([
	_on_container_items_stored,
	_on_container_items_erased,
	_on_container_delete_request,
	_on_container_items_function_changed,
	_on_container_items_value_changed,
	_on_container_items_can_fade_changed,
	_on_container_items_start_changed,
	_on_container_items_stop_changed,
]).set_prefix("_on_container_")


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIDataEditor")


## ready
func _ready() -> void:
	super._ready()
	
	_settings.require("Table", table.get_settings())
	table.set_column_freeze(2)
	
	for layer_name: String in Programmer.Layer:
		view_layer_option.add_item(layer_name.capitalize())


## Sets the Function to display
func set_function(p_function: Function) -> void:
	if p_function == _function:
		return
	
	_function_connections.disconnect_object(_function)
	_function = p_function
	
	component_button.set_component(_function)
	_function_connections.connect_object(_function)
	
	var is_valid: bool = is_instance_valid(_function)
	
	add_items_button.set_disabled(not is_valid)
	view_layer_option.set_disabled(not is_valid)
	
	if not is_valid:
		_set_container(null)
		return
	
	if ComponentClassList.does_class_inherit(_function.get_class_name(), "CueList"):
		var current_cue: Cue = _function.get_active_cue()
		var cues: Array[Cue] = _function.get_cues()
		
		if not current_cue and cues:
			current_cue = cues[0]
		
		_set_container(cues[0] if cues else null)
	else:
		_set_container(_function.get_data_container())


## Sets the view layer
func set_view_layer(p_view_layer: Programmer.Layer) -> void:
	_view_layer = p_view_layer
	
	if not is_instance_valid(_container):
		return
	
	_reload_item_data(_container.get_items())


## Serializes this UIDataEditor
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"cue_list": component_button.get_component_uuid()
	})


## Deserializes this UIDataEditor
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	component_button.look_for(type_convert(p_serialized_data.get("cue_list"), TYPE_STRING))


## Sets the DataContainer to display
func _set_container(p_container: DataContainer) -> void:
	if p_container != _container:
		_container_connections.disconnect_object(_container)
		_container = p_container
		_container_connections.connect_object(_container)
	
	var is_valid: bool = is_instance_valid(_container)
	
	table.clear()
	table.clear_columns()
	
	_rows.clear()
	_columns.clear()
	_fixture_rows.clear()
	
	table.add_column("Fixture", Data.Type.STRING)
	table.add_column("CID", Data.Type.INT)
	
	if not is_valid:
		return

	var sorted_columns: Dictionary[Programmer.Category, RefMap]
	var unsorted_columns: Dictionary[Programmer.Category, Set]
	
	for item: ContainerItem in _container.get_items():
		var parameter: String = item.get_parameter()
		var category: Programmer.Category = Programmer.get_category_from_string(item.get_fixture().get_parameter_category(item.get_zone(), parameter))
		var parameter_index: int = Programmer.get_parameter_index(category, parameter)
		
		if parameter_index != -1:
			sorted_columns.get_or_add(category, RefMap.new()).map(parameter, parameter_index)
		else:
			unsorted_columns.get_or_add(category, Set.new()).add(parameter)
	
	for category: Programmer.Category in Programmer.Category.values():
		if sorted_columns.has(category):
			var sorted_parameter_indexes: Array = sorted_columns[category].get_right()
			
			sorted_parameter_indexes.sort()
			for parameter_index: int in sorted_parameter_indexes:
				var parameter: String = sorted_columns[category].right(parameter_index)
				_columns.map(parameter, table.add_column(parameter, Data.Type.NULL))
		
		if unsorted_columns.has(category):
			for parameter: String in unsorted_columns[category].get_as_array():
				_columns.map(parameter, table.add_column(parameter, Data.Type.NULL))
	
	var data: Dictionary[Fixture, Dictionary] = _container.get_data()
	for fixture: Fixture in data:
		var root_row: Table.Row = table.add_row({})
		
		_rows[fixture] = RefMap.from({Fixture.RootZone: root_row})
		_fixture_rows[root_row] = fixture
		
		root_row.set_cell_data(table.get_column(0), fixture.get_settings().get_entry("Name"))
		root_row.set_cell_data(table.get_column(1), 0)
		
		for zone: String in data[fixture]:
			var row: Table.Row
			
			if _rows.has(fixture) and _rows[fixture].has_left(zone):
				row = _rows[fixture].left(zone)
			else:
				row = root_row.add_sub_row({})
				row.set_cell_data(table.get_column(0), zone)
				
				_rows[fixture].map(zone, row)
				_fixture_rows[row] = fixture
			
			for parameter: String in data[fixture][zone]:
				var item: ContainerItem = data[fixture][zone][parameter]
				row.set_cell_data(_columns.left(parameter), _get_item_value(item))


## Reloads the data for the given items
func _reload_item_data(p_items: Array) -> void:
	for item: ContainerItem in p_items:
		_rows[item.get_fixture()].left(item.get_zone()).set_cell_data(_columns.left(item.get_parameter()), _get_item_value(item))


## Returns the value of a ContainerItem based on the current ViewMode
func _get_item_value(p_item: ContainerItem) -> Variant:
	match _view_layer:
		Programmer.Layer.VALUE:
			return p_item.get_value()
		Programmer.Layer.START:
			return p_item.get_start()
		Programmer.Layer.STOP:
			return p_item.get_stop()
		Programmer.Layer.CANFADE:
			return p_item.get_can_fade()
		Programmer.Layer.FUNCTION:
			return p_item.get_function()
		_:
			return null


## Returns all the ContainerItems from the selected items in the table. de-selecting any none of type
func _get_items_from_table_selection(p_selection: Dictionary[Table.Row, Array], p_allow_auto_deselect: bool = true) -> Dictionary[String, Variant]:
	var items: Array[ContainerItem]
	var fixtures: Array[Fixture]
	
	for row: Table.Row in p_selection:
		var fixture: Fixture = _fixture_rows[row]
		fixtures.append(fixture)
		
		for column: Table.Column in p_selection[row]:
			var parameter: String = type_convert(_columns.right(column), TYPE_STRING)
			var item: ContainerItem = _container.get_item(fixture, _rows[fixture].right(row), parameter)
			
			if is_instance_valid(item):
				items.append(item)
			elif p_allow_auto_deselect:
				row.deselect(column)
	
	return {
		"items": items,
		"fixtures": fixtures
	}


## Called when the function is to be deleted
func _on_function_delete_requested(_p_function: Function) -> void:
	set_function(null)


## Called when items are stored into the DataContainer
func _on_container_items_stored(p_items: Array) -> void:
	_set_container(_container)


## Called when items are erased from the DataContainer
func _on_container_items_erased(p_items: Array) -> void:
	_set_container(_container)


## Called when the DataContainer is to be deleted
func _on_container_delete_request() -> void:
	_set_container(null)


## Called when the X is changed on the given items
func _on_container_items_value_changed(p_items: Array, p_value: float) -> void:
	if _view_layer == Programmer.Layer.VALUE:
		_reload_item_data(p_items)


## Called when the X is changed on the given items
func _on_container_items_can_fade_changed(p_items: Array, p_can_fade: bool) -> void:
	if _view_layer == Programmer.Layer.CANFADE:
		_reload_item_data(p_items)


## Called when the X is changed on the given items
func _on_container_items_start_changed(p_items: Array, p_start: float) -> void:
	if _view_layer == Programmer.Layer.START:
		_reload_item_data(p_items)


## Called when the X is changed on the given items
func _on_container_items_stop_changed(p_items: Array, p_stop: float) -> void:
	if _view_layer == Programmer.Layer.STOP:
		_reload_item_data(p_items)


## Called when the X is changed on the given items
func _on_container_items_function_changed(p_items: Array, p_function: String) -> void:
	if _view_layer == Programmer.Layer.FUNCTION:
		_reload_item_data(p_items)


## Called when the Function is a CueList and the active cue has changed
func _on_cuelist_active_cue_changed(p_cue: Cue) -> void:
	_set_container(p_cue)


## Called when the selection is changed on the table
func _on_table_selection_changed() -> void:
	var items: Array[ContainerItem] = _get_items_from_table_selection(table.get_selection(), false).items
	var is_valid: bool = bool(items.size())
	
	remove_items_button.set_disabled(not is_valid)


## Called when an edit is requested on the table
func _on_table_edit_request_none_module(p_selected_items: Dictionary[Table.Row, Array]) -> void:
	var result: Dictionary[String, Variant] = _get_items_from_table_selection(p_selected_items)
	var items: Array[ContainerItem] = result.items
	var fixtures: Array[Fixture] = result.fixtures
	
	if not items:
		return
	
	match _view_layer:
		Programmer.Layer.VALUE:
			Popups.show_data_input(self, Data.Type.FLOAT, items[0].get_value(), "Value").then(func (p_value: float):
				if is_instance_valid(_container): _container.set_value(items, p_value)
			)
		Programmer.Layer.START:
			Popups.show_data_input(self, Data.Type.FLOAT, items[0].get_start(), "Start").then(func (p_value: float):
				if is_instance_valid(_container): _container.set_start(items, p_value)
			)
		Programmer.Layer.STOP:
			Popups.show_data_input(self, Data.Type.FLOAT, items[0].get_stop(), "Stop").then(func (p_value: float):
				if is_instance_valid(_container): _container.set_stop(items, p_value)
			)
		Programmer.Layer.CANFADE:
			Popups.show_data_input(self, Data.Type.BOOL, items[0].get_can_fade(), "Can Fade").then(func (p_value: bool):
				if is_instance_valid(_container): _container.set_can_fade(items, p_value)
			)
		Programmer.Layer.FUNCTION:
			Popups.ParameterList_function(self, fixtures, Fixture.RootZone, items[0].get_parameter()).then(func (p_function: String):
				if is_instance_valid(_container): _container.set_function(items, p_function)
			)


## Called when the add item button is pressed
func _on_add_item_pressed() -> void:
	Popups.ObjectSelector(self, EngineComponent, Fixture).then(func (p_fixture: Fixture):
		Popups.ParameterList(self, [p_fixture]).then(func (p_zone: String, p_parameter: String, p_function: String):
			_container.store_data(
				p_fixture, 
				p_zone, 
				p_parameter, 
				p_function, 
				p_fixture.get_default(p_zone, p_parameter))
		)
	)


## Called when the RemoveItem button is pressed
func _on_remove_item_pressed() -> void:
	var items: Array[ContainerItem] = _get_items_from_table_selection(table.get_selection()).items
	Popups.confirm_delete_components(self, items, false).then(func ():
		_container.erase_items(items)
	)
