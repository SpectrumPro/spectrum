# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name VirtualFixtureContainer extends Control
## Script to manage virtual fixtures


## Emitted when the selection of virtual fixtures is changed
signal selected_virtual_fixtures_changed(virtual_fixtures: Array[VirtualFixture])


## Default spacing between fixtures when adding mutiple at once
const _fixture_spacing: Vector2 = Vector2(100, 0)

const _grid_align_spacing: Vector2 = Vector2(100, 100)


## The virtual fixtures root node
@export var _virtual_fixtures_root: UIVirtualFixtures


## Snapping distance
var snapping_distance: Vector2 = Vector2(20, 20)

## Snapping state
var use_snapping: bool = true

## The fixture group
var fixture_group: FixtureGroup = null : set = set_fixture_group


## Stores all the current virtual fixtures, stored as {Fixture:VF}
var _virtual_fixtures: RefMap = RefMap.new()

## The old selected fixtures list
var _old_selected_fixtures: Array

## ALl the current selected virtual fixture nodes
var _selected_virtual_fixtures: Array[VirtualFixture]


## Is the user using box selection currently
var _is_selecting: bool = false

## Starting position of the current selection
var _selection_start_pos: Vector2 = Vector2.ZERO

## Current size of the selection
var _selection_size: Vector2 = Vector2.ZERO

## The Rect2 used for the box selection
var _selection_rect: Rect2 = Rect2()

## Edit mode state
var _edit_mode: bool = false

## Keeps track of all the virtual fixture that are currently being moved. This allows there server side positions to be updated once the mouse button is let go
var _just_moved_virtual_fixtures: Array = []

## Signal connections for FixtureGroupItems, stored as {FixtureGroupItem: {"SignalName": Callable}}
var _group_item_signal_connections: Dictionary = {}

## Width of the grid align mode
var _grid_width: int = 1


## ready
func _ready() -> void:
	Values.connect_to_selection_value("selected_fixtures", _on_selected_fixtures_changed)


## Sets the fixture group
func set_fixture_group(p_fixture_group: FixtureGroup) -> void:
	_reset_all()
	
	if fixture_group:
		fixture_group.fixtures_added.disconnect(_on_fixture_group_fixtures_added)
		fixture_group.fixtures_removed.disconnect(_on_fixture_group_fixtures_removed)
		
		for group_item: FixtureGroupItem in _group_item_signal_connections:
			var connections: Dictionary = _group_item_signal_connections[group_item]
			#group_item.fixture_changed.disconnect()
			group_item.position_changed.disconnect(connections.position_changed)
		
		_group_item_signal_connections = {}
	
	fixture_group = p_fixture_group
	
	if fixture_group:
		_virtual_fixtures_root.set_edit_mode_disabled(false)
		fixture_group.fixtures_added.connect(_on_fixture_group_fixtures_added)
		fixture_group.fixtures_removed.connect(_on_fixture_group_fixtures_removed)
		
		for group_item: FixtureGroupItem in _group_item_signal_connections:
			var connections: Dictionary = _group_item_signal_connections[group_item]
			
		
		for fixture: Fixture in fixture_group.get_fixtures():
			var group_item: FixtureGroupItem = fixture_group.get_group_item_for(fixture)
			_group_item_signal_connections[group_item] = {
				"position_changed": _on_fixture_position_changed.bind(fixture)
			}
			var connections: Dictionary = _group_item_signal_connections[group_item]
			
			#group_item.fixture_changed.disconnect()
			group_item.position_changed.connect(connections.position_changed)
			
			add_fixture(fixture, false, _get_v2_position(fixture), true)
	
	else:
		_virtual_fixtures_root.set_edit_mode(false)
		_virtual_fixtures_root.set_edit_mode_disabled(true)


## Adds a fixture
func add_fixture(fixture: Fixture, set_vf_selected: bool = true, at_position: Vector2 = Vector2.ZERO, no_group_add: bool = false) -> void:
	if _virtual_fixtures.has_left(fixture):
		return
	
	var vf_uuid: String = UUID_Util.v4()
	var new_vf: VirtualFixture = load("uid://cen3hxenplnih").instantiate()
	
	new_vf.set_fixture(fixture)
	
	new_vf.move_requested.connect(_on_virtual_fixture_move_requested.bind(new_vf))
	new_vf.clicked.connect(_on_virtual_fixture_clicked.bind(new_vf))
	new_vf.released.connect(_handle_mouse_up)
	
	new_vf.name = vf_uuid
	new_vf.position = at_position
	
	_virtual_fixtures.map(fixture, new_vf)
	
	if set_vf_selected:
		Values.add_to_selection_value("selected_fixtures", [fixture])
	
	if not no_group_add:
		fixture_group.add_fixture(fixture, Vector3(at_position.x, 0, at_position.y))
	
	add_child(new_vf)


