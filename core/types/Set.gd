# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Set extends RefCounted
## A one-dimensional hash based Array


## The data contained in this set. Stored in the keys
var _set: Dictionary[Variant, Variant] = {}

## The data type of this Set
var _type: int = TYPE_NIL


## Init
func _init(p_data_type: int = TYPE_NIL) -> void:
	_type = p_data_type


## Creates a new RefMap from a Dictionary
static func from(p_array: Array) -> Set:
	var new_set: Set = Set.new()
	
	for item: Variant in p_array:
		new_set.add(item)
		
	return new_set


## Adds a value to this set
func add(p_value: Variant) -> bool:
	if has(p_value):
		return false
	
	_set[p_value] = null
	return true


## Returns true if this Set has the given value
func has(p_value: Variant) -> bool:
	if _type and typeof(p_value) != _type:
		return false
	
	return _set.has(p_value)


## Returns this Set as an Array
func get_as_array() -> Array[Variant]:
	var result: Array = Array([], TYPE_NIL, "", "")
	result.assign(_set.keys())
	
	return result


## Gets this RefMap as a dictonary
func get_as_dict() -> Dictionary[Variant, Variant]:
	return _set.duplicate()


## Returns the data type
func get_data_type() -> int:
	return _type


## Clears the RefMap
func clear() -> void:
	_set.clear()


## Returns this Set as a string
func _to_string() -> String:
	return str(_set.keys())
