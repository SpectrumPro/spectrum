# Copyright (c) 2024 Liam Sherwin, All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.

class_name UIDataContainerTimeLine extends Control
## Timeline editor for DataContainer


## Start SpinBox
@export var _start_spin_box: SpinBox

## Stop SpinBox
@export var _stop_spin_box: SpinBox

## Value SpinBox
@export var _value_spin_box: SpinBox

## CanFade SpinBox
@export var _can_fade_button: CheckButton

## Scene Root
@export var _data_editor: UIDataEditor

## TimeLineContainer Control
@export var _time_line_container: Control

## Template Line2D
@export var _line: Line2D

## Template start handle
@export var _start_handle: TextureRect

## Template stop handle
@export var _stop_handle: TextureRect


## Timeline handle type
enum HandleType {START, STOP}


## The DataContainer
var _container: DataContainer

## All current selected fixtures
var _fixtures: Dictionary[Fixture, Dictionary]

## All handles and Lines for each ContainerItem in the timeline
var _timeline_handles: Dictionary[ContainerItem, Dictionary]

## Snapping Distance
var _snapping_distance: Vector2 = Vector2(10, 4)

## Snapping State
var _use_snapping: bool = true

## Position with out snapping
var _no_snap_pos: Vector2 = Vector2(-1, -1)


## Updates the input controls
func _update_input_controls(container_item: ContainerItem) -> void:
	_start_spin_box.set_value_no_signal(container_item.get_start())
	_stop_spin_box.set_value_no_signal(container_item.get_stop())
	_value_spin_box.set_value_no_signal(container_item.get_value())
	_can_fade_button.set_pressed_no_signal(container_item.get_can_fade())


## Creates timeline handles for a ContainerItem
func _create_timeline_handles(container_item: ContainerItem) -> void:
	if container_item in _timeline_handles:
		return
	
	var line: Line2D = _line.duplicate()
	var start_handle: TextureRect = _start_handle.duplicate()
	var stop_handle: TextureRect = _stop_handle.duplicate()
	
	start_handle.get_node("Capture").gui_input.connect(_on_handle_gui_input.bind(HandleType.START, container_item))
	stop_handle.get_node("Capture").gui_input.connect(_on_handle_gui_input.bind(HandleType.STOP, container_item))
	
	_time_line_container.add_child(line)
	_time_line_container.add_child(start_handle)
	_time_line_container.add_child(stop_handle)
	
	_timeline_handles[container_item] = {"start_handle": start_handle, "stop_handle": stop_handle, "line": line}
	await get_tree().process_frame
	
	if not (is_instance_valid(start_handle) and is_instance_valid(stop_handle) and is_instance_valid(line)):
		return
	
	start_handle.set_position(
		Vector2(
			remap(container_item.get_start(), 0.0, 1.0, 0, _time_line_container.size.x),
			_time_line_container.size.y
		) - (start_handle.size / 2)
	)
	stop_handle.set_position(
		Vector2(
			remap(container_item.get_stop(), 0.0, 1.0, 0, _time_line_container.size.x), 
			remap(container_item.get_value(), 0.0, 1.0, _time_line_container.size.y, 0), 
		) - (stop_handle.size / 2)
	)
	
	
	line.add_point(Vector2(start_handle.position.x + (start_handle.size.x / 2), start_handle.position.y + (start_handle.size.y)))
	line.add_point(Vector2(stop_handle.position.x + (stop_handle.size.x / 2), stop_handle.position.y + (stop_handle.size.y)))


## Removes timeline handles for a ContainerItem
func _remove_timeline_handles(container_item: ContainerItem) -> void:
	if container_item not in _timeline_handles:
		return
	
	var start_handle: TextureRect = _timeline_handles[container_item].start_handle
	var stop_handle: TextureRect = _timeline_handles[container_item].stop_handle
	var line: Line2D = _timeline_handles[container_item].line
	
	_time_line_container.remove_child(start_handle)
	_time_line_container.remove_child(stop_handle)
	_time_line_container.remove_child(line)
	
	start_handle.queue_free()
	stop_handle.queue_free()
	line.queue_free()
	
	_timeline_handles.erase(container_item)


## Gets all selected items
func _get_selected() -> Array[ContainerItem]:
	return _data_editor._selected_items


## Called when the data container changes
func _on_data_editor_container_changed(container: DataContainer) -> void:
	_container = container


## Called when the selection is changed
func _on_data_editor_selection_changed(container_item: ContainerItem, selected: bool) -> void:
	if selected:
		_update_input_controls(container_item)
		_create_timeline_handles(container_item)
	
	else:
		_remove_timeline_handles(container_item)


