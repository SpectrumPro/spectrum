# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.

class_name UIDesk extends UIPanel
## A customisable UI layout


## Emitted when the snapping distance is changed. Will be Vector2.ZERO when snapping is disabled.
signal snapping_distance_changed(snapping_distance: Vector2)

## Emitted when the GridSize is changed
signal grid_size_changed(grid_size: GridSize)


## Enum for GridSize
enum GridSize {
	SMALL = 25,
	MEDIUM = 10,
	LARGE = 5
}


## Array of buttons to disable when no panel is selected
@export var disable_on_deselect: Array[Button]

## The SelectBox node
@export var _select_box: SelectBox

## The container used for holding the panels
@export var _container_node: DrawGrid

## The Panel used for the aera indicator
@export var _area_indicator: Panel


## Whether snapping is enabled in this desk
var _snapping_enabled: bool = true

## The snapping distance of desk items in px
var _snapping_distance: Vector2 = Vector2(80, 80)

## current GridSize
var _grid_size: GridSize = GridSize.MEDIUM

## Array of all items in the desk
var _items: Array[UIDeskItemContainer]

## The selected panels
var _selected_items: Array[UIDeskItemContainer] = []

## The position of the most recently deleted item, so a new one can appear in its place
var _just_deleted_pos: Vector2 = Vector2.ZERO

## The size of the most recently deleted panel
var _just_deleted_size: Vector2 = Vector2(100, 100)

## Target position for the aera indicator
var _aera_indicator_target: Rect2 = Rect2()

## True if mouse selection was just used
var _used_mouse_select: bool = false


## Init
func _init() -> void:
	super._init()
	
	_set_class_name("UIDesk")
	
	settings_manager.register_setting("GridSize", Data.Type.ENUM, set_grid_size, get_grid_size, [grid_size_changed]).set_enum_dict(GridSize)


## Process
func _process(delta: float) -> void:
	var pos_speed: float = max(_area_indicator.position.distance_to(_aera_indicator_target.position) / ThemeManager.Constants.Times.DeskAreaMoveTime, 0.1)
	var size_speed: float = max(_area_indicator.size.distance_to(_aera_indicator_target.size) / ThemeManager.Constants.Times.DeskAreaMoveTime, 0.1)
	
	_area_indicator.position = _area_indicator.position.move_toward(_aera_indicator_target.position, pos_speed * delta)
	_area_indicator.size = _area_indicator.size.move_toward(_aera_indicator_target.size, size_speed * delta)
	
	if _area_indicator.position == _aera_indicator_target.position and _area_indicator.size == _aera_indicator_target.size:
		set_process(false)


## Selects all the panels in this desk
func select_all() -> void:
	for item: Control in _container_node.get_children():
		select_item(item)


## Deselects all the panels in this desk
func select_none() -> void:
	for item: Control in _selected_items.duplicate():
		deselect_item(item)


## Selects an individual panel
func select_item(p_item: Control) -> void:
	p_item.set_selected(true)
	
	if not _selected_items:
		enable_button_array(disable_on_deselect)
	
	if p_item not in _selected_items:
		_selected_items.append(p_item)


## Deselects an individual panel
func deselect_item(p_item: Control) -> void:
	p_item.set_selected(false)
	_selected_items.erase(p_item)
	
	if not _selected_items:
		disable_button_array(disable_on_deselect)


## Sets whether snapping is enabled in this desk
func set_snapping_enabled(p_enabled: bool) -> void:
	_snapping_enabled = p_enabled
	_container_node.show_grid = _snapping_enabled
	snapping_distance_changed.emit(_snapping_distance if _snapping_enabled else Vector2.ZERO)


## Sets the snapping distance of this desk
func set_snapping_distance(p_distance: Vector2) -> void:
	_snapping_distance = p_distance
	
	_container_node.grid_size = _snapping_distance
	_select_box.snapping_distance = _snapping_distance
	
	snapping_distance_changed.emit(_snapping_distance)


## Adds a new panel to this desk
func add_panel(p_panel: UIPanel, p_position: Vector2 = _just_deleted_pos, p_size: Vector2 = _just_deleted_size) -> UIDeskItemContainer:
	var new_node: UIDeskItemContainer = preload("uid://cebqk3au5iwx0").instantiate()
	new_node.set_edit_mode(true)
	
	# Connect signals to the item container
	edit_mode_toggled.connect(new_node.set_edit_mode)
	snapping_distance_changed.connect(new_node.set_snapping_distance)
	
	new_node.clicked.connect(_on_item_clicked.bind(new_node))
	new_node.right_clicked.connect(_on_item_right_clicked.bind(new_node))
	
	# Add the new panel
	new_node.set_panel(p_panel)
	new_node.set_edit_mode(get_edit_mode())
	new_node.set_snapping_distance(_snapping_distance)
	
	new_node.position = p_position
	new_node.size = p_size.clamp(_snapping_distance, Vector2.INF)
	_container_node.add_child(new_node, true)
	
	_items.append(new_node)
	
	new_node.hide()
	Interface.show_and_fade(new_node)
	return new_node


