# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIParameterList extends UIPopup
## Picker for Parameter Functions


## Emitted when a combined zone, parameter, and function are chosen
signal combined_chosen(p_zone: String, p_parameter: String, p_function: String)

## Emitted when a zone and parameter are chosen
signal zone_parameter_chosen(p_zone: String, p_parameter: String)

## Emitted when a zone is chosen
signal zone_chosen(p_zone: String)

## Emitted when a parameter is chosen
signal parameter_chosen(parameter: String)

## Emitted when a function is chosen
signal function_chosen(p_function: String)


## Enum for SearchMode
enum SearchMode {
	COMBINED,		## Search for a zone>parameter>function and return all 3
	ZONE_PARAMETER,	## Search for a zone>parameter and return both
	ZONE,			## Searching for a zone
	PARAMETER,		## Searching for parameter
	FUNCTION,		## Searching for function within a parameter
}


## Enmum for ZoneType
enum ItemType {
	ZONE,
	PARAMETER,
	FUNCTION
}


## The CombinedTree to show all zones, parameters, and functions
@export var combined_tree: Tree

## ZoneTree for showing all parameters per zone
@export var zone_tree: Tree

## ParameterTree for showing all parameters
@export var parameter_tree: Tree

## FunctionTree for showing all Function on the given parameter
@export var function_tree: Tree

## The TaggedLineEdit
@export var search_bar: TaggedLineEdit

## Min size of the second tree column
@export var column_min_size: int = 100


## The given fixtures
var _fixtures: Array[Fixture]

## The zone filter
var _zone_filter: String

## The parameter filter
var _parameter_filter: String

## RefMap for zone: TreeItem
var _zones_combined: RefMap = RefMap.new()

## RefMap for zone: TreeItem
var _zones_single: RefMap = RefMap.new()

## RefMap for {zone: parameter: TreeItem}
var _parameters_combined: Dictionary[String, RefMap]

## RefMap for parameter: TreeItem
var _parameters_single: RefMap = RefMap.new()

## RefMap for {zone: {parameter: function: TreeItem}}
var _functions_combined: Dictionary[String, Dictionary]

## RefMap for function: TreeItem
var _functions_single: RefMap = RefMap.new()

## ItemType for each TreeItem in the combined tree
var _combined_types: Dictionary[TreeItem, ItemType]

## Current mode
var _search_mode: SearchMode = SearchMode.COMBINED

## The orignal search mode
var _orignal_search_mode: SearchMode = SearchMode.COMBINED

## The current search text
var _search_text: String


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIParameterFunctionList")


## ready
func _ready() -> void:
	super._ready()
	
	[combined_tree, zone_tree, parameter_tree, function_tree].map(func (p_tree: Tree):
		p_tree.set_column_expand(1, false)
		p_tree.set_column_custom_minimum_width(1, column_min_size)
		p_tree.item_activated.connect(_handle_tree_activated.bind(p_tree))
	)


## Sets the SearchMode to SearchMode.COMBINED
func search_mode_combined(p_fixtures: Array[Fixture]) -> void:
	set_custom_accepted_signal(combined_chosen)
	_orignal_search_mode = SearchMode.COMBINED
	_set_search_mode_combined(p_fixtures)


## Sets the SearchMode to SearchMode.ZONE_PARAMETER
func search_mode_zone_parameter(p_fixtures: Array[Fixture]) -> void:
	set_custom_accepted_signal(zone_parameter_chosen)
	_orignal_search_mode = SearchMode.ZONE_PARAMETER
	_set_search_mode_zone_parameter(p_fixtures)


## Sets the SearchMode to SearchMode.ZONE
func search_mode_zone(p_fixtures: Array[Fixture]) -> void:
	set_custom_accepted_signal(zone_chosen)
	_orignal_search_mode = SearchMode.ZONE
	_set_search_mode_zone(p_fixtures)


## Sets the SearchMode to SearchMode.PARAMETER
func search_mode_parameter(p_fixtures: Array[Fixture], p_zone_filter: String = "") -> void:
	set_custom_accepted_signal(parameter_chosen)
	_orignal_search_mode = SearchMode.PARAMETER
	_set_search_mode_parameter(p_fixtures, p_zone_filter)


