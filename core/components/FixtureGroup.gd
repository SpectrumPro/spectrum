# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name FixtureGroup extends EngineComponent
## Stores a group of fixtures, using FixtureGroupItem


## Emitted when fixtures are added to this FixtureGroup
signal fixtures_added(fixtures: Array[FixtureGroupItem])

## Emitted when fixtures are removed from this FixtureGroup
signal fixtures_removed(fixtures: Array[Fixture])


## Stores all the fixtures and there positions. Stored as {Fixture: FixtureGroupItem}
var _fixtures: Dictionary[Fixture, FixtureGroupItem] = {}


## init
func _init(p_uuid: String = UUID_Util.v4(), p_name: String = _name) -> void:
	super._init(p_uuid, p_name)
	
	_set_name("FixtureGroup")
	_set_self_class("FixtureGroup")
	
	_settings_manager.register_custom_panel("Fixtures", preload("res://components/SettingsManagerCustomPanels/FixtureGroupFixtures.tscn"), "set_fixture_group")
	
	_settings_manager.register_networked_callbacks({
		"on_fixtures_added": _add_group_items,
		"on_fixtures_removed": _remove_fixtures,
	})
	
	_settings_manager.set_callback_allow_deserialize("on_fixtures_added")


## Gets all the fixtures
func get_fixtures() -> Array[Fixture]:
	var result: Array[Fixture]
	result.assign(_fixtures.keys())
	
	return result


## Gets all the group items
func get_group_items() -> Array[FixtureGroupItem]:
	var result: Array[FixtureGroupItem]
	result.assign(_fixtures.values())
	
	return result


## Gets a FixtureGroupItem
func get_group_item_for(fixture: Fixture) -> FixtureGroupItem:
	return _fixtures.get(fixture)


## Adds a fixture to this FixtureGroup
func add_fixture(fixture: Fixture, position: Vector3 = Vector3.ZERO) -> Promise: 
	return rpc("add_fixture", [fixture, position])


## Adds a pre-existing FixtureGroupItem. Returns false the fixture is already in this group
func add_group_item(group_item: FixtureGroupItem) -> Promise: 
	return rpc("add_group_item", [group_item])


## Adds mutiple group items at once
func add_group_items(group_items: Array) -> Promise: 
	return rpc("add_group_items", [group_items])


## Removes a fixture from this group, returns false if this fixture is not in this group
func remove_fixture(fixture: Fixture) -> Promise: 
	return rpc("remove_fixture", [fixture])


## Adds mutiple fixtures at once
func remove_fixtures(fixtures: Array) -> Promise: 
	return rpc("remove_fixtures", [fixtures])


## Deletes this FixtureGroup
func delete() -> void:
	for group_item: FixtureGroupItem in _fixtures.values():
		group_item.delete()
	
	super.delete()


## Saves this FixtureGroup into a dictionary
func serialize() -> Dictionary:
	var serialized_data: Dictionary = {
		"fixtures": {}
	}
	
	for fixture: Fixture in _fixtures:
		serialized_data.fixtures[fixture.uuid] = _fixtures[fixture].serialize()
	
	return super.serialize().merged(serialized_data)


## Loads this FixtureGroup from serialized data
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	if p_serialized_data.get("fixtures") is Dictionary: 
		var fixtures: Dictionary = p_serialized_data.fixtures
		
		for fixture_uuid: Variant in fixtures:
			ComponentDB.request_component(fixture_uuid, func (p_fixture: EngineComponent):
				if not p_fixture is Fixture:
					return
				
				var new_group_item: FixtureGroupItem = FixtureGroupItem.new()
				new_group_item.deserialize(fixtures[fixture_uuid])
				
				_add_group_item(new_group_item, true)
			)


## Internal: Adds a fixture to this FixtureGroup
func _add_fixture(fixture: Fixture, position: Vector3 = Vector3.ZERO, no_signal: bool = false) -> bool:
	if fixture in _fixtures: return false
	
	var new_group_item: FixtureGroupItem = FixtureGroupItem.new()
	
	new_group_item.fixture = fixture
	new_group_item.position = position
	
	_add_group_item(new_group_item, no_signal)    
	
	return true


## Internal: Adds a pre-existing FixtureGroupItem. Returns false the fixture is already in this group
func _add_group_item(group_item: FixtureGroupItem, no_signal: bool = false) -> bool:
	if group_item.get_fixture() in _fixtures: return false
	
	_fixtures[group_item.get_fixture()] = group_item
	
	group_item.get_fixture().delete_requested.connect(_remove_fixture.bind(group_item.get_fixture()), CONNECT_ONE_SHOT)
	ComponentDB.register_component(group_item)
	
	if not no_signal:
		fixtures_added.emit([group_item])
		
	return true


## Internal: Adds mutiple group items at once
func _add_group_items(group_items: Array) -> void:
	var just_added_group_items: Array[FixtureGroupItem]
	
	for group_item: Variant in group_items:
		if group_item is FixtureGroupItem:
			if _add_group_item(group_item, true):
				just_added_group_items.append(group_item)
	
	if just_added_group_items:
		fixtures_added.emit(just_added_group_items)


## Internal: Removes a fixture from this group, returns false if this fixture is not in this group
func _remove_fixture(fixture: Fixture, no_signal: bool = false) -> bool:
	if not _fixtures.has(fixture): return false
	
	_fixtures[fixture].delete()
	_fixtures.erase(fixture)
	
	if not no_signal:
		fixtures_removed.emit([fixture])
	
	return true


## Internal: Adds mutiple fixtures at once
func _remove_fixtures(fixtures: Array) -> void:
	var just_removed_fixtures: Array[Fixture] = []
	
	for fixture: Variant in fixtures:
		if fixture is Fixture:
			if _remove_fixture(fixture, true):
				just_removed_fixtures.append(fixture)
	
	if just_removed_fixtures:
		fixtures_removed.emit(just_removed_fixtures)
