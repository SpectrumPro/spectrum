# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIManifestSelector extends UIPopup
## Find and selects objects


## Emitted when a manifest is selected
signal manifest_selected(manifest_uuid: String, mode: String)


## The Tree to show all manifests
@export var manifest_tree: Tree

## The Tree to show all manufacturers
@export var manufacturer_tree: Tree

## The Tree to show all fixtures
@export var global_fixture_tree: Tree

## The tree to show all fixtures by a given manufacturer
@export var manufacturer_fixture_tree: Tree

## The Tree to show all modes
@export var mode_tree: Tree

## The panel tp show the manufacturer tree is selected
@export var manufacturer_tree_select_box: Panel

## The panel tp show the fixture tree is selected
@export var fixture_tree_select_box: Panel

## The LineEdit for the search bar
@export var search_bar: TaggedLineEdit

## Min size of the second tree column
@export var column_min_size: int = 150


## Enum for SearchMode
enum SearchMode {
	SEARCH,
	MANUFACTURER_FILTER,
	MODE_SELECT,
}

## Number of searched items to show
const REORDER_AMOUNT: int = 10

## Contains all manifest info from FixtureLibaray
var _manifest_info: Dictionary[String, Dictionary] = {}

## RefMap for Dictionary: Tree
var _fixture_tree_manifest_items: RefMap = RefMap.new()

## RefMap for Dictionary: Tree
var _manufacturer_fixture_tree_manifest_items: RefMap = RefMap.new()

## The current selected FixtureManifest as a Dictionary
var _selected_manifest: Dictionary

## The selected manufacturer when using SearchMode.MANUFACTURER_FILTER
var _selected_manufacturer: String = ""

## The current active tree
var _search_mode: SearchMode = SearchMode.SEARCH

## Current search text
var _search_text: String = ""

## Thread for search
var _search_thread: Thread = Thread.new()

## The current selected tree in SearchMode.SEARCH
var _search_mode_search_active_tree: Tree


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIManifestPicker")
	set_custom_accepted_signal(manifest_selected)


## Ready
func _ready() -> void:
	super._ready()
	
	manifest_tree.set_column_expand(1, false)
	manifest_tree.set_column_custom_minimum_width(1, column_min_size)
	
	manufacturer_tree.set_column_expand(1, false)
	manufacturer_tree.set_column_custom_minimum_width(1, column_min_size / 4)
	
	global_fixture_tree.set_column_expand(1, false)
	global_fixture_tree.set_column_custom_minimum_width(1, column_min_size / 2)
	
	manufacturer_fixture_tree.set_column_expand(1, false)
	manufacturer_fixture_tree.set_column_custom_minimum_width(1, column_min_size / 2)
	
	mode_tree.set_column_expand(1, false)
	mode_tree.set_column_custom_minimum_width(1, column_min_size / 2)
	
	_search_mode_search_active_tree = global_fixture_tree
	fixture_tree_select_box.show()
	
	get_edit_controls().back_button.pressed.connect(go_back)
	
	FixtureLibrary.manifests_found.connect(_load_manifests)
	_load_manifests()


## Takes focus
func focus() -> void:
	search_bar.grab_focus()


## Sets the search mode to SearchMode.SEARCH and displays all fixtuers and manufacturers
func search_mode_default() -> void:
	_search_mode = SearchMode.SEARCH
	get_edit_controls().set_show_back(false)
	
	search_bar.clear_all()
	search_for("")


## Sets the search mode to MANUFACTURER_FILTER and displays all fixtures by that manufacturer
func search_mode_manufacturer(p_manufacturer: String) -> void:
	if p_manufacturer not in _manifest_info.keys():
		return
	
	_search_mode = SearchMode.MANUFACTURER_FILTER
	_selected_manufacturer = p_manufacturer
	
	_manufacturer_fixture_tree_manifest_items.clear()
	manufacturer_fixture_tree.clear()
	manufacturer_fixture_tree.create_item()
	
	var sorted_fixtures: Array = _manifest_info[_selected_manufacturer].keys()
	sorted_fixtures.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	
	for fixture: String in sorted_fixtures:
		var fixture_item: TreeItem = manufacturer_fixture_tree.create_item()
		
		fixture_item.set_text(0, fixture)
		fixture_item.set_icon(0, preload("res://assets/icons/Fixture.svg"))
		
		fixture_item.set_custom_color(1, Color(0x919191ff))
		fixture_item.set_text(1, str(len(_manifest_info[_selected_manufacturer][fixture].modes)) + " Modes")
		
		_manufacturer_fixture_tree_manifest_items.map(_manifest_info[_selected_manufacturer][fixture], fixture_item)
	
	search_bar.clear_all()
	search_bar.create_tag("@" + p_manufacturer)
	
	get_edit_controls().set_show_back(true)
	search_for("")