## Adds fixtures to the fixture group
func _add_fixtures(fixtures: Array) -> void:
	var last_pos: Vector2 = size / 2
	last_pos -= _fixture_spacing * len(fixtures) / 2
	
	for fixture: Fixture in fixtures:
		fixture_group.add_fixture(fixture, _get_v3_position_from_v2(last_pos))
		last_pos += _fixture_spacing


## Removes a fixture
func remove_fixture(fixture: Fixture) -> void:
	if not _virtual_fixtures.has_left(fixture):
		return
	
	var vf: Node = _virtual_fixtures.left(fixture)
	
	_set_fixture_selected(fixture, false)
	_virtual_fixtures.erase_left(fixture)
	
	vf.queue_free()


## Sets edit mode state
func set_edit_mode(p_edit_mode: bool) -> void:
	_edit_mode = p_edit_mode
	$Grid.visible = _edit_mode


## Grid Aligns the selected virtual fixtures
func grid_align() -> void:
	if not _selected_virtual_fixtures: return
	
	var base_positon: Vector2 = _selected_virtual_fixtures[0].position
	var updated_position: Vector2 = base_positon
	var index: int = 0
	
	for vf: VirtualFixture in _selected_virtual_fixtures:
		_set_vf_position(vf, updated_position)
		if index == _grid_width -1 :
			updated_position.x = base_positon.x
			updated_position.y += _grid_align_spacing.y
			index = 0
		else:
			updated_position.x += _grid_align_spacing.x
			index += 1 
	
	_handle_mouse_up()


#region Component Callbacks

## Called when the fixture selection is changed
func _on_selected_fixtures_changed(new_selected_fixtures: Array) -> void:
	for fixture: Fixture in _old_selected_fixtures.duplicate():
		if fixture not in new_selected_fixtures:
			_set_fixture_selected(fixture, false)
			
			
	for fixture in new_selected_fixtures:
		if fixture is Fixture and fixture not in _old_selected_fixtures and _virtual_fixtures.has_left(fixture):
			_set_fixture_selected(fixture, true)
	
	_old_selected_fixtures = new_selected_fixtures.duplicate()


## Called when fixtures are added to the fixture group
func _on_fixture_group_fixtures_added(group_items: Array) -> void:
	for group_item: FixtureGroupItem in group_items:
		add_fixture(group_item.get_fixture(), false, _get_v2_position(group_item.get_fixture()), true)


## Called when fixtures are removed from the fixture group
func _on_fixture_group_fixtures_removed(fixtures: Array) -> void:
	for fixture: Fixture in fixtures:
		remove_fixture(fixture)


## Called when any of the fixtures change position
func _on_fixture_position_changed(new_position: Vector3, fixture: Fixture) -> void:	
	_set_vf_position(_virtual_fixtures.left(fixture), _get_v2_position(fixture), true)
	_reset_virtual_fixture_no_snap()
#endregion


#region VF Callbacks
## Called when a virtual fixture is moved
func _on_virtual_fixture_move_requested(by: Vector2, vf: VirtualFixture) -> void:
	if not _edit_mode: return
	
	var vf_to_move: Array = _selected_virtual_fixtures.duplicate()
	
	vf_to_move.erase(vf)
	vf.no_snap_pos += by
	_set_vf_position(vf, vf.no_snap_pos.snapped(snapping_distance) if use_snapping else vf.no_snap_pos)
	
	for next_vf: VirtualFixture in vf_to_move:
		next_vf.no_snap_pos += by
		if use_snapping:
			_set_vf_position(next_vf, next_vf.no_snap_pos.snapped(snapping_distance))
			
		else:
			_set_vf_position(next_vf, next_vf.position + by)


## Called when a virtual fixture is clicked
func _on_virtual_fixture_clicked(vf: VirtualFixture) -> void:
	if vf.get_fixture() not in Values.get_selection_value("selected_fixtures"):
		if Input.is_key_pressed(KEY_SHIFT):
			Values.add_to_selection_value("selected_fixtures", [vf.get_fixture()])
		else:
			Values.set_selection_value("selected_fixtures", [vf.get_fixture()])