## Sets the SearchMode to SearchMode.FUNCTION
func search_mode_function(p_fixtures: Array[Fixture], p_zone_filter: String = "", p_parameter_filter: String = "") -> void:
	set_custom_accepted_signal(function_chosen)
	_orignal_search_mode = SearchMode.FUNCTION
	_set_search_mode_function(p_fixtures, p_zone_filter, p_parameter_filter)


## Searches for the given text
func search_for(p_search_text: String) -> void:
	_search_text = p_search_text
	
	combined_tree.hide()
	zone_tree.hide()
	parameter_tree.hide()
	function_tree.hide()
	
	var items_to_sort: RefMap
	var items_to_display: Array
	var search_tree: Tree
	
	match _search_mode:
		SearchMode.COMBINED when not _search_text:
			combined_tree.show()
		
		SearchMode.COMBINED when _search_text:
			zone_tree.show()
			items_to_sort = _zones_single
			search_tree = zone_tree
		
		SearchMode.ZONE:
			zone_tree.show()
			items_to_sort = _zones_single
			search_tree = zone_tree
		
		SearchMode.PARAMETER:
			parameter_tree.show()
			items_to_sort = _parameters_single
			search_tree = parameter_tree
		
		SearchMode.FUNCTION:
			function_tree.show()
			items_to_sort = _functions_single
			search_tree = function_tree
	
	if not is_instance_valid(search_tree):
		return
	
	for value: String in items_to_sort.get_left():
		items_to_display.append({
			"item_name": value,
			"similarity": value.similarity(_search_text) if _search_text else 0.0,
			"tree_item": items_to_sort.left(value),
			"show": true
		})
	
	items_to_display.sort_custom(func (p_a: Dictionary, p_b: Dictionary) -> bool:
		if _search_text and len(_search_text) < 3:
			return (p_a.item_name as String).to_lower().begins_with(_search_text[0])
		elif _search_text:
			return p_a.similarity > p_b.similarity
		else:
			return (p_a.item_name as String).naturalnocasecmp_to(p_b.item_name) < 0
	)
	items_to_display.reverse()
	
	for item: Dictionary in items_to_display:
		item.tree_item.move_before(search_tree.get_root().get_child(0))
		item.tree_item.set_visible(item.show)
	
	_select_first.call_deferred(search_tree)


## Focuses this UIParameterFunctionList
func focus() -> void:
	search_bar.grab_focus()
	search_bar.edit()


## Sets the SearchMode to SearchMode.COMBINED
func _set_search_mode_combined(p_fixtures: Array[Fixture]) -> void:
	_search_mode = SearchMode.COMBINED
	_fixtures = p_fixtures
	
	_reload_combined_tree()
	_reload_zone_tree()
	
	search_bar.clear_all()
	search_bar.set_placeholder("Select Zone > Parameter > Function")
	
	focus.call_deferred()
	search_for("")


## Sets the SearchMode to SearchMode.ZONE_PARAMETER
func _set_search_mode_zone_parameter(p_fixtures: Array[Fixture]) -> void:
	_search_mode = SearchMode.ZONE
	_fixtures = p_fixtures
	
	_reload_zone_tree()
	
	search_bar.clear_all()
	search_bar.set_placeholder("Select Zone > Parameter")
	
	focus.call_deferred()
	search_for("")


## Sets the SearchMode to SearchMode.ZONE
func _set_search_mode_zone(p_fixtures: Array[Fixture]) -> void:
	_search_mode = SearchMode.ZONE
	_fixtures = p_fixtures
	
	_reload_zone_tree()
	
	search_bar.clear_all()
	search_bar.set_placeholder("Select Zone")
	
	focus.call_deferred()
	search_for("")


## Sets the SearchMode to SearchMode.PARAMETER
func _set_search_mode_parameter(p_fixtures: Array[Fixture], p_zone_filter: String = "") -> void:
	_search_mode = SearchMode.PARAMETER
	_zone_filter = p_zone_filter
	_fixtures = p_fixtures
	
	_reload_parameter_tree()
	
	search_bar.clear_all()
	search_bar.create_tag("@" + _zone_filter)
	search_bar.set_placeholder("Select Parameter")
	
	focus.call_deferred()
	search_for("")


