# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIParameterFunctionList extends UIPopup
## Picker for Parameter Functions


## Emitted when a functions is chosen
signal function_chosen(function: String)


## ItemList for function
@export var function_tree: Tree

## The TaggedLineEdit
@export var search_bar: TaggedLineEdit


## RefMap for Function: TreeItem
var _functions: RefMap = RefMap.new()

## The given fixtures
var _fixtures: Array[Fixture]

## The parameter filter
var _parameter: String = ""


## Sets the fixtures to show thier functions
func set_fixtures(p_fixtures: Array[Fixture], p_parameter: String) -> void:
	_functions.clear()
	_fixtures = p_fixtures.duplicate()
	_parameter = p_parameter
	
	function_tree.clear()
	function_tree.create_item()
	
	if not _fixtures.size():
		return
	
	for fixture: Fixture in _fixtures:
		if not fixture.has_parameter(Fixture.RootZone, p_parameter):
			continue
		
		for function: String in fixture.get_parameter_functions(Fixture.RootZone, p_parameter):
			if _functions.has_left(function):
				continue
			
			var item: TreeItem = function_tree.create_item()
			
			item.set_text(0, function)
			_functions.map(function, item)


## Searches for the given text
func search_for(p_search_text: String) -> void:
	_search_tree(p_search_text, function_tree)


## Focuses this node
func focus() -> void:
	search_bar.grab_focus()
	search_bar.select()


## Gets the fixtures
func get_fixtures() -> Array[Fixture]:
	return _fixtures.duplicate()


## Gets the parameter
func get_parameter() -> String:
	return _parameter


## Searches for the given text in the given tree
func _search_tree(p_search_text: String, p_tree: Tree) -> void:
	var items_to_display: Array[Dictionary]
	
	for item: TreeItem in p_tree.get_root().get_children():
		var item_name: String = item.get_text(0).to_lower()
		items_to_display.append({
			"item_name": item_name,
			"similarity": item_name.similarity(p_search_text) if p_search_text else 0.0,
			"tree_item": item,
		})
	
	items_to_display.sort_custom(func (p_a: Dictionary, p_b: Dictionary) -> bool:
		if p_search_text:
			return p_a.similarity > p_b.similarity
		else:
			return (p_a.item_name as String).naturalnocasecmp_to(p_b.item_name)
	)
	
	items_to_display[0].tree_item.select(0)
	items_to_display.reverse()
	
	for item: Dictionary in items_to_display:
		item.tree_item.move_before(p_tree.get_root().get_child(0))
	
	p_tree.ensure_cursor_is_visible()


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


## Called for all GUI inputs on the search bar
func _on_line_edit_gui_input(p_event: InputEvent) -> void:
	if not p_event.is_action_type():
		return
	
	if p_event.is_action_pressed("ui_down") or p_event.is_action_pressed("ui_up"):
		if p_event.is_action_pressed("ui_down"):
			_select_next(function_tree)
		
		if p_event.is_action_pressed("ui_up"):
			_select_prev(function_tree)


## Called when text is submitted in the search bar
func _on_line_edit_text_submitted(new_text: String) -> void:
	_on_tree_item_activated()


## Called when an item is acitvated in the tree
func _on_tree_item_activated() -> void:
	var selected: TreeItem = function_tree.get_selected()
	
	if not is_instance_valid(selected):
		return
	
	accept(selected.get_text(0))