## Opens the settings on the given node or selected item
func open_settings(p_node: UIDeskItemContainer = null) -> void:
	if _selected_items or p_node:
		var panel: UIPanel = _selected_items[0].get_panel() if not p_node else p_node.get_panel()
		panel.show_settings()


## Sets the GridSize
func set_grid_size(p_grid_size: GridSize) -> void:
	if p_grid_size == _grid_size or p_grid_size <= 0:
		return
	
	_grid_size = p_grid_size
	_update_snapping_size()
	
	grid_size_changed.emit(_grid_size)


## Returns the GridSize
func get_grid_size() -> GridSize:
	return _grid_size


## Returns a dictionary containing all panels, their positions, sizes, and settings
func serialize() -> Dictionary:
	var items: Array = []
	
	for desk_item_container: UIDeskItemContainer in _items:
		items.append(desk_item_container.serialize())
	
	return super.serialize().merged({
		"items": items,
		"grid_size": _grid_size
	})


## Loads all items in this desk from a saved dictionary
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	var items: Array = type_convert(p_serialized_data.get("items", []), TYPE_ARRAY)
	
	for serialized_container: Variant in items:
		if not serialized_container is Dictionary:
			continue
		
		var serialized_panel: Dictionary = type_convert(serialized_container.get("serialized_panel", []), TYPE_DICTIONARY)
		var panel_class: String = type_convert(serialized_panel.get("class", []), TYPE_STRING)
		
		var panel_anchor_left: float = type_convert(serialized_container.get("anchor_left"), TYPE_FLOAT)
		var panel_anchor_right: float = type_convert(serialized_container.get("anchor_right"), TYPE_FLOAT)
		var panel_anchor_top: float = type_convert(serialized_container.get("anchor_top"), TYPE_FLOAT)
		var panel_anchor_bottom: float = type_convert(serialized_container.get("anchor_bottom"), TYPE_FLOAT)
		
		var panel: UIPanel = UIDB.instance_panel(panel_class)
		
		if not is_instance_valid(panel):
			continue
		
		var container: UIDeskItemContainer = add_panel(panel, Vector2.ZERO, Vector2.ZERO)
		container.deserialize(serialized_container)
		
		container.set_anchor(SIDE_LEFT, panel_anchor_left, true, true)
		container.set_anchor(SIDE_RIGHT, panel_anchor_right, true, true)
		container.set_anchor(SIDE_TOP, panel_anchor_top, true, true)
		container.set_anchor(SIDE_BOTTOM, panel_anchor_bottom, true, true)
		
		container.set_offset(SIDE_LEFT, 0)
		container.set_offset(SIDE_RIGHT, 0)
		container.set_offset(SIDE_TOP, 0)
		container.set_offset(SIDE_BOTTOM, 0)
		
		panel.deserialize(serialized_panel)
	
	set_grid_size(type_convert(p_serialized_data.get("grid_size", _grid_size), TYPE_INT))


## Override this function to change state when edit mode is toggled
func _edit_mode_toggled(state: bool) -> void:
	_container_node.show_point = state


## Updates the position of the aera indicator
func _update_aera_indicator(p_position: Vector2) -> void:
	_aera_indicator_target = _get_preset_area_size(p_position)
	set_process(true)


## Updates the snapping size to match the container size
func _update_snapping_size() -> void:
	set_snapping_distance(_container_node.size / _grid_size)


