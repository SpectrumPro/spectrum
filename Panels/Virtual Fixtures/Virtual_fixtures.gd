# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

extends GraphEdit
## UI panel for displaying virtual fixtures

const ORIENTATION_VERTICAL: int = 0
const ORIENTATION_HORIZONTAL: int = 1


var _old_active_fixtures: Array
var _selected_virtual_fixtures: Array

var _add_fixture_button: Button

var _position_offset: Vector2 = Vector2(100, 100)

var last_call_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## Add extra buttons to GraphEdit menu, and subscribe to global variables
	
	_add_fixture_button = _add_menu_hbox_button("Add Selected Fixture", self._add_fixture, "Add the selected fixtures to the view", true)
	_add_menu_hbox_button("Delete", self._request_delete, "Delete the selected virtual fixtures, this does NOT delete the underlying fixture")
	_add_menu_hbox_button(ResourceLoader.load("res://Assets/Icons/Horizontal_distribute.svg"), self._align.bind(ORIENTATION_HORIZONTAL), "Align the selected fixtures horizontally" )
	_add_menu_hbox_button(ResourceLoader.load("res://Assets/Icons/Vertical_distribute.svg"), self._align.bind(ORIENTATION_VERTICAL), "Align the selected fixtures verticality" )
	
	Values.connect_to_selection_value("selected_fixtures", self._active_fixtures_changed)


func _add_menu_hbox_button(content:Variant, method: Callable, tooltip: String = "", disabled: bool = false) -> Button:
	## Function to add a button to the Graph Edits menu HBox, with callbacks, tool tips, and shortcuts
	
	var button: Button = Button.new()
	
	if content is Texture2D:
		button.icon = content
	else:
		button.text = content as String
	
	button.pressed.connect(method)
	button.tooltip_text = tooltip
	button.disabled = disabled
	
	self.get_menu_hbox().add_child(button)
	return button


func _add_fixture() -> void:
	## Adds the currently selected virtual fixtures to the view
	
	for fixture: Fixture in Values.get_selection_value("selected_fixtures"):
		var node_to_add: Control = Interface.components.virtual_fixture.instantiate()
		
		node_to_add.set_fixture(fixture)
		node_to_add.set_highlighted(true)
		
		if not fixture.user_meta.get("virtual_fixtures"):
			fixture.user_meta.virtual_fixtures = []
		
		node_to_add.virtual_fixture_index = len(fixture.user_meta.virtual_fixtures)
		node_to_add.position_offset += _position_offset
		_position_offset += Vector2(5, 5)
		
		fixture.user_meta.virtual_fixtures.append(node_to_add.position_offset)
		
		self.add_child(node_to_add)


func _request_delete() -> void:
	## Deletes a virtual fixtures from the current view
	var to_remove: Array = _selected_virtual_fixtures.duplicate()
	
	for virtual_fixture: Control in to_remove:
		virtual_fixture.fixture.user_meta.virtual_fixtures.remove_at(virtual_fixture.virtual_fixture_index)
		virtual_fixture.queue_free()
		_selected_virtual_fixtures.erase(virtual_fixture)

  #
func _active_fixtures_changed(new_active_fixtures: Array) -> void:
	## Function to update highlighting on virtual fixtures, when their corresponding fixture is selected
	
	_add_fixture_button.disabled = true if new_active_fixtures == [] else false
	
	for virtual_fixture: Control in get_children():
		virtual_fixture.set_highlighted(false)
	
	for active_fixture: Fixture in new_active_fixtures:
		for virtual_fixture in active_fixture.get_user_meta("virtual_fixtures", []):
			virtual_fixture.set_highlighted(true)
	
	_old_active_fixtures = new_active_fixtures


func _align(orientation: int) -> void:
	## Function to align the currently selected fixtures horizontally
	
	if not _selected_virtual_fixtures:
		return
		
	var base_position: Vector2 = _selected_virtual_fixtures[0].position_offset
	
	for virtual_fixture: Control in _selected_virtual_fixtures:
		virtual_fixture.position_offset = base_position
		virtual_fixture.fixture.user_meta.virtual_fixtures[virtual_fixture.virtual_fixture_index] = base_position
		
		if orientation:
			base_position.x += 100
		else:
			base_position.y += 100


func from(config: Dictionary, control_fixture: Fixture) -> void:
	## Function to load a virtual fixture, from a stored config in a save file
	
	var node_to_add: Control = Interface.components.virtual_fixture.instantiate()
	
	node_to_add._position_offset = Vector2(config._position_offset.x, config._position_offset.y)
	node_to_add.set_fixture(control_fixture)
	control_fixture.add_virtual_fixture(node_to_add)
	
	self.add_child(node_to_add)


func _on_virtual_fixture_selected(node) -> void:
	if node not in _selected_virtual_fixtures:
		_selected_virtual_fixtures.append(node)
	Values.add_to_selection_value("selected_fixtures", [node.fixture])


func _on_virtual_fixture_deselected(node) -> void:
	_selected_virtual_fixtures.erase(node)
	Values.remove_from_selection_value("selected_fixtures", [node.fixture])
	


func _on_color_picker_color_changed(color: Color) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0  # Convert milliseconds to seconds
	
	if current_time - last_call_time >= Core.call_interval:
		Core.programmer.set_color(Values.get_selection_value("selected_fixtures"), color)
		
		last_call_time = current_time


func _on_save_pressed() -> void:
	Core.programmer.save_to_scene()
