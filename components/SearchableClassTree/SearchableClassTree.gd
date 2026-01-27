# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SearchableClassTree extends UIComponent
## A tree containing a list of classes that are searchable


## Emitted when the SearchMode is changed
signal search_mode_changed(mode: SearchMode)

## Emitted when an object is selected
signal object_selected(object: Object)

## Emitted when a class is selected
signal class_selected(classname: String)


## Enum for SearchMode
enum SearchMode {
	CLASS,		## Searching for classes
	OBJECT,		## Searching for objects with a given class
	COMBINED,	## Both class and object
}


## The InheritanceTree
@export var inheritance_tree: Tree

## The SearchableInheritanceTree 
@export var searchable_inheritance_tree: Tree

## The SearchableTree
@export var searchable_tree: Tree

## The ObjectTree
@export var object_tree: Tree

## Min size of the second tree column
@export var column_min_size: int = 100


## The ClassTreeConfig
var _config: ClassTreeConfig

## RefMap for TreeItem: "ClassName"
var _class_items: RefMap = RefMap.new()

## RefMap for TreeItem: Object
var _object_items: RefMap = RefMap.new()

## The null item in the inheritance_tree
var _inheritance_tree_null: TreeItem

## All tree nulls
var _tree_nulls: RefMap

## Current search mode
var _search_mode: SearchMode = SearchMode.COMBINED

## The classname of SearchMode.OBJECT
var _search_mode_object_class: String = ""

## The class filter when using SearchMode.CLASS
var _search_mode_class_filter: String = ""

## The current search text
var _search_text: String = ""


## Init
func _init() -> void:
	super._init()
	_set_class_name("SeachableClassTreee")


## Ready
func _ready() -> void:
	_tree_nulls = RefMap.from({
		inheritance_tree: null,
		searchable_inheritance_tree: null,
		searchable_tree: null,
		object_tree: null,
	})
	
	_tree_nulls.get_left().map(func (tree: Tree):
		tree.set_column_expand(1, false)
		tree.set_column_custom_minimum_width(1, column_min_size)
	)


## Gets the selected object class for SearchMode.OBJECT
func get_object_class() -> String:
	return _search_mode_object_class


## Gets the filter used for SearchMode.CLASS
func get_class_filter() -> String:
	return _search_mode_class_filter


## Focuses the current Tree
func focus() -> void:
	_get_active_tree().grab_focus()


## Selectes the next item in the tree
func select_next() -> void:
	var tree: Tree = _get_active_tree()
	var current: TreeItem = tree.get_selected()
	var next_item: TreeItem = current.get_next_visible(true) if current else tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	tree.ensure_cursor_is_visible()


## Selectes the next item in the tree
func select_prev() -> void:
	var tree: Tree = _get_active_tree()
	var current: TreeItem = tree.get_selected()
	var next_item: TreeItem = current.get_prev_visible(true) if current else tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	tree.ensure_cursor_is_visible()


## Activates the selected TreeItem
func activate_selected() -> void:
	var tree: Tree = _get_active_tree()
	var selected: TreeItem = tree.get_selected()
	
	if not selected or selected == tree.get_root():
		return
	
	if _tree_nulls.has_right(selected):
		object_selected.emit(null)
	
	match _search_mode:
		SearchMode.COMBINED:
			search_mode_object(selected.get_text(0))
		
		SearchMode.CLASS:
			class_selected.emit(selected.get_text(0))
		
		SearchMode.OBJECT:
			object_selected.emit(_object_items.left(selected))


## Loads a ClassTreeConfig
func load_config(p_config: ClassTreeConfig) -> void:
	_config = p_config
	
	inheritance_tree.clear()
	searchable_inheritance_tree.clear()
	searchable_tree.clear()
	
	inheritance_tree.create_item()
	searchable_inheritance_tree.create_item()
	searchable_tree.create_item()
	
	_inheritance_tree_null = inheritance_tree.get_root().create_child()
	_inheritance_tree_null.set_text(0, "null")
	_inheritance_tree_null.set_text(1, "Empty")
	_inheritance_tree_null.set_icon(0, UIDB.get_class_icon("null"))
	
	_climb_branch_tree.call(inheritance_tree.get_root(), p_config.get_class_tree(), p_config.get_class_tree().keys()[0])
	
	var inheritance_map: Dictionary = p_config.get_inheritance_map()
	
	for parent_class: String in inheritance_map.keys():
		if _config.is_class_hidden(parent_class):
			continue
		
		var parent_branch = searchable_inheritance_tree.create_item()
		
		parent_branch.set_text(0, parent_class)
		parent_branch.set_icon(0, UIDB.get_class_icon(parent_class))
		
		parent_branch.set_custom_color(1, Color(0x919191ff))
		parent_branch.set_text(1, "Enter")
		
		for child_class: String in inheritance_map[parent_class]:
			if _config.is_class_hidden(child_class):
				continue
			
			var child_branch = parent_branch.create_child()
			
			child_branch.set_text(0, child_class)
			child_branch.set_icon(0, UIDB.get_class_icon(child_class))
			
			child_branch.set_custom_color(1, Color(0x919191ff))
			child_branch.set_text(1, "Enter")


## Gets the loaded config
func get_config() -> ClassTreeConfig:
	return _config


## Sets the search mode to SearchMode.CLASS
func search_mode_class(p_class_filter: String = "") -> void:
	_search_mode = SearchMode.CLASS
	_search_mode_class_filter = p_class_filter
	
	search_for("")
	search_mode_changed.emit(_search_mode)