## Gets the area of a preset zone from a position
func _get_preset_area_size(p_position: Vector2) -> Rect2i:
	var width: int = _container_node.size.x
	var height: int = _container_node.size.y
	
	var third_w: int = width / 3
	var third_h: int = height / 3
	var half_w: int = width / 2
	var half_h: int = height / 2
	
	var location: Vector2i = Vector2i(
		int(clamp(floor(p_position.x / third_w), 0, 2)),
		int(clamp(floor(p_position.y / third_h), 0, 2))
	)

	match location:
		Vector2i(0, 0):
			return Rect2i(0, 0, half_w, half_h) # top-left
		Vector2i(2, 0):
			return Rect2i(half_w, 0, half_w, half_h) # top-right
		Vector2i(0, 2):
			return Rect2i(0, half_h, half_w, half_h) # bottom-left
		Vector2i(2, 2):
			return Rect2i(half_w, half_h, half_w, half_h) # bottom-right
		
		Vector2i(1, 0):
			return Rect2i(0, 0, width, half_h) # top
		Vector2i(1, 2):
			return Rect2i(0, half_h, width, half_h) # bottom
		Vector2i(0, 1):
			return Rect2i(0, 0, half_w, height) # left
		Vector2i(2, 1):
			return Rect2i(half_w, 0, half_w, height) # right
		
		_:
			return Rect2i(0, 0, width, height) # full


## Called when the add button is pressed
func _on_add_pressed() -> void:
	Interface.prompt_panel_picker(self).then(func (p_panel_class: String):
		add_panel(UIDB.instance_panel(p_panel_class))
	)


## Removes the selected items from this desk
func _on_delete_pressed() -> void:
	for item: UIDeskItemContainer in _selected_items.duplicate():
		deselect_item(item)
		
		_just_deleted_pos = item.position
		_just_deleted_size = item.size
		
		_items.erase(item)
		
		Interface.fade_and_hide(item, func ():
			item.queue_free()
		)


## Called when the edit button is pressed
func _on_edit_pressed() -> void:
	open_settings()


## Called when the copy button is pressed
func _on_copy_pressed() -> void:
	var nodes_to_copy: Array[UIDeskItemContainer] = _selected_items.duplicate()
	select_none()
	
	for panel_container: UIDeskItemContainer in nodes_to_copy:
		var new_panel: UIPanel = UIDB.instance_panel(panel_container.get_panel().get_class_name())
		
		new_panel.deserialize(panel_container.get_panel().serialize())
		select_item(add_panel(
			new_panel,
			panel_container.position,
			panel_container.size
		))


## Called when the value in the snapping distance box is changed
func _on_snapping_distance_value_changed(p_value: float) -> void:
	set_snapping_distance(Vector2(p_value, p_value))


## Moves the selected items up so they appear on top
func _on_move_up_pressed() -> void:
	for item in _selected_items:
		_container_node.move_child(item, item.get_index() + 1)


## Moves the selected items down so they appear underneath
func _on_move_down_pressed() -> void:
	for item in _selected_items:
		_container_node.move_child(item, clamp(item.get_index() - 1, 0, INF))


## Called when a panel is clicked in edit mode
func _on_item_clicked(p_item: Control) -> void:
	if not Input.is_key_label_pressed(KEY_SHIFT):
		select_none()
	
	select_item(p_item)


## Called when a panel is right clicked in edit mode
func _on_item_right_clicked(p_item: UIDeskItemContainer) -> void:
	select_none()
	select_item(p_item)
	open_settings(p_item)


## Called when the container receives an input event. Handles selection and object picker display.
func _on_container_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton:
		if p_event.is_pressed() and _edit_mode:
			select_none()
		
		if p_event.button_index == MOUSE_BUTTON_LEFT and p_event.is_released():
			if _used_mouse_select:
				_used_mouse_select = false
			
			else:
				var area_rect: Rect2i = _get_preset_area_size(p_event.position)
				
				Interface.prompt_panel_picker(self).then(func (p_panel_class: String):
					add_panel(UIDB.instance_panel(p_panel_class), area_rect.position, area_rect.size)
				)
	
	if p_event is InputEventMouseMotion:
		_update_aera_indicator(p_event.position)


## Called when the selection is released in the select box
func _on_select_box_released() -> void:
	var rect: Rect2 = _select_box.get_selection()
	
	Interface.prompt_panel_picker(self).then(func (p_panel_class: String):
		add_panel(UIDB.instance_panel(p_panel_class), rect.position.snapped(_snapping_distance), rect.size.snapped(_snapping_distance))
	)
	
	Interface.show_and_fade(_area_indicator)


## Called when the select box starts
func _on_select_box_pressed() -> void:
	_used_mouse_select = true
	Interface.fade_and_hide(_area_indicator)


## Called when the mouse enters the container
func _on_container_mouse_entered() -> void:
	if not _select_box.is_selecting():
		Interface.show_and_fade(_area_indicator)
		_update_aera_indicator(_container_node.get_local_mouse_position())


## Called when the mouse exits the container
func _on_container_mouse_exited() -> void:
	Interface.fade_and_hide(_area_indicator)


## Called when the container is resized
func _on_container_resized() -> void:
	_update_snapping_size()
