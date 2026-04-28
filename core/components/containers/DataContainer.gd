# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataContainer extends EngineComponent
## DataContainer stores fixture data


## Emitted when ContainerItems are stored
signal items_stored(items: Array)

## Emitted when ContainerItems are erased
signal items_erased(items: Array)

## Emitted when the function is changed in mutiple ContainerItems
signal items_function_changed(items: Array, function: String)

## Emitted when the value is changed in mutiple ContainerItems
signal items_value_changed(items: Array, value: float)

## Emitted when the can_fade state is changed in mutiple ContainerItems
signal items_can_fade_changed(items: Array, can_fade: bool)

## Emitted when the start point is changed in mutiple ContainerItems
signal items_start_changed(items: Array, start: float)

## Emitted when the stop point is changed in mutiple ContainerItems
signal items_stop_changed(items: Array, stop: float)


## All ContainerItems
var _items: Array[ContainerItem]

## All fixtures stored as { Fixture: { zone: { parameter: ContainerItem } } }
var _fixtures: Dictionary[Fixture, Dictionary]


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_name("DataContainer")
	_set_class_name("DataContainer")
	
	_settings.register_networked_callbacks({
		"on_items_stored": _store_items,
		"on_items_erased": _erase_items,
		"on_items_function_changed": _set_function,
		"on_items_value_changed": _set_value,
		"on_items_can_fade_changed": _set_can_fade,
		"on_items_start_changed": _set_start,
		"on_items_stop_changed": _set_stop,
	})
	
	_settings.set_callback_allow_deserialize("on_items_stored")


## Gets all the ContainerItems
func get_items() -> Array[ContainerItem]:
	return _items.duplicate()


## Returns all fixture in this DataContainer
func get_fixtures() -> Array[Fixture]:
	var result: Array[Fixture]
	result.assign(_fixtures.keys())
	
	return result


## Returns all the data
func get_data() -> Dictionary[Fixture, Dictionary]:
	return _fixtures


## Gets an item by fixture, zone, and parameter
func get_item(p_fixture: Fixture, p_zone: String, p_parameter: String) -> ContainerItem:
	if not _fixtures.has(p_fixture):
		return null
	
	var container: ContainerItem = _fixtures.get(p_fixture, {}).get(p_zone, {}).get(p_parameter, null)

	if not is_instance_valid(container):
		return null
	
	return container


## Gets all the data for a given fixture, stored as { zone: { parameter: ContainerItem } }
func get_data_for(p_fixture: Fixture) -> Dictionary[String, Dictionary]:
	var result: Dictionary[String, Dictionary]
	result.assign(_fixtures.get(p_fixture, {}).duplicate(true))
	
	return result


## Stores data into this DataContainer
func store_data(p_fixture: Fixture, p_zone: String, p_parameter: String, p_function: String, p_value: float, p_can_fade: bool = true, p_start: float = 0.0, p_stop: float = 1.0) -> Promise:
	return rpc("store_data", [p_fixture, p_zone, p_parameter, p_function, p_value, p_can_fade, p_start, p_stop])


## Erases data
func erase_data(p_fixture: Fixture, p_zone: String, p_parameter: String) -> Promise:
	return rpc("erase_data", [p_fixture, p_zone, p_parameter])
	

## Stores a ContainerItem
func store_item(p_item: ContainerItem) -> Promise:
	return rpc("store_item", [p_item])


## Stores mutiple items at once
func store_items(p_items: Array) -> Promise:
	return rpc("store_items", [p_items])


## Erases an item
func erase_item(p_item: ContainerItem) -> Promise:
	return rpc("erase_item", [p_item])


## Erases mutiple items at once
func erase_items(p_items: Array) -> Promise:
	return rpc("erase_items", [p_items])


## Sets the function of mutiple items
func set_function(p_items: Array, p_function: String) -> Promise:
	return rpc("set_function", [p_items, p_function])


## Sets the value of mutiple items
func set_value(p_items: Array, p_value: float) -> Promise:
	return rpc("set_value", [p_items, p_value])


## Sets the value of mutiple items
func set_can_fade(p_items: Array, p_can_fade: bool) ->Promise:
	return rpc("set_can_fade", [p_items, p_can_fade])


## Sets the value of mutiple items
func set_start(p_items: Array, p_start: float) -> Promise:
	return rpc("set_start", [p_items, p_start])


## Sets the value of mutiple items
func set_stop(p_items: Array, p_stop: float) -> Promise:
	return rpc("set_stop", [p_items, p_stop])