## Called when the selection is reset
func _on_data_editor_selection_reset() -> void:
	for child: Node in _time_line_container.get_children():
		_time_line_container.remove_child(child)
		child.queue_free()
	
	_timeline_handles.clear()


## Called when there is a gui input on a handle
func _on_handle_gui_input(event: InputEvent, handle_type: HandleType, container: ContainerItem) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		match handle_type:
			HandleType.START:
				var handle: TextureRect = _timeline_handles[container].start_handle
				
				if _no_snap_pos == Vector2(-1, -1):
					_no_snap_pos = handle.position
				
				var new_pos: Vector2 = _no_snap_pos + event.relative
				
				new_pos.y = handle.position.y
				new_pos.x = clampf(new_pos.x, 0 - (handle.size.x / 2), _time_line_container.size.x - (handle.size.x / 2))
				_no_snap_pos = new_pos
				
				if _use_snapping:
					new_pos.x = snappedf(new_pos.x, _time_line_container.size.x / _snapping_distance.x) - (handle.size.x / 2)
				
				handle.position = new_pos
				_timeline_handles[container].line.points[0] = Vector2(new_pos.x + (handle.size.x / 2), new_pos.y + (handle.size.y))
				
				_start_spin_box.set_value_no_signal(_get_handle_x_remap(handle))
			
			HandleType.STOP:
				var handle: TextureRect = _timeline_handles[container].stop_handle
				
				if _no_snap_pos == Vector2(-1, -1):
					_no_snap_pos = handle.position
				
				var new_pos: Vector2 = _no_snap_pos + event.relative
				
				new_pos.y = clampf(new_pos.y, 0 - (handle.size.y / 2), _time_line_container.size.y - (handle.size.y / 2))
				new_pos.x = clampf(new_pos.x, 0 - (handle.size.x / 2), _time_line_container.size.x - (handle.size.x / 2))
				_no_snap_pos = new_pos
				
				if _use_snapping:
					new_pos.y = snappedf(new_pos.y, _time_line_container.size.y / _snapping_distance.y) - (handle.size.y / 2)
					new_pos.x = snappedf(new_pos.x, _time_line_container.size.x / _snapping_distance.x) - (handle.size.x / 2)
				
				handle.position = new_pos
				_timeline_handles[container].line.points[1] = Vector2(new_pos.x + (handle.size.x / 2), new_pos.y + (handle.size.y))
				
				_value_spin_box.set_value_no_signal(_get_handle_y_remap(handle))
				_stop_spin_box.set_value_no_signal(_get_handle_x_remap(handle))
	
	elif event is InputEventMouseButton and event.is_released():
		_no_snap_pos = Vector2(-1, -1)
		
		match handle_type:
			HandleType.START:
				var handle: TextureRect = _timeline_handles[container].start_handle
				_container.set_start([container], _get_handle_x_remap(handle))
			
			HandleType.STOP:
				var handle: TextureRect = _timeline_handles[container].stop_handle
				
				_container.set_value([container], _get_handle_y_remap(handle))
				_container.set_stop([container], _get_handle_x_remap(handle))


## Gets the remapped X position of a handle
func _get_handle_x_remap(handle: TextureRect) -> float:
	var x_pos: int = handle.position.x
	var value: float = remap(x_pos, 0 - (handle.size.x / 2), _time_line_container.size.x - (handle.size.x / 2), 0.0, 1.0)
	
	if _use_snapping:
		value = snappedf(value, 0.01)
	else:
		value = snappedf(value, 0.001)
	
	return value


## Gets the remapped Y position of a handle
func _get_handle_y_remap(handle: TextureRect) -> float:
	var y_pos: int = handle.position.y
	var value: float = remap(y_pos, _time_line_container.size.y - (handle.size.y / 2), 0 - (handle.size.y / 2), 0.0, 1.0)
	
	if _use_snapping:
		value = snappedf(value, 0.01)
	else:
		value = snappedf(value, 0.001)
	
	return value


## Called when the value input is changed
func _on_value_value_changed(value: float) -> void:
	_container.set_value(_get_selected(), value)


## Called when the can fade input is toggled
func _on_can_fade_toggled(toggled_on: bool) -> void:
	_container.set_can_fade(_get_selected(), toggled_on)


## Called when the start input is changed
func _on_start_value_changed(value: float) -> void:
	_container.set_start(_get_selected(), value)


## Called when the stop input is changed
func _on_stop_value_changed(value: float) -> void:
	_container.set_stop(_get_selected(), value)


## Called when the ToggleGrid button is pressed
func _on_toggle_grid_toggled(toggled_on: bool) -> void:
	_use_snapping = toggled_on
