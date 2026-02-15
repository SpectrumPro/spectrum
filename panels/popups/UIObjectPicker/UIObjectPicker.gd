# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIObjectPicker extends UIPopup
## Find and selects objects


## Emitted when an object is selected
signal object_selected(p_object: Variant)


## Enum for SelectMode
enum SelectMode {
	OBJECT, 		## Selects a pre-existing object
	CLASS			## Selects a classname
}


## The LineEdit search bar
@export var search_bar: TaggedLineEdit

## The Container to hold all SearchableClassTrees
@export var index_container: Container


## All Indexes shown
var _indexes: RefMap = RefMap.new()

## The current index
var _current_index: SearchableClassTree

## Current select mode
var _select_mode: SelectMode = SelectMode.OBJECT


## Init
func _init() -> void:
	super._init()
	_set_class_name("UIObjectPicker")
	set_custom_accepted_signal(object_selected)


## Ready
func _ready() -> void:
	for script: Script in Interface._object_picker_index:
		var config: ClassTreeConfig = Interface._object_picker_index[script]
		var class_tree: SearchableClassTree = UIDB.instance_component(SearchableClassTree)
		
		class_tree.search_mode_changed.connect(_on_search_mode_changed.bind(class_tree))
		class_tree.object_selected.connect(accept)
		class_tree.class_selected.connect(accept)
		
		class_tree.load_config(config)
		class_tree.hide()
		
		index_container.add_child(class_tree)
		_indexes.map(script, class_tree)
	
	edit_controls.back_button.pressed.connect(_revert_to_class_mode)
	edit_controls.back_button.set_disabled(true)


## Sets the index by base script
func set_index(p_class: Script, p_class_filter: String = "") -> bool:
	if not _indexes.has_left(p_class):
		return false
	
	if _current_index:
		_current_index.hide()
	
	search_bar.clear_tags()
	search_bar.clear()
	
	_current_index = _indexes.left(p_class)
	_current_index.show()
	
	match _select_mode:
		SelectMode.OBJECT:
			_current_index.search_mode_object(p_class_filter)
		SelectMode.CLASS:
			_current_index.search_mode_class(p_class_filter)
	
	return true


## Sets the select mode
func set_select_mode(p_select_mode: SelectMode) -> void:
	_select_mode = p_select_mode
	
	if not is_instance_valid(_current_index):
		return
	
	match _select_mode:
		SelectMode.OBJECT:
			_current_index.search_mode_combined()
			
		SelectMode.CLASS:
			_current_index.search_mode_class()


## Sets the search filter
func search_for(p_text: String) -> void:
	if _current_index:
		_current_index.search_for(p_text)


## Makes this take focus
func focus() -> void:
	search_bar.grab_focus()


## Called when the back button is pressed
func _revert_to_class_mode() -> void:
	if _current_index:
		search_bar.clear_tags()
		_current_index.search_mode_class()
		edit_controls.back_button.set_disabled(true)


## Called when the SearchMode is changed in a SearchableClassTree
func _on_search_mode_changed(p_search_mode: SearchableClassTree.SearchMode, p_class_tree: SearchableClassTree) -> void:
	if p_class_tree != _current_index:
		return
	
	match p_search_mode:
		SearchableClassTree.SearchMode.OBJECT:
			search_bar.clear()
			search_bar.create_tag("@" + p_class_tree.get_object_class())
			
			edit_controls.back_button.set_disabled(false)
			await get_tree().process_frame
			
			search_bar.grab_focus()
			search_bar.edit()
		_:
			edit_controls.back_button.set_disabled(true)


## Called when a tag is removed from the search bar
func _on_line_edit_tag_removed(p_id: Variant) -> void:
	_revert_to_class_mode()


## Called for all GUI inputs on the search bar
func _on_line_edit_gui_input(p_event: InputEvent) -> void:
	if not _current_index:
		return
	
	if p_event.is_action_pressed("ui_down"):
		_current_index.select_next()
	
	if p_event.is_action_pressed("ui_up"):
		_current_index.select_prev()


## Called when text is submitted
func _on_line_edit_text_submitted(_p_new_text: String) -> void:
	if _current_index:
		_current_index.activate_selected()