## Sets the search mode to SearchMode.MODE_SELECT and displayes all the modes in a given fixture
func search_mode_mode_select(p_manufacturer: String, p_fixture: String) -> void:
	if not _manifest_info.has(p_manufacturer) or not _manifest_info[p_manufacturer].has(p_fixture):
		return
	
	_search_mode = SearchMode.MODE_SELECT
	_selected_manufacturer = p_manufacturer
	_selected_manifest = _manifest_info[p_manufacturer][p_fixture]
	
	mode_tree.clear()
	mode_tree.create_item()
	
	var sorted_modes: Array = _selected_manifest.modes.keys()
	sorted_modes.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	
	for mode: String in sorted_modes:
		var mode_item: TreeItem = mode_tree.create_item()
		
		mode_item.set_text(0, mode)
		mode_item.set_icon(0, preload("res://assets/icons/DMXOutput.svg"))
		
		mode_item.set_custom_color(1, Color(0x919191ff))
		mode_item.set_text(1, str(_selected_manifest.modes[mode]) + " CH")
	
	search_bar.clear_all()
	search_bar.create_tag("@" + p_manufacturer + "/" + p_fixture)
	
	get_edit_controls().set_show_back(true)
	search_for("")


## Goes back a in the search mode
func go_back():
	match _search_mode:
		SearchMode.MANUFACTURER_FILTER:
			search_mode_default()
		SearchMode.MODE_SELECT:
			search_mode_manufacturer(_selected_manufacturer)


## Searched for the given text
func search_for(p_search_text: String) -> void:
	manifest_tree.hide()
	manufacturer_tree.hide()
	global_fixture_tree.hide()
	manufacturer_fixture_tree.hide()
	mode_tree.hide()
	
	_search_text = p_search_text
	
	match _search_mode:
		SearchMode.SEARCH:
			if not p_search_text:
				manifest_tree.show()
				return
			
			manufacturer_tree.show()
			global_fixture_tree.show()
			
			if _search_thread.is_alive():
				_search_thread.wait_to_finish()
			
			_search_thread.start(func () -> void:
				_search_tree(p_search_text.to_lower(), manufacturer_tree)
				_search_tree(p_search_text.to_lower(), global_fixture_tree)
			)
			_search_thread.wait_to_finish()
		
		SearchMode.MANUFACTURER_FILTER:
			manufacturer_fixture_tree.show()
			
			if _search_thread.is_alive():
				_search_thread.wait_to_finish()
			
			_search_thread.start(func () -> void:
				_search_tree(p_search_text.to_lower(), manufacturer_fixture_tree, false)
			)
			_search_thread.wait_to_finish()
		
		SearchMode.MODE_SELECT:
			mode_tree.show()
			
			if _search_thread.is_alive():
				_search_thread.wait_to_finish()
			
			_search_thread.start(func () -> void:
				_search_tree(p_search_text.to_lower(), mode_tree, false)
			)
			_search_thread.wait_to_finish()


## Searches for the given text in the given tree
func _search_tree(p_search_text: String, p_tree: Tree, p_use_limit: bool = true) -> void:
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
	
	(func () -> void:
		items_to_display[0].tree_item.select(0)
		
		if p_use_limit:
			items_to_display = items_to_display.slice(0, REORDER_AMOUNT)
		
		items_to_display.reverse()
		
		for item: Dictionary in items_to_display:
			item.tree_item.move_before(p_tree.get_root().get_child(0))
		
		p_tree.ensure_cursor_is_visible()
	).call_deferred()
	


## Loads all manifests
func _load_manifests() -> void:
	manifest_tree.clear()
	global_fixture_tree.clear()
	mode_tree.clear()
	search_bar.clear()
	
	manifest_tree.create_item()
	global_fixture_tree.create_item()
	mode_tree.create_item()
	
	_fixture_tree_manifest_items.clear()
	_manifest_info = FixtureLibrary.get_sorted_manifest_info()
	
	var sorted_manufacturers: Array = _manifest_info.keys()
	sorted_manufacturers.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	
	for manufacturer: String in sorted_manufacturers:
		var manufacturer_item: TreeItem = manifest_tree.create_item()
		
		manufacturer_item.set_text(0, manufacturer)
		manufacturer_item.set_icon(0, preload("res://modules/Vertex/assets/icons/Factory.svg"))
		
		manufacturer_item.set_custom_color(1, Color(0x919191ff))
		manufacturer_item.set_text(1, "Manufacturer")
		
		manufacturer_item.set_collapsed(true)
		
		var manufacturer_tree_manufacturer_item: TreeItem = manufacturer_tree.create_item()
			
		manufacturer_tree_manufacturer_item.set_text(0, manufacturer)
		manufacturer_tree_manufacturer_item.set_icon(0, preload("res://modules/Vertex/assets/icons/Factory.svg"))
		
		manufacturer_tree_manufacturer_item.set_custom_color(1, Color(0x919191ff))
		manufacturer_tree_manufacturer_item.set_text(1, str(len(_manifest_info[manufacturer])))
		
		var sorted_fixtures: Array = _manifest_info[manufacturer].keys()
		sorted_fixtures.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
		
		for fixture: String in sorted_fixtures:
			var manifest_tree_fixture_item: TreeItem = manufacturer_item.create_child()
			
			manifest_tree_fixture_item.set_text(0, fixture)
			manifest_tree_fixture_item.set_icon(0, preload("res://assets/icons/Fixture.svg"))
			
			manifest_tree_fixture_item.set_custom_color(1, Color(0x919191ff))
			manifest_tree_fixture_item.set_text(1, "FixtureManifest")
			
			var fixture_tree_fixture_item: TreeItem = global_fixture_tree.create_item()
			
			fixture_tree_fixture_item.set_text(0, fixture)
			fixture_tree_fixture_item.set_icon(0, preload("res://assets/icons/Fixture.svg"))
			
			fixture_tree_fixture_item.set_custom_color(1, Color(0x919191ff))
			fixture_tree_fixture_item.set_text(1, manufacturer)
			
			_fixture_tree_manifest_items.map(_manifest_info[manufacturer][fixture], fixture_tree_fixture_item)