## Handles delete requests
func delete() -> void:
	for item: ContainerItem in _items:
		item.delete()
	
	super.delete()


## Serializes this Datacontainer and returnes it in a dictionary
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged(_serialize())


## Loads this DataContainer from a dictonary
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	_load(p_serialized_data)


## Internal: Stores a ContainerItem
func _store_item(p_item: ContainerItem, no_signal: bool = false) -> bool:
	if not p_item or p_item in _items or not p_item.is_valid():
		return false
	
	_items.append(p_item)
	_fixtures.get_or_add(p_item.get_fixture(), {}).get_or_add(p_item.get_zone(), {})[p_item.get_parameter()] = p_item

	ComponentDB.register_component(p_item)
	p_item.delete_requested.connect(_erase_item)

	if not no_signal:
		items_stored.emit([p_item])
	
	return true


## Internal: Stores mutiple items at once
func _store_items(p_items: Array) -> void:
	var just_added_items: Array[ContainerItem]

	for item: Variant in p_items:
		if item is ContainerItem:
			if _store_item(item, true):
				just_added_items.append(item)
	
	if just_added_items:
		items_stored.emit(just_added_items)


## Internal: Erases an item
func _erase_item(p_item: ContainerItem, no_signal: bool = false) -> bool:
	if not p_item or p_item not in _items:
		return false
	
	_items.erase(p_item)
	p_item.delete_requested.disconnect(_erase_item)
	_fixtures[p_item.get_fixture()][p_item.get_zone()].erase(p_item.get_parameter())
	
	if not _fixtures[p_item.get_fixture()][p_item.get_zone()]:
		_fixtures[p_item.get_fixture()].erase(p_item.get_zone())
		
		if not _fixtures[p_item.get_fixture()]:
			_fixtures.erase(p_item.get_fixture())
	
	if not no_signal:
		items_erased.emit([p_item])
	
	return true


## Internal: Erases mutiple items at once
func _erase_items(p_items: Array) -> void:
	var just_erased_items: Array[ContainerItem]

	for item: Variant in p_items:
		if item is ContainerItem:
			if _erase_item(item, true):
				just_erased_items.append(item)
	
	if just_erased_items:
		items_erased.emit(just_erased_items)


## Internal: Sets the function of mutiple items
func _set_function(p_items: Array, p_function: String) -> void:
	var changed_items: Array[ContainerItem]

	for item: Variant in p_items:
		if item is ContainerItem:
			if item.set_function(p_function):
				changed_items.append(item)
	
	if changed_items:
		items_function_changed.emit(changed_items, p_function)


## Internal: Sets the value of mutiple items
func _set_value(p_items: Array, p_value: float) -> void:
	var changed_items: Array[ContainerItem]

	for item: Variant in p_items:
		if item is ContainerItem:
			if item.set_value(p_value):
				changed_items.append(item)
	
	if changed_items:
		items_value_changed.emit(changed_items, p_value)


## Internal: Sets the value of mutiple items
func _set_can_fade(p_items: Array, p_can_fade: bool) -> void:
	var changed_items: Array[ContainerItem]

	for item: Variant in p_items:
		if item is ContainerItem:
			if item.set_can_fade(p_can_fade):
				changed_items.append(item)
	
	if changed_items:
		items_can_fade_changed.emit(changed_items, p_can_fade)


## Internal: Sets the value of mutiple items
func _set_start(p_items: Array, p_start: float) -> void:
	var changed_items: Array[ContainerItem]

	for item: Variant in p_items:
		if item is ContainerItem:
			if item.set_start(p_start):
				changed_items.append(item)
	
	if changed_items:
		items_start_changed.emit(changed_items, p_start)


## Internal: Sets the value of mutiple items
func _set_stop(p_items: Array, p_stop: float) -> void:
	var changed_items: Array[ContainerItem]

	for item: Variant in p_items:
		if item is ContainerItem:
			if item.set_stop(p_stop):
				changed_items.append(item)
	
	if changed_items:
		items_stop_changed.emit(changed_items, p_stop)


## Serializes this DataContainer and returnes it in a dictionary
func _serialize() -> Dictionary:
	return {
		"items": seralise_component_array(_items)
	}


## Called when this DataContainer is to be loaded from serialized data
func _load(serialized_data: Dictionary) -> void:
	_store_items(deseralise_component_array(type_convert(serialized_data.get("items", []), TYPE_ARRAY)))
