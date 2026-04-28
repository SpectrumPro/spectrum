# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UISettingsInputActions extends PanelContainer
## Input Action settings.

#
### ItemList for inputactions
#@export var _input_action_tree: Tree
#
### The RemoveInputAction button
#@export var _remove_action_button: Button
#
### The InputActionSettingsComponent
#@export var _input_action_settings: InputActionSettingsComponent
#
#
### All current input action
#var _input_actions: RefMap = RefMap.new()
#
### All current selected input action
#var _selected_actions: Array[InputAction]
#
#
### Loads the input items into the list
#func _ready() -> void:
	#_input_action_tree.create_item()
	#
	#InputServer.input_action_added.connect(_add_input_action)
	#InputServer.input_action_removed.connect(_remove_input_action)
	#
	#for action: InputAction in InputServer.get_input_actions():
		#_add_input_action(action)
#
#
### Adds an InputAction to the list
#func _add_input_action(p_action: InputAction) -> void:
	#var tree_item: TreeItem = _input_action_tree.create_item()
	#
	#p_action.name_changed.connect(func (new_name: String):
		#tree_item.set_text(0, new_name)
	#)
	#
	#tree_item.set_text(0, p_action.get_name())
	#_input_actions.map(p_action, tree_item)
#
#
### Removes an InputAction to the list
#func _remove_input_action(p_action: InputAction) -> void:
	#_input_actions.left(p_action).free()
	#_input_actions.erase_left(p_action)
	#_selected_actions.erase(p_action)
	#_remove_action_button.set_disabled(true)
	#_input_action_settings.set_input_action(null)
#
#
### Called when the AddInputAction button is pressed
#func _on_add_input_action_pressed() -> void:
	#InputServer.create_input_action()
#
#
### Called when the RemoveInputAction button is pressed
#func _on_remove_input_action_pressed() -> void:
	#for action: InputAction in _selected_actions.duplicate():
		#InputServer.remove_input_action(action)
#
#
### Called when an item is selected in the ItemList
#func _on_input_action_tree_multi_selected(item: TreeItem, column: int, selected: bool) -> void:
	#var action: InputAction = _input_actions.right(item)
	#
	#if selected and action not in _selected_actions:
		#_selected_actions.append(action)
	#
	#elif not selected and action in _selected_actions:
		#_selected_actions.erase(action)
		#
	#_remove_action_button.set_disabled(not len(_selected_actions))
	#
	#if selected:
		#_input_action_settings.set_input_action(action)
#
#
### Called when nothing is selected in the ItemList
#func _on_item_list_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	#_input_action_tree.deselect_all()
	#_remove_action_button.set_disabled(true)
	#_input_action_settings.set_input_action(null)
