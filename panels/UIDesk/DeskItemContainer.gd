# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIDeskItemContainer extends UIComponent
## Container for desk items


## Emitted when this desk item is clicked in edit mode
signal clicked

## Emitted when this desk item is right-clicked in edit mode
signal right_clicked


## The label node that displays the position and size of this item
@export var _label_node: Label

## The Background Panel
@export var _background: Panel

## The Container for all the handles
@export var _handles_container: Control

## The new position of this item, used during processing
@onready var _new_position: Vector2 = position

## The new size of this item, used during processing
@onready var _new_size: Vector2 = size

## The target size
@onready var _target_size: Vector2 = size

## The target position
@onready var _target_position: Vector2 = position


## The background color of this desk item when it is selected
var _selected_color: Color = ThemeManager.Colors.Selections.SelectedGray

## The background color of this desk item when it is not selected
var _normal_color: Color = ThemeManager.Colors.Selections.UnSelectedGray

## The snapping distance of this desk item
var _snapping_distance: Vector2 = Vector2(20, 20) : set = set_snapping_distance

## The panel node
var _panel: UIPanel = null

## Mouse move on right click state
var _has_moved_on_right_click: bool = false

## True if the last time this node was moved was from _process
var _moved_on_process: bool = false
 

## Init
func _init() -> void:
	super._init()
	_set_class_name("UIDeskItemContainer")


## Ready
func _ready() -> void:
	_background.add_theme_stylebox_override("panel", _background.get_theme_stylebox("panel").duplicate())
	_label_node.label_settings = _label_node.label_settings.duplicate()
	
	_set_anchors_to_current_size.call_deferred()
	
	set_process(false)
	
	await get_tree().process_frame
	update_label()


## Process
func _process(delta: float) -> void:
	var pos_speed: float = max(position.distance_to(_target_position) / ThemeManager.Constants.Times.DeskItemMoveTime, 10)
	var size_speed: float = max(size.distance_to(_target_size) / ThemeManager.Constants.Times.DeskItemMoveTime, 10)
	
	_moved_on_process = true
	
	position = position.move_toward(_target_position, pos_speed * delta)
	size = size.move_toward(_target_size, size_speed * delta)
	
	if position.is_equal_approx(_target_position) and size.is_equal_approx(_target_size):
		_moved_on_process = false
		_set_anchors_to_current_size()
		set_process(false)


## Shows or hides the position/size controls
func set_edit_mode(p_edit_mode: bool) -> void:
	Interface.set_visible_and_fade(_handles_container, p_edit_mode)


## Sets the selection state of this item, changing the background color
func set_selected(p_is_selected: bool) -> void:
	Interface.fade_property(_background.get_theme_stylebox("panel"), "bg_color", _selected_color if p_is_selected else _normal_color)


## Sets the snapping distance of this item
func set_snapping_distance(p_snapping_distance: Vector2) -> void:
	_snapping_distance = p_snapping_distance


## Sets the panel node of this item
func set_panel(p_panel: UIPanel) -> void:
	if _panel:
		remove_child(_panel)
		_panel.request_move.disconnect(_on_panel_request_move)
		_panel.request_resize.disconnect(_on_panel_request_resize)
	
	_panel = p_panel
	
	if _panel:
		add_child(_panel)
		move_child(_panel, 0)
		
		_panel.request_move.connect(_on_panel_request_move)
		_panel.request_resize.connect(_on_panel_request_resize)


## Gets the panel node set with set_panel, otherwise null
func get_panel() -> Variant:
	return _panel


## Updates the label to show the correct position and size
func update_label() -> void:
	if size > Vector2(180, 180):
		_label_node.text = "W:" + str(int(_target_size.x)) + " H:" + str(int(_target_size.y)) + "\nX:" + str(int(_target_position.x)) + " Y:" + str(int(_target_position.y))
		_label_node.label_settings.font_size = 16
	else:
		_label_node.text = "W:" + str(int(_target_size.x)) + "\nH:" + str(int(_target_size.y)) + "\nX:" + str(int(_target_position.x)) + "\nY:" + str(int(_target_position.y))
		_label_node.label_settings.font_size = 10