## Sets the search mode to SearchMode.CLASS
func search_mode_combined() -> void:
	_search_mode = SearchMode.COMBINED
	
	search_for("")
	search_mode_changed.emit(_search_mode)


## Sets the search mode to SearchMode.OBJECT
func search_mode_object(p_classname: String) -> void:
	_search_mode = SearchMode.OBJECT
	_search_mode_object_class = p_classname
	
	object_tree.clear()
	object_tree.create_item()
	_object_items.clear()
	
	for object: Object in _config.get_objects_by_classname(p_classname):
		var classname: String = _config.get_object_classname(object)
		if _config.is_class_hidden(classname):
			continue
		
		var item: TreeItem = object_tree.create_item()
		
		item.set_text(0, _config.get_object_name(object))
		item.set_icon(0, UIDB.get_class_icon(classname))
		
		item.set_custom_color(1, Color(0x919191ff))
		item.set_text(1, "Use")
		
		_object_items.map(item, object)
	
	search_for("")
	search_mode_changed.emit(_search_mode)


## Searches for the given text
func search_for(p_text: String) -> void:
	var items_to_display: Array[Dictionary]
	var search_string: String = p_text.to_lower()
	var search_tree: Tree = null
	var item_to_select: TreeItem = null
	
	object_tree.hide()
	searchable_tree.hide()
	searchable_inheritance_tree.hide()
	inheritance_tree.hide()
	
	match _search_mode:
		SearchMode.CLASS when p_text == "":
			searchable_inheritance_tree.show()
			search_tree = searchable_inheritance_tree
			
			for item: TreeItem in searchable_inheritance_tree.get_root().get_children():
				if item.get_text(0) == _search_mode_class_filter and _search_mode_class_filter:
					item_to_select = item
					item.set_visible(true)
				else:
					item.set_visible(false)
			
		SearchMode.COMBINED, SearchMode.CLASS:
			if not p_text:
				inheritance_tree.show()
				return
			
			searchable_tree.show()
			search_tree = searchable_tree
			
			for classname: String in _class_items.get_right():
				var show: bool = _search_mode == SearchMode.CLASS and _config.does_class_extend(classname, _search_mode_class_filter)
				items_to_display.append({
					"item_name": classname,
					"similarity": classname.similarity(search_string) if p_text else 0.0,
					"tree_item": _class_items.right(classname),
					"show": show
				})
		
		SearchMode.OBJECT:
			object_tree.show()
			search_tree = object_tree
			
			for object: Object in _object_items.get_right():
				var object_name: String = _config.get_object_name(object)
				items_to_display.append({
					"item_name": object_name,
					"similarity": object_name.similarity(search_string) if p_text else 0.0,
					"tree_item": _object_items.right(object),
					"show": true
				})
	
	items_to_display.sort_custom(func (p_a: Dictionary, p_b: Dictionary) -> bool:
		if search_string and len(search_string) < 3:
			return (p_a.item_name as String).to_lower().begins_with(search_string[0])
		elif search_string:
			return p_a.similarity > p_b.similarity
		else:
			return (p_a.item_name as String).naturalnocasecmp_to(p_b.item_name)
	)
	items_to_display.reverse()
	
	for item: Dictionary in items_to_display:
		item.tree_item.move_before(search_tree.get_root().get_child(0))
		item.tree_item.set_visible(item.show)
	
	if item_to_select:
		item_to_select.select(0)
		search_tree.ensure_cursor_is_visible()
	
	elif search_tree.get_root().get_child_count():
		search_tree.get_root().get_child(0).select(0)
		search_tree.ensure_cursor_is_visible()
	
	_show_null()
	_search_text = search_string


## Shows a "null" item on each tree
func _show_null() -> void:
	for tree: Tree in _tree_nulls.get_left():
		if not _tree_nulls.left(tree):
			var new_null: TreeItem = tree.create_item()
			
			new_null.set_text(0, "null")
			new_null.set_text(1, "Empty")
			new_null.set_icon(0, UIDB.get_class_icon("null"))
			
			_tree_nulls.map(tree, new_null)
		
		var tree_null: TreeItem = _tree_nulls.left(tree)
		tree_null.set_visible(true)
		
		if tree.get_root().get_children():
			tree_null.move_before(tree.get_root().get_child(0))


## Climbs a branch on the class tree
func _climb_branch_tree(p_tree_branch: TreeItem, p_data_branch: Dictionary, p_previous_classname: String) -> void:
	for classname: String in p_data_branch.keys():
		if _config.is_class_hidden(classname):
			continue
		
		var value: Variant = p_data_branch[classname]
		var new_branch = p_tree_branch.create_child()
		
		new_branch.set_text(0, classname)
		new_branch.set_icon(0, UIDB.get_class_icon(classname))
		
		new_branch.set_custom_color(1, Color(0x919191ff))
		new_branch.set_text(1, "Enter")
		
		if value is Dictionary:
			_climb_branch_tree.call(new_branch, value, classname)
		
		elif value is Script:
			var flat_item: TreeItem = searchable_tree.create_item()
			
			flat_item.set_text(0, classname)
			flat_item.set_icon(0, UIDB.get_class_icon(classname))
			
			flat_item.set_custom_color(1, Color(0x919191ff))
			flat_item.set_text(1, p_previous_classname)
			
			_class_items.map(flat_item, classname)


## Gets the active tree
func _get_active_tree() -> Tree:
	match _search_mode:
		SearchMode.CLASS, SearchMode.COMBINED when _search_text:
			return searchable_tree
		
		SearchMode.CLASS:
			return searchable_inheritance_tree
		
		SearchMode.COMBINED:
			return inheritance_tree
		
		_:
			return object_tree