## Sets the SearchMode to SearchMode.FUNCTION
func _set_search_mode_function(p_fixtures: Array[Fixture], p_zone_filter: String = "", p_parameter_filter: String = "") -> void:
	_search_mode = SearchMode.FUNCTION
	_zone_filter = p_zone_filter
	_parameter_filter = p_parameter_filter
	
	_fixtures = p_fixtures
	_reload_function_tree()
	
	search_bar.clear_all()
	search_bar.create_tag("@" + _zone_filter + "/" + _parameter_filter)
	search_bar.set_placeholder("Select Function")
	
	focus.call_deferred()
	search_for("")


## Returns the current tree based on the current SearchMode
func _get_current_tree() -> Tree:
	match _search_mode:
		SearchMode.COMBINED when not _search_text:
			return combined_tree
		SearchMode.COMBINED when _search_text:
			return zone_tree
		SearchMode.ZONE:
			return zone_tree
		SearchMode.PARAMETER:
			return parameter_tree
		SearchMode.FUNCTION:
			return function_tree
		_:
			return null


## Selects the first item in the tree
func _select_first(p_tree: Tree) -> void:
	var first_child: TreeItem = p_tree.get_root().get_child(0)
	
	if is_instance_valid(first_child):
		first_child.select(0)


## Reloads all the trees
func _reload_combined_tree() -> void:
	combined_tree.clear()
	combined_tree.create_item()
	
	_zones_combined.clear()
	_parameters_combined.clear()
	_functions_combined.clear()
	
	var loaded_fixture_types: Set = Set.new()
	
	for fixture: Fixture in _fixtures:
		if not is_instance_valid(fixture) or loaded_fixture_types.has(fixture.get_type_id()):
			continue
		
		for zone: String in fixture.get_zones():
			var zone_item_combined: TreeItem
			
			if _zones_combined.has_left(zone):
				zone_item_combined = _zones_combined.left(zone)
			else:
				zone_item_combined = combined_tree.create_item()
			
			_config_item(zone_item_combined, zone, "enter", preload("res://modules/Vertex/assets/icons/Zone.svg"))
			_zones_combined.map(zone, zone_item_combined)
			_combined_types[zone_item_combined] = ItemType.ZONE
			
			_parameters_combined.get_or_add(zone, RefMap.new())
			_functions_combined.get_or_add(zone, {})
			
			for parameter: String in fixture.get_parameters(zone):
				var parameter_item_combined: TreeItem
				
				if _parameters_combined[zone].has_left(parameter):
					parameter_item_combined = _parameters_combined[zone].left(parameter)
				else:
					parameter_item_combined = zone_item_combined.create_child()
				
				_config_item(parameter_item_combined, parameter, "enter")
				_combined_types[parameter_item_combined] = ItemType.PARAMETER
				
				_parameters_combined[zone].map(parameter, parameter_item_combined)
				_functions_combined[zone].get_or_add(parameter, RefMap.new())
			
				for function: String in fixture.get_parameter_functions(zone, parameter):
					var function_item_combined: TreeItem
					
					if _functions_combined[zone][parameter].has_left(function):
						function_item_combined = _functions_combined[zone][parameter].left(function)
					else:
						function_item_combined = parameter_item_combined.create_child()
					
					_config_item(function_item_combined, function, "use")
					_combined_types[function_item_combined] = ItemType.FUNCTION
					_functions_combined[zone][parameter].map(function, function_item_combined)
	
	_select_first(combined_tree)


## Reloads the zone tree
func _reload_zone_tree() -> void:
	zone_tree.clear()
	zone_tree.create_item()
	
	_zones_single.clear()
	var loaded_fixture_types: Set = Set.new()
	
	for fixture: Fixture in _fixtures:
		if not is_instance_valid(fixture) or loaded_fixture_types.has(fixture.get_type_id()):
			continue
		
		for zone: String in fixture.get_zones():
			if _zones_single.has_left(zone):
				continue
			
			var zone_item_single: TreeItem = zone_tree.create_item()
			var subtype: String = "use" if _orignal_search_mode == SearchMode.ZONE else "enter"
			
			_config_item(zone_item_single, zone, subtype, preload("res://modules/Vertex/assets/icons/Zone.svg"))
			_zones_single.map(zone, zone_item_single)
	
	_select_first(zone_tree)