## Saves the state of this item for restoration later
func serialize() -> Dictionary:
	return super.serialize().merged({
		"type": "",
		"anchor_left": get_anchor(SIDE_LEFT),
		"anchor_right": get_anchor(SIDE_RIGHT),
		"anchor_top": get_anchor(SIDE_TOP),
		"anchor_bottom": get_anchor(SIDE_BOTTOM),
		"serialized_panel": _panel.serialize() if _panel else {}
	})


## Updates the position and scale if needed
func _update_transform() -> void:
	if position != _target_position or size != _target_size:
		set_process(true)


## Updates the size of this panel from an InputEvent
func _update_size_from_event(p_event: InputEventMouse) -> void:
	_new_size += p_event.relative
	_new_size = _new_size.abs()
	
	_target_size = _new_size.snapped(_snapping_distance).clamp(_snapping_distance, Vector2.INF)
	update_label()
	move_to_front()
	_update_transform()


## Updates the position of this panel from an InputEvent
func _update_position_from_event(p_event: InputEventMouse) -> void:
	_new_position += p_event.relative
	_new_position = _new_position.abs()
	
	_target_position = _new_position.snapped(_snapping_distance)
	update_label()
	move_to_front()
	_update_transform()


## Sets anchors to current size
func _set_anchors_to_current_size():
	var parent_rect = get_parent().get_rect()
	if parent_rect.size.x == 0 or parent_rect.size.y == 0:
		# Avoid division by zero if parent has no size yet
		return

	# Calculate anchor positions as a percentage of the parent's size
	var anchor_left_ratio = position.x / parent_rect.size.x
	var anchor_top_ratio = position.y / parent_rect.size.y
	var anchor_right_ratio = (position.x + size.x) / parent_rect.size.x
	var anchor_bottom_ratio = (position.y + size.y) / parent_rect.size.y

	# Set the anchors
	set_anchor(SIDE_LEFT, anchor_left_ratio)
	set_anchor(SIDE_TOP, anchor_top_ratio)
	set_anchor(SIDE_RIGHT, anchor_right_ratio)
	set_anchor(SIDE_BOTTOM, anchor_bottom_ratio)


## Handles drag motion on the background to move the item
func _on_background_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_position_from_event(p_event)
		
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_has_moved_on_right_click = true
			_update_size_from_event(p_event)
	
	if p_event is InputEventMouseButton:
		match p_event.button_index:
			MOUSE_BUTTON_LEFT:
				clicked.emit()
			MOUSE_BUTTON_RIGHT:
				if p_event.is_released():
					if _has_moved_on_right_click:
						_has_moved_on_right_click = false
					
					else:
						right_clicked.emit()


## Handles drag motion on the resize handle to resize the item
func _on_br_handle_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseMotion and (p_event.button_mask == MOUSE_BUTTON_MASK_LEFT or p_event.button_mask == MOUSE_BUTTON_MASK_RIGHT):
		_update_size_from_event(p_event)

	if p_event is InputEventMouseButton and p_event.is_pressed():
		clicked.emit()


## Handles resize request from internal UIPanel
func _on_panel_request_resize(p_by: Vector2) -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		p_by *= 4
	_new_size += p_by
	
	_target_size = _new_size.snapped(_snapping_distance).clamp(_snapping_distance, Vector2.INF)
	move_to_front()
	_update_transform()


## Handles move request from internal UIPanel
func _on_panel_request_move(p_by: Vector2) -> void:
	_new_position += p_by
	_new_position = abs(_new_position)
	
	_target_position = snapped(_new_position, _snapping_distance)
	move_to_front()
	_update_transform()


## Called when self is resizes
func _on_resized() -> void:
	if _moved_on_process:
		_moved_on_process = false
		return
	
	_new_position = position
	_new_size = size
	_target_position = position
	_target_size = size
