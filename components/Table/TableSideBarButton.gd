# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name TableSideBarButton extends Button
## Sidebar button for the Table


## Emitted when this button is right clicked
signal right_clicked()


## Icon to display when the row is folded
var _folded_icon: Texture2D = preload("res://assets/icons/Unfold.svg")

## Icon to display when the row is unfolded
var _unfolded_icon: Texture2D = preload("res://assets/icons/Fold.svg")


## The folded state of this button
var _folded: bool

## The icon visable state of this button
var _icon_visable: bool


## Sets this button folded or un folded icon
func set_folded(p_folded: bool) -> void:
	_folded = p_folded
	
	if _folded:
		set_button_icon(_folded_icon)
	else:
		set_button_icon(_unfolded_icon)


## Sets the icon visable state
func set_icon_visable(p_icon_visable: bool) -> void:
	_icon_visable = p_icon_visable
	
	if _icon_visable:
		set_folded(_folded)
	else:
		set_button_icon(null)


## Returns the folded state of this button
func get_folded() -> bool:
	return _folded


## Returns the icon visable state
func get_icon_visable() -> bool:
	return _icon_visable


## Called for each GUI input
func _on_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.is_pressed():
		
		match p_event.button_index:
			MOUSE_BUTTON_RIGHT:
				right_clicked.emit()
