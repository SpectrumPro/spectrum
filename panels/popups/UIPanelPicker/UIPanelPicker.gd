# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIPanelPicker extends UIPopup
## Picks panel items for the Desk


## Emitted when a panel classname is chosen
signal panel_chosen(p_panel_class: String)


## The Tree for showing all UIPanels in thier categorys
@export var categorised_tree: Tree

## The Tree for showing all panels
@export var panel_tree: Tree

## Min size of the second tree column
@export var column_min_size: int = 110

## The TaggedLineEdit for the search bar
@export var search_bar: TaggedLineEdit

## Current search text
var _search_text: String = ""


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIPanelPicker")
	set_custom_accepted_signal(panel_chosen)


## Ready     
func _ready() -> void:
	categorised_tree.set_column_expand(1, false)
	categorised_tree.set_column_custom_minimum_width(1, column_min_size)
	
	panel_tree.set_column_expand(1, false)
	panel_tree.set_column_custom_minimum_width(1, column_min_size)
	
	_reload_tree()


## Takes focus to this node
func focus() -> void:
	search_bar.grab_focus()
	search_bar.select()


## Searched for the given text
func search_for(p_search_text: String) -> void:
	_search_text = p_search_text
	
	categorised_tree.hide()
	panel_tree.hide()
	
	if _search_text:
		panel_tree.show()
		_search_tree(p_search_text, panel_tree)
		
	else:
		categorised_tree.show()


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
			return (p_a.item_name as String).naturalnocasecmp_to(p_b.item_name) < 0
	)
	
	items_to_display[0].tree_item.select(0)
	items_to_display.reverse()
	
	for item: Dictionary in items_to_display:
		item.tree_item.move_before(p_tree.get_root().get_child(0))
	
	p_tree.ensure_cursor_is_visible()


## Reloads the tree
func _reload_tree() -> void:
	categorised_tree.clear()
	panel_tree.clear()
	
	categorised_tree.create_item()
	panel_tree.create_item()
	
	var sorted_categories: Array = UIDB.get_panel_categories()
	sorted_categories.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	
	for category: String in sorted_categories:
		var category_item: TreeItem = categorised_tree.create_item()
		
		category_item.set_text(0, category)
		category_item.set_icon(0, UIDB.get_class_icon(UIPanel))
		category_item.set_custom_color(0, Color(0x919191ff))
		
		category_item.set_text(1, "Category")
		category_item.set_custom_color(1, Color(0x919191ff))
		
		for panel: String in UIDB.get_panels_in_category(category):
			var categorised_panel_item: TreeItem = category_item.create_child()
			
			categorised_panel_item.set_text(0, panel)
			categorised_panel_item.set_icon(0, UIDB.get_class_icon(panel))
			
			categorised_panel_item.set_text(1, "Panel")
			categorised_panel_item.set_custom_color(1, Color(0x919191ff))
			
			var panel_item: TreeItem = panel_tree.create_item()
			
			panel_item.set_text(0, panel)
			panel_item.set_icon(0, UIDB.get_class_icon(panel))
			
			panel_item.set_text(1, category)
			panel_item.set_custom_color(1, Color(0x919191ff))


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
		var tree: Tree = panel_tree if _search_text else categorised_tree
		
		if p_event.is_action_pressed("ui_down"):
			_select_next(tree)
		
		if p_event.is_action_pressed("ui_up"):
			_select_prev(tree)


## Called when enter is pressed on the search bar
func _on_line_edit_text_submitted(_p_new_text: String) -> void:
	if _search_text:
		_on_panel_tree_item_activated()
	else:
		_on_categorised_tree_item_activated()


## Called when an item is activated in the categorised tree
func _on_categorised_tree_item_activated() -> void:
	var selected: TreeItem = categorised_tree.get_selected()
	
	if not selected or selected.get_parent() == categorised_tree.get_root():
		return
	
	accept(selected.get_text(0))


## Called when an item is added in the panel tree
func _on_panel_tree_item_activated() -> void:
	var selected: TreeItem = panel_tree.get_selected()
	
	if not selected:
		return
	
	accept(selected.get_text(0))
