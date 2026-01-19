# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICommandPalette extends UIPopup
## CommandPalette


## The LineEdit input
@export var line_edit: TaggedLineEdit

## The Treee for SearchMode.COMMAND
@export var command_tree: Tree


## Enum for SearchMode
enum SearchMode {
	COMMAND,			## Search and run commands
}

## RefMap for TreeItem: SettingsModule
var _command_items: RefMap = RefMap.new()

## Current SearchMode state
var _search_mode: SearchMode = SearchMode.COMMAND


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UISaveLoad")


## Ready
func _ready() -> void:
	command_tree.set_column_expand(1, false)
	command_tree.set_column_custom_minimum_width(1, 50)
	
	_load_command_tree()
	search_for("")


## Searches for a string
func search_for(p_search_string: String) -> void:
	var items_to_display: Array[Dictionary]
	var search_string: String = p_search_string.to_lower()
	var search_tree: Tree = null
	
	match _search_mode:
		SearchMode.COMMAND:
			for classname: String in Interface._palette_search_index:
				for item_name: String in Interface._palette_search_index[classname]:
					items_to_display.append({
						"item_name": item_name,
						"similarity": item_name.similarity(search_string) if p_search_string else 0.0,
						"tree_item": _command_items.right(Interface._palette_search_index[classname][item_name])
					})
			
			search_tree = command_tree
	
	items_to_display.sort_custom(_sort_items.bind(search_string))
	items_to_display.reverse()
	
	for item: Dictionary in items_to_display:
		item.tree_item.move_before(search_tree.get_root().get_child(0))
	
	search_tree.get_root().get_child(0).select(0)
	search_tree.ensure_cursor_is_visible()


## Take focus to the input
func focus() -> void:
	line_edit.grab_focus()


## Activates an item
func activate_item(p_tree_item: TreeItem) -> void:
	match _search_mode:
		SearchMode.COMMAND:
			var module: SettingsModule = _command_items.left(p_tree_item)
			
			match module.get_data_type():
				Data.Type.ACTION:
					module.get_setter().call()
				_:
					Interface.prompt_settings_module(self, module)
	
	accept()


## Ready function for SearchMode.COMMAND
func _load_command_tree() -> void:
	_command_items.clear()
	
	command_tree.clear()
	command_tree.create_item()
	
	for classname: String in Interface._palette_search_index:
		for item_name: String in Interface._palette_search_index[classname]:
			var tree_item: TreeItem = command_tree.create_item()
			var module: SettingsModule = Interface._palette_search_index[classname][item_name]
			
			tree_item.set_text(0, str(classname, ": ", item_name))
			tree_item.set_icon(0, UIDB.get_class_icon(classname))
			
			tree_item.set_custom_color(1, Color(0x919191ff))
			
			match module.get_type():
				SettingsModule.Type.SETTING, SettingsModule.Type.CONTROL when module.get_data_type() == Data.Type.ACTION:
					tree_item.set_text(1, "Run")
					
				SettingsModule.Type.SETTING, SettingsModule.Type.CONTROL when module.get_data_type() != Data.Type.ACTION:
					tree_item.set_text(1, "Edit")
				
				SettingsModule.Type.STATUS:
					tree_item.set_text(1, "View")
			
			_command_items.map(tree_item, module)


## Sorts items
func _sort_items(p_a: Dictionary, p_b: Dictionary, p_search_string: String) -> bool:
	if p_search_string and len(p_search_string) < 3:
		return (p_a.item_name as String).to_lower().begins_with(p_search_string[0])
	elif p_search_string:
		return p_a.similarity > p_b.similarity
	else:
		return p_a.item_name.naturalnocasecmp_to(p_b.item_name) < 0


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


## Called when text is submitted in the list
func _on_line_edit_text_submitted(p_new_text: String) -> void:
	match _search_mode:
		SearchMode.COMMAND:
			if not command_tree.get_selected():
				return
			
			activate_item(command_tree.get_selected())


## Called when the text is changed in the LineEdit
func _on_line_edit_text_changed(p_new_text: String) -> void:
	search_for(p_new_text)


## Called for each GUI input on the lineedit
func _on_line_edit_gui_input(p_event: InputEvent) -> void:
	if p_event.is_action_released("ui_down"):
		_select_next(command_tree)
	
	if p_event.is_action_released("ui_up"):
		_select_prev(command_tree)


## Called when an item is activated in the tree
func _on_command_tree_item_activated() -> void:
	activate_item(command_tree.get_selected())
