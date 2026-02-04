# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SelectBox extends UIComponent
## Class for selection boxes


## Emitted when the selection is pressed
signal pressed()

## Emitted when the selection is released
signal released()

## Emitted when the selection is updated
signal selection_updated(selection: Rect2)


## The Control node to listen to GUI events from
@export var event_control: Control : set = set_event_control

## Snapping Distance
@export var snapping_distance: Vector2 = Vector2.ZERO

## If true. This SelectionBox will use global mouse cordinates
@export var use_global: bool = false

## Target pos to animate to
@onready var _target_position: Vector2 = position

## Target scale to animate to
@onready var _target_size: Vector2 = size


## Selection state
var _is_selecting: bool = false

## The mouse start point of the selection
var _selection_start_pos: Vector2 = Vector2.ZERO

## The current size of the selection
var _selection_size: Vector2 = Vector2.ZERO

## The most recent selection
var _current_selection: Rect2

## Has the selection stated in this frame
var _selection_started: bool = false


## Process
func _process(delta: float) -> void:
	var pos_speed: float = max(position.distance_to(_target_position) / ThemeManager.Constants.Times.SelectBoxMoveTime, 0.1)
	var size_speed: float = max(size.distance_to(_target_size) / ThemeManager.Constants.Times.SelectBoxMoveTime, 0.1)
	
	position = position.move_toward(_target_position, pos_speed * delta)
	size = size.move_toward(_target_size, size_speed * delta)
	
	if position == _target_position and size == _target_size:
		set_process(false)


## Sets the event control
func set_event_control(p_event_control: Control) -> void:
	if p_event_control == event_control:
		return
	
	if event_control:
		event_control.gui_input.disconnect(_on_event_control_gui_input)
	
	event_control = p_event_control
	
	if event_control:
		event_control.gui_input.connect(_on_event_control_gui_input)


## Gets the current selection
func get_selection() -> Rect2:
	return _current_selection


## Returns true if the select box is selecting
func is_selecting() -> bool:
	return _is_selecting


## Updates the selection box with the current width and height
func _update_selection_box() -> void:
	var raw_rect: Rect2 = Rect2(_selection_start_pos, _selection_size).abs()
	var start: Vector2 = raw_rect.position
	var end: Vector2 = (start + raw_rect.size).clamp(Vector2.ZERO, event_control.size)
	start = start.clamp(Vector2.ZERO, end)
	
	var rect: Rect2 = Rect2(start, end - start)
	
	if _selection_started:
		position = rect.position
		size = rect.size
		_selection_started = false
	
	_target_position = rect.position
	_target_size = rect.size
	
	set_process(true)
	
	if use_global:
		_current_selection.position = event_control.get_global_rect().position + rect.position
		_current_selection.end = event_control.get_global_rect().position + rect.end
	else:
		_current_selection = rect
	
	selection_updated.emit(_current_selection)


## Called on any GUI input
func _on_event_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		if not _is_selecting:
			_is_selecting = true
			_selection_started = true
			
			_selection_start_pos = event_control.get_local_mouse_position().snapped(snapping_distance)
			_selection_size = Vector2.ZERO
			
			Interface.show(self)
			pressed.emit()
		
		_selection_size = event_control.get_local_mouse_position().snapped(snapping_distance) - _selection_start_pos
		_update_selection_box()
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if _is_selecting:
				_is_selecting = false
				
				Interface.fade_and_hide(self)
				released.emit()
