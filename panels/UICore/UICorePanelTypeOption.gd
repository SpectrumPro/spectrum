# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UICorePanelTypeOption extends Control
## UICorePanelTypeOption


## The AddDesk button
@export var add_desk_button: Button

## The AddCustom button
@export var add_custom_button: Button

## The UICorePrimarySideBar
@export var side_bar: UICorePrimarySideBar


## Ready
func _ready() -> void:
	add_desk_button.pressed.connect(_on_add_desk_pressed)
	add_custom_button.pressed.connect(_on_add_custom_pressed)
	side_bar.tab_changed.connect(_on_side_bar_tab_changed)
	side_bar.empty_tab_selected.connect(_on_side_bar_empty_tab_selected)
	
	visible = (side_bar.get_current_empty_tab() != -1)


## Called when the AddDesk button is pressed
func _on_add_desk_pressed() -> void:
	side_bar.create_tab(UIDB.instance_panel(UIDesk), side_bar.get_current_empty_tab()).set_title("Desk")


## Called when the AddCustom button is pressed
func _on_add_custom_pressed() -> void:
	Popups.PanelPicker(self).then(func (p_panel_class: String):
		var panel: UIPanel = UIDB.instance_panel(p_panel_class)
		side_bar.create_tab(panel, side_bar.get_current_empty_tab()).set_title(panel.get_uname())
	)


## Called when a tab is selected
func _on_side_bar_tab_changed(p_tab: UICorePrimarySideBar.TabItem) -> void:
	if visible and is_instance_valid(p_tab): 
		Interface.fade_and_hide(self)


## Called when an empty tab is selected
func _on_side_bar_empty_tab_selected(p_index: int) -> void:
	if not visible and p_index != -1: 
		Interface.show_and_fade(self)
	