## Reloads the parameter tree
func _reload_parameter_tree() -> void:
	parameter_tree.clear()
	parameter_tree.create_item()
	
	_parameters_single.clear()
	var loaded_fixture_types: Set = Set.new()
	
	for fixture: Fixture in _fixtures:
		if not is_instance_valid(fixture) or loaded_fixture_types.has(fixture.get_type_id()):
			continue
		
		for parameter: String in fixture.get_parameters(_zone_filter):
			if _parameters_single.has_left(parameter):
				continue
			
			var parameter_item_single: TreeItem = parameter_tree.create_item()
			var subtype: String = "use" if _orignal_search_mode == SearchMode.PARAMETER else "enter"
			
			_config_item(parameter_item_single, parameter, subtype)
			_parameters_single.map(parameter, parameter_item_single)
	
	_select_first(parameter_tree)


## Reloads the function tree
func _reload_function_tree() -> void:
	function_tree.clear()
	function_tree.create_item()
	
	_functions_single.clear()
	var loaded_fixture_types: Set = Set.new()
	
	for fixture: Fixture in _fixtures:
		if not is_instance_valid(fixture) or loaded_fixture_types.has(fixture.get_type_id()):
			continue
		
		for function: String in fixture.get_parameter_functions(_zone_filter, _parameter_filter):
			if _functions_single.has_left(function):
				continue
			
			var function_item_single: TreeItem = function_tree.create_item()
			
			_config_item(function_item_single, function, "use")
			_functions_single.map(function, function_item_single)
	
	_select_first(function_tree)


## Sets the text and icon on the given TreeItem
func _config_item(p_item: TreeItem, p_text: String, p_subtype: String, p_icon: Texture2D = null) -> void:
	p_item.set_text(0, p_text)
	p_item.set_icon(0, p_icon)
	
	p_item.set_custom_color(1, Color(0x919191ff))
	p_item.set_text(1, p_subtype)


## Selectes the next item in the tree
func _select_next(p_tree: Tree) -> void:
	var current: TreeItem = p_tree.get_selected()
	var next_item: TreeItem = current.get_next_visible(true) if current else p_tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	p_tree.ensure_cursor_is_visible()


## Selectes the next item in the tree
func _select_prev(p_tree: Tree) -> void:
	var current: TreeItem = p_tree.get_selected()
	var next_item: TreeItem = current.get_prev_visible(true) if current else p_tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	p_tree.ensure_cursor_is_visible()


## Handles when a tree is activated
func _handle_tree_activated(p_tree: Tree) -> void:
	var selected: TreeItem = p_tree.get_selected()
	
	if not is_instance_valid(selected):
		return
	
	var value = selected.get_text(0)
	match p_tree:
		combined_tree:
			match _combined_types[selected]:
				ItemType.ZONE:
					_set_search_mode_parameter(_fixtures, value)
				
				ItemType.PARAMETER:
					_set_search_mode_function(_fixtures, selected.get_parent().get_text(0), value)
				
				ItemType.FUNCTION:
					function_chosen.emit(value)
					combined_chosen.emit(selected.get_parent().get_parent().get_text(0), selected.get_parent().get_text(0), value)
		
		zone_tree:
			if _orignal_search_mode == SearchMode.ZONE:
				zone_chosen.emit(value)
			else:
				_set_search_mode_parameter(_fixtures, value)
		
		parameter_tree:
			if _orignal_search_mode == SearchMode.PARAMETER:
				parameter_chosen.emit(value)
			elif _orignal_search_mode == SearchMode.ZONE_PARAMETER:
				zone_parameter_chosen.emit(_zone_filter, value)
			else:
				_set_search_mode_function(_fixtures, _zone_filter, value)
		
		function_tree:
			function_chosen.emit(value)
			combined_chosen.emit(_zone_filter, _parameter_filter, value)



## Called for each GUI input on the search bar
func _on_line_edit_gui_input(p_event: InputEvent) -> void:
	if p_event.is_action_pressed("ui_down"):
		_select_next(_get_current_tree())
	elif p_event.is_action_pressed("ui_up"):
		_select_prev(_get_current_tree())


## Called when the text is submitted on the search bar
func _on_line_edit_text_submitted(_p_new_text: String) -> void:
	_handle_tree_activated(_get_current_tree())


## Called when a tag is removed on the search bar
func _on_line_edit_tag_removed(p_id: Variant) -> void:
	match _search_mode:
		SearchMode.ZONE:
			_set_search_mode_combined(_fixtures)
		SearchMode.PARAMETER:
			_set_search_mode_zone(_fixtures)
		SearchMode.FUNCTION:
			_set_search_mode_parameter(_fixtures, _zone_filter)
