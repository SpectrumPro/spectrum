# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ClassListDB extends Node
## Contains a list of all the classes for a given base class


## Contains all the classes sorted by the system hierarchy tree
var _global_class_tree: Dictionary = {}

## Contains all classes sorted by the inheritance tree
var _inheritance_map: Dictionary = {}

## Contains the class tree for each class
var _inheritance_trees: Dictionary = {}

## Contains all the class scripts keyed by the classname
var _script_map: Dictionary = {}

## Contains all the hidden classes that should not be shown to the user
var _hidden_classes: Array = []

## Classes that should always seralize
var _always_searlize_classes: Array[String] = []


func _ready() -> void:
	rebuild_maps(_global_class_tree)


## Builds both the inheritance map and the class script map from the class_tree.
func rebuild_maps(tree: Dictionary) -> void:
	var inheritance_map: Dictionary = {}
	var class_script_map: Dictionary = {}
	var inheritance_trees: Dictionary = {}
	
	for key in tree.keys():
		_process_node(key, tree[key], inheritance_map, inheritance_trees, class_script_map, [key])
	
	_inheritance_map = inheritance_map
	_inheritance_trees = inheritance_trees
	_script_map = class_script_map


## Processes a node in the class_tree.
func _process_node(key: String, node: Variant, inheritance_map: Dictionary, inheritance_trees: Dictionary, class_script_map: Dictionary, current_position: Array) -> void:
	if node is Dictionary:
		for subkey in node.keys():
			var subnode = node[subkey]
			var remove_pos: bool = false
			
			if not current_position or current_position.back() != subkey:
				current_position.push_back(subkey)
				remove_pos = true
			
			if subnode is Dictionary:
				_process_node(subkey, subnode, inheritance_map, inheritance_trees, class_script_map, current_position)
			else:
				class_script_map[subkey] = subnode
				inheritance_trees[subkey] = current_position.duplicate()
				
				for pos_key: String in current_position:
					inheritance_map.get_or_add(pos_key, []).append(subkey)
			
			if remove_pos:
				current_position.pop_back()
	else:
		class_script_map[key] = node


## Returns the class script from the script map, or null if not found
func get_class_script(classname: String) -> Script:
	return _script_map.get(classname, null)


## Checks if a class exists in the map
func has_class(classname: String, match_parent: String = "") -> bool:
	if match_parent:
		return _script_map.has(classname) and _inheritance_map.get(match_parent, {}).has(classname)
	else:
		return _script_map.has(classname)


## Returns a copy of the global class tree
func get_global_class_tree() -> Dictionary:
	return _global_class_tree.duplicate(true)


## Returns a copy of the class inheritance map
func get_inheritance_map() -> Dictionary:
	return _inheritance_map.duplicate(true)


## Returns a copy of the script map
func get_script_map() -> Dictionary:
	return _script_map.duplicate()


## Gets all the classes that extend the given parent class
func get_classes_from_parent(parent_class: String) -> Dictionary:
	return _inheritance_map.get(parent_class, {}).duplicate()


## Returns a copy of a class's inheritance
func get_class_inheritance_tree(classname: String) -> Array:
	return _inheritance_trees.get(classname, []).duplicate()


## Checks if the given class is marked as hidden
func is_class_hidden(classname: String) -> bool:
	return _hidden_classes.has(classname)


## Checks if a class inherits from another class
func does_class_inherit(base_class: String, inheritance: String) -> bool:
	return _inheritance_trees[base_class].has(inheritance)


## Checks if a class should seralize
func should_class_searlize(classname: String) -> bool:
	return _always_searlize_classes.has(classname)