## Called for all GUI inputs on the search bar
func _on_line_edit_gui_input(p_event: InputEvent) -> void:
	if not p_event.is_action_type():
		return
	
	if p_event.is_action_pressed("ui_down") or p_event.is_action_pressed("ui_up"):
		var trees: Array[Tree]
		
		match _search_mode:
			SearchMode.SEARCH when not _search_text:
				trees = [manifest_tree]
			
			SearchMode.SEARCH when _search_text:
				trees = [manufacturer_tree, global_fixture_tree]
			
			SearchMode.MANUFACTURER_FILTER:
				trees = [manufacturer_fixture_tree]
			
			SearchMode.MODE_SELECT:
				trees = [mode_tree]
		
		for tree: Tree in trees:
			if p_event.is_action_pressed("ui_down"):
				_select_next(tree)
			
			if p_event.is_action_pressed("ui_up"):
				_select_prev(tree)
		
	elif p_event.is_action_pressed("ui_left") and _search_mode == SearchMode.SEARCH:
		fixture_tree_select_box.hide()
		manufacturer_tree_select_box.show()
		_search_mode_search_active_tree = manufacturer_tree
		
	elif p_event.is_action_pressed("ui_right") and _search_mode == SearchMode.SEARCH:
		manufacturer_tree_select_box.hide()
		fixture_tree_select_box.show()
		_search_mode_search_active_tree = global_fixture_tree


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


## Called when focus is lost on the search bar
func _on_line_edit_focus_exited() -> void:
	manufacturer_tree_select_box.hide()
	fixture_tree_select_box.hide()


## Called when focus is taken on the search bar
func _on_line_edit_focus_entered() -> void:
	if _search_mode_search_active_tree == manufacturer_tree:
		manufacturer_tree_select_box.show()
	else:
		fixture_tree_select_box.show()


## Called when the entre key is pressed on the search bar
func _on_line_edit_text_submitted(new_text: String) -> void:
	match _search_mode:
		SearchMode.SEARCH when _search_mode_search_active_tree == manufacturer_tree and _search_text:
			_on_manufacturer_tree_item_activated()
		
		SearchMode.SEARCH when _search_mode_search_active_tree == global_fixture_tree and _search_text:
			_on_global_fixture_tree_item_activated()
		
		SearchMode.SEARCH when not _search_text:
			_on_manifest_tree_item_activated()
		
		SearchMode.MANUFACTURER_FILTER:
			_on_manufacturer_fixture_tree_item_activated()
		
		SearchMode.MODE_SELECT:
			_on_mode_tree_item_activated()


## Called when a tag is removed from the search bar
func _on_line_edit_tag_removed(p_id: Variant) -> void:
	go_back()


## Called when an item is activated in the manifest tree
func _on_manifest_tree_item_activated() -> void:
	var selected: TreeItem = manifest_tree.get_selected()
	
	if not selected:
		return
	
	if selected.get_parent() == manifest_tree.get_root():
		search_mode_manufacturer(selected.get_text(0))
	
	else:
		search_mode_mode_select(selected.get_parent().get_text(0), selected.get_text(0))


## Called when an item is activated in the manufacturer tree
func _on_manufacturer_tree_item_activated() -> void:
	var selected: TreeItem = manufacturer_tree.get_selected()
	
	if not selected:
		return
	
	search_mode_manufacturer(selected.get_text(0))


## Called when an item is activated in the global fixture tree
func _on_global_fixture_tree_item_activated() -> void:
	var selected: TreeItem = global_fixture_tree.get_selected()
	
	if not selected:
		return
	
	var manifest: Dictionary = _fixture_tree_manifest_items.right(selected)
	search_mode_mode_select(manifest.manufacturer, selected.get_text(0))


## Called when an item is activated in the manufacturer fixture tree
func _on_manufacturer_fixture_tree_item_activated() -> void:
	var selected: TreeItem = manufacturer_fixture_tree.get_selected()
	
	if not selected:
		return
	
	search_mode_mode_select(_selected_manufacturer, selected.get_text(0))


## Called when an item is activated in the mode tree
func _on_mode_tree_item_activated() -> void:
	var selected: TreeItem = mode_tree.get_selected()
	
	if not selected:
		return
	
	var mode: String = selected.get_text(0)
	
	manifest_selected.emit(_selected_manifest.uuid, mode)
	accepted.emit()
