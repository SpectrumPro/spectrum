# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIMainMenu extends UIPanel
## UIMainMenu 


@export_group("Settings Button")

## The AllSettings Button
@export var all_settings_button: Button

## The NetworkManagerSettings Button
@export var network_manager_settings_button: Button

## The ExternalInputSettings Button
@export var external_input_settings_button: Button


@export_group("WindowManager Buttons")

## The WindowManager Button
@export var window_manager_button: Button

## The NewWindow Button
@export var new_window_button: Button

## The MoveWindow Button
@export var move_window_button: Button


@export_group("SaveLoad Buttons")

## The SaveLoad Button
@export var save_load_button: Button

## The SaveFile Button
@export var save_file_button: Button

## The LoadFile Button
@export var load_file_button: Button


## The UISetting popup for this window
@onready var _settings_panel: UISetting = Interface.get_window_popup(Interface.WindowPopup.SETTINGS, self)

## The UISaveLoad popup for this window
@onready var _window_manager_panel: UIWindowManager = Interface.get_window_popup(Interface.WindowPopup.WINDOW_MANAGER, self)

## The UISaveLoad popup for this window
@onready var _save_load_panel: UISaveLoad = Interface.get_window_popup(Interface.WindowPopup.SAVE_LOAD, self)


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIMainMenu")


## Ready
func _ready() -> void:
	_settings_panel.visibility_changed.connect(func (): all_settings_button.set_pressed_no_signal(_settings_panel.visible))
	_window_manager_panel.visibility_changed.connect(func (): window_manager_button.set_pressed_no_signal(_window_manager_panel.visible))
	_save_load_panel.visibility_changed.connect(func (): save_load_button.set_pressed_no_signal(_save_load_panel.visible))


## Called when the AllSettings Button is toggled
func _on_all_settings_toggled(p_toggled_on: bool) -> void:
	Interface.set_popup_visable(Interface.WindowPopup.SETTINGS, self, p_toggled_on)
	close_request.emit()


## Called when the NetworkManager button is pressed
func _on_network_manager_settings_pressed() -> void:
	Interface.set_popup_visable(Interface.WindowPopup.SETTINGS, self, true)
	_settings_panel.switch_to_tab(UISetting.Tab.NetworkManager)
	close_request.emit()


## Called when the ExternalInput button is pressed
func _on_external_input_settings_pressed() -> void:
	Interface.set_popup_visable(Interface.WindowPopup.SETTINGS, self, true)
	_settings_panel.switch_to_tab(UISetting.Tab.Shortcuts)
	close_request.emit()


## Called when the SaveLoad Button is toggled
func _on_save_load_toggled(p_toggled_on: bool) -> void:
	Interface.set_popup_visable(Interface.WindowPopup.SAVE_LOAD, self, p_toggled_on)
	close_request.emit()


## Called when the SaveFile button is pressed
func _on_save_file_pressed() -> void:
	Core.save_to_file()


## Called when the WindowManager button is pressed
func _on_window_manager_toggled(p_toggled_on: bool) -> void:
	Interface.set_popup_visable(Interface.WindowPopup.WINDOW_MANAGER, self, p_toggled_on)
	close_request.emit()


## Called when the NewWindow button is pressed
func _on_new_window_pressed() -> void:
	Interface.add_window()


## Called when the SetDisplayMode button is pressed
func _on_set_display_mode_pressed() -> void:
	Interface.prompt_settings_module(self, Interface.get_window_node(self).settings().get_entry("display_mode"))
