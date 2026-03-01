# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIWindowManager extends UIPanel
## UIWindowManager for managing windows


## SettingsManagerView for the selected window
@export var settings_manager_multi_view: SettingsManagerMultiView

## The FocusWindow button
@export var focus_window_button: Button

## The DeleteWindowButton
@export var delete_window_button: Button


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIWindowManager")


## Ready
func _ready() -> void:
	Interface.window_added.connect(_add_window)
	Interface.window_removed.connect(_remove_window)
	
	for window: UIWindow in Interface.get_all_windows():
		_add_window(window)


## Called when a window is added
func _add_window(p_window: UIWindow) -> void:
	settings_manager_multi_view.add_manager(p_window.settings())


## Called when an item is removed
func _remove_window(p_window: UIWindow) -> void:
	settings_manager_multi_view.remove_manager(p_window.settings())


## Updates buttons disabled state
func _update_buttons() -> void:
	var selected_window: UIWindow = settings_manager_multi_view.get_selected_owner()
	var state: bool = selected_window == null
	
	if selected_window and selected_window.is_window_root():
		state = true
	
	delete_window_button.set_disabled(state)
	focus_window_button.set_disabled(state)


## Called when the AddWindow button is pressed
func _on_add_window_pressed() -> void:
	Interface.add_window()


## Called when the FocusWindow button is pressed
func _on_focus_window_pressed() -> void:
	var selected_window: UIWindow = settings_manager_multi_view.get_selected_owner()
	
	if is_instance_valid(selected_window):
		selected_window.set_window_visible(true)
		selected_window.grab_focus()


## Called when the DeleteWindow button is pressed
func _on_delete_window_pressed() -> void:
	var selected_window: UIWindow = settings_manager_multi_view.get_selected_owner()
	
	if is_instance_valid(selected_window):
		Popups.show_delete_confirmation(self, str("Delete: ", selected_window.get_window_title(), "?")).then(func ():
			Interface.remove_window(selected_window)
			_update_buttons()
		)


## Called when the IdentifyWindows button is pressed
func _on_identify_windows_toggled(p_toggled_on: bool) -> void:
	if p_toggled_on:
		Interface.show_window_id()
	else:
		Interface.hide_window_id()
