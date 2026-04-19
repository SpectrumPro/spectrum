# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name FixtureGroupFixtures extends PanelContainer
## Custom status display for FixtureGroups


## Tree for displaying function
@export var _tree: Tree

## The Remove Button
@export var _remove_button: Button

## The MoveUp Button
@export var _move_up_button: Button

## The MoveDown Button
@export var _move_down_button: Button

## Root TreeItem
@onready var _root: TreeItem = _tree.create_item()


## The current FunctionGroup
var _fixture_group: FixtureGroup

## Stores all TreeItems with there Function
var _fixture_tree_items: RefMap = RefMap.new()

## All current selected function
var _selected_fixtures: Array[Fixture]

## Signals to connect to the FunctionGroup
var _signal_group: SignalGroup = SignalGroup.new([], {
	"fixtures_added": _add_fixtures,
	"fixtures_removed": _remove_fixtures,
})


## Sets the FunctionGroup
func set_fixture_group(p_fixture_gropup: FixtureGroup) -> void:
	_signal_group.disconnect_object(_fixture_group)
	_fixture_group = p_fixture_gropup
	_signal_group.connect_object(_fixture_group)
	
	_add_fixtures(_fixture_group.get_group_items())


## Adds functions to the list
func _add_fixtures(p_fixtures: Array[FixtureGroupItem]) -> void:
	for group_item: FixtureGroupItem in p_fixtures:
		var fixture: Fixture = group_item.get_fixture()
		
		if fixture in _fixture_tree_items.get_left():
			return
		
		var item: TreeItem = _root.create_child()
		item.set_text(0, fixture.get_name())
		
		_fixture_tree_items.map(fixture, item)


## Removes functions from the list
func _remove_fixtures(p_fixtures: Array[Fixture]) -> void:
	for fixture: Fixture in p_fixtures:
		if fixture not in _fixture_tree_items.get_left():
			return
		
		_fixture_tree_items.left(fixture).free()
		_fixture_tree_items.erase_left(fixture)
		
		if fixture in _selected_fixtures:
			_selected_fixtures.erase(fixture)


## Called when the Add Button is pressed
func _on_add_pressed() -> void:
	Popups.ObjectSelector(self, EngineComponent, "Fixture").then(func (p_fixture: Fixture):
		_fixture_group.add_fixture(p_fixture)
	)


## Called when the Remove Button is pressed
func _on_remove_pressed() -> void:
	_fixture_group.remove_fixtures(_selected_fixtures)


## Called when items are selected on the Tree
func _on_tree_multi_selected(p_item: TreeItem, p_column: int, p_selected: bool) -> void:
	var fixture: Fixture = _fixture_tree_items.right(p_item)
	
	if p_selected and fixture not in _selected_fixtures:
		_selected_fixtures.append(fixture)
	elif not p_selected and fixture in _selected_fixtures:
		_selected_fixtures.erase(fixture)
	
	var state: bool = _selected_fixtures == []
	
	_remove_button.set_disabled(state)
	_move_up_button.set_disabled(state)
	_move_down_button.set_disabled(state)