#endregion


#region Positions
## Sets the position of a virtual fixture
func _set_vf_position(vf: VirtualFixture, pos: Vector2, no_group_change: bool = false) -> void:
	if vf.position == pos:
		return
	
	else:
		vf.position = pos
		
		if not no_group_change and vf  not in _just_moved_virtual_fixtures:
			_just_moved_virtual_fixtures.append(vf)


## Returns the Vector2 position from a fixture
func _get_v2_position(fixture: Fixture) -> Vector2:
	var pos3: Vector3 = fixture_group.get_group_item_for(fixture).get_position()
	# TODO: Allow for top, front, left views
	return Vector2(pos3.x, pos3.z)


## Gets the Vector3 position of a fixture, from the Vector2 position of a Virtual Fixture
func _get_v3_position(vf: VirtualFixture) -> Vector3:
	var pos2: Vector2 = vf.position
	return _get_v3_position_from_v2(pos2, fixture_group.get_group_item_for(vf.get_fixture()).get_position())


## Gets the Vector3 position of a fixture, from from a Vector2
func _get_v3_position_from_v2(pos2: Vector2, base_pos3: Vector3 = Vector3.ZERO) -> Vector3:	
	# TODO: Allow for top, front, left views
	base_pos3.x = pos2.x
	base_pos3.z = pos2.y
	
	return base_pos3


## Updates the positions of fixtures in the FixtureGroup
func _update_fixture_group_positions() -> void:
	for vf: VirtualFixture in _just_moved_virtual_fixtures:
		fixture_group.get_group_item_for(vf.get_fixture()).set_position(_get_v3_position(vf))
	
	_just_moved_virtual_fixtures = []


## Handles mouse up actions. Resets all no_snap positions and updates the FixtureGroup fixture positions
func _handle_mouse_up() -> void:
	if _just_moved_virtual_fixtures:
		_reset_virtual_fixture_no_snap()
		_update_fixture_group_positions()

#endregion


#region Selections

## Sets the selected state on a fixture's virtual fixtures
func _set_fixture_selected(fixture: Fixture, state: bool) -> void:
	if _virtual_fixtures.has_left(fixture):
		_virtual_fixtures.left(fixture).set_fixture_selected(state)
		
		_set_selected(_virtual_fixtures.left(fixture), state)


## Sets all Virtual Fixture's self selected state to false
func _reset_fixture_selected() -> void:
	for fixture: Fixture in _old_selected_fixtures:
		_set_fixture_selected(fixture, false)


## Sets the self selected state of a virtual fixture
func _set_selected(vf: VirtualFixture, state: bool) -> void:	
	if vf not in _selected_virtual_fixtures and state:
		_selected_virtual_fixtures.append(vf)
	elif not state:
		_selected_virtual_fixtures.erase(vf)
	
	selected_virtual_fixtures_changed.emit(_selected_virtual_fixtures)


## Resets all the virtualFixture's no snap positions
func _reset_virtual_fixture_no_snap() -> void:
	for vf: VirtualFixture in _virtual_fixtures.get_right():
		vf.no_snap_pos = vf.position


## Resets all values and removes all virtual fixtures
func _reset_all() -> void:
	for vf: VirtualFixture in _virtual_fixtures.get_right():
		vf.queue_free()
		
	_virtual_fixtures.clear()
	_old_selected_fixtures = []
	_selected_virtual_fixtures = []
	_just_moved_virtual_fixtures = []


## Updates the selection box witht the current width and height
func _update_selection_box() -> void:
	var x: int = _selection_start_pos.x
	var y: int = _selection_start_pos.y
	var w: int = _selection_size.x
	var h: int = _selection_size.y
	
	if _selection_size.x < 0:
		x = x + w
		w = abs(_selection_size.x)
	
	if _selection_size.y < 0:
		y = y + h
		h = abs(_selection_size.y)
	
	$SelectBox.position = Vector2(x, y)
	$SelectBox.size = Vector2(w, h)
	_selection_rect.position = Vector2(x, y)
	_selection_rect.size = Vector2(w, h)
	
	for fixture: Fixture in _virtual_fixtures.get_left():
		var vf: VirtualFixture = _virtual_fixtures.left(fixture)
		var just_selected: bool = _selection_rect.intersection(Rect2(vf.position, vf.size)).size != Vector2.ZERO
		var current_selected: Array = Values.get_selection_value("selected_fixtures")
		
		if just_selected and fixture not in current_selected:
			Values.add_to_selection_value("selected_fixtures", [fixture], false)
			
		elif not just_selected and fixture in current_selected and not Input.is_key_pressed(KEY_SHIFT):
			Values.remove_from_selection_value("selected_fixtures", [fixture], false)

#endregion


#region UI Callbacks
## Called when the add fixtures button is pressed
func _on_add_fixtures_pressed() -> void: 
	Interface.prompt_object_picker(self, EngineComponent, "DMXFixture")


## Called when the remove fixtures button is pressed
func _on_remove_fixtures_pressed() -> void:
	var fixtures: Array[Fixture]
	
	for vf: VirtualFixture in _selected_virtual_fixtures:
		fixtures.append(vf.get_fixture())
	
	fixture_group.remove_fixtures(fixtures)


## Called when fixtures are selected in the object picker to be added
func _on_object_picker_objects_selected(objects: Array) -> void:
	_add_fixtures(objects)


func _on_import_pressed() -> void:
	_add_fixtures(Values.get_selection_value("selected_fixtures"))


## Called when the grid size value is changed
func _on_grid_size_value_changed(value: float) -> void: 
	snapping_distance = Vector2(int(value), int(value))
	$Grid.material.set_shader_parameter("grid_size", int(value))


## Called when the toggle grid snap button is presses
func _on_show_grid_toggled(toggled_on: bool) -> void: 
	use_snapping = not toggled_on
	_reset_virtual_fixture_no_snap()


## Called on any GUI input
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		if not _is_selecting:
			_is_selecting = true
			$SelectBox.show()
			_selection_start_pos = get_local_mouse_position()
			_selection_size = Vector2.ZERO
		
		_selection_size += event.relative
		_update_selection_box()
	
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.is_released():
					if _is_selecting:
						_is_selecting = false
						$SelectBox.hide()
					
					_handle_mouse_up()
					
				elif not Input.is_key_pressed(KEY_SHIFT):
					if Values.get_selection_value("selected_fixtures"):
						Values.set_selection_value("selected_fixtures", [])
				
			MOUSE_BUTTON_RIGHT:
				if event.is_released() and _edit_mode:
					Interface.show_object_picker(ObjectPicker.SelectMode.Multi, _on_object_picker_objects_selected, "Fixture")


## Called when the align button is pressed
func _on_horizontal_align_pressed() -> void:
	if not _selected_virtual_fixtures:
		return
		
	var base_position: Vector2 = _selected_virtual_fixtures[0].position
	
	for vf: VirtualFixture in _selected_virtual_fixtures:
		_set_vf_position(vf, base_position)
		base_position.x += _fixture_spacing.x
		
	_handle_mouse_up()


## Called when the align button is pressed
func _on_vertical_align_pressed() -> void:
	if not _selected_virtual_fixtures:
		return
		
	var base_position: Vector2 = _selected_virtual_fixtures[0].position
	
	for vf: VirtualFixture in _selected_virtual_fixtures:
		_set_vf_position(vf, base_position)
		base_position.y += _fixture_spacing.x
	
	_handle_mouse_up()


## Called when the grid align button is pressed
func _on_grid_align_pressed() -> void:
	grid_align()


## Called when the fixture grid align width is changed
func _on_grid_width_value_changed(value: float) -> void:
	_grid_width = int(value)
	grid_align()


## Called when the SelectAll button is pressed
func _on_select_all_pressed() -> void:
	Values.set_selection_value("selected_fixtures", fixture_group.get_fixtures())


##  Called when the DeSelect random button is pressed
func _on_de_select_random_pressed() -> void:
	var selected: Array = Values.get_selection_value("selected_fixtures")
	
	selected = selected.filter(func (fixture: Fixture):
		return bool(randi_range(0, 1))
	)
	
	Values.set_selection_value("selected_fixtures", selected)


func _on_fixture_group_name_pressed() -> void:
	Interface.show_object_picker(ObjectPicker.SelectMode.Single, func (objects: Array):
		if objects[0] is FixtureGroup:
			set_fixture_group(objects[0])
	, "FixtureGroup")
#endregion
