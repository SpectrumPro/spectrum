# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIPopupDialog extends UIPopup
## UIPopupDialog


## Emitted when a button is pressed that Represents a non bool option
signal option_chosen(option: Variant)


## The Control to contain all nodex
@export var container: Control

## The title Button
@export var title_button: Button


## Enum for Preset
enum Preset {
	CONFIRM,
	DELETE,
}


## The current line
var _current_line: HBoxContainer = HBoxContainer.new()

## The imbedded Promise
var _promise: Promise

## Array of all labels
var _labels: Array[Label]

## Array of all buttons
var _buttons: Array[Button]

## config for each preset
var _preset_config: Dictionary[Preset, Callable] = {
	Preset.CONFIRM: (func (p_label: String):
		title(p_label if p_label else "Please confirm this action.")
		button("Cancel", false)
		button("Confirm", true)
		),
	Preset.DELETE: (func (p_label: String):
		title(p_label if p_label else "Confirm deletion? This action can't be undone.")
		button("Cancel", false)
		button("Delete", true, Color.RED)
		),
}


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIPopupDialog")


## Ready
func _ready() -> void:
	new_line()


## Focuses this input
func focus() -> void:
	if _buttons:
		_buttons[0].grab_focus()
	else:
		edit_controls.close_button.grab_focus()


## Loads a preset
func preset(p_preset: Preset, p_custom_label: String = "") -> UIPopupDialog:
	if not is_node_ready():
		return self
	
	_preset_config[p_preset].call(p_custom_label)
	
	return self


## Returns the imbedded promise
func promise() -> Promise:
	return _promise


## Sets the popup title
func title(p_title: String) -> void:
	title_button.set_text(p_title)


## Adds a label
func label(p_text: String) -> UIPopupDialog:
	if not is_node_ready():
		return self
	
	var new_label: Label = Label.new()
	_labels.append(new_label)
	
	new_label.set_text(p_text)
	new_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	_current_line.add_child(new_label)
	return self


## Adds a button
func button(p_text: String, p_return_value: Variant, p_color: Color = Color.TRANSPARENT) -> UIPopupDialog:
	if not is_node_ready():
		self
	
	var new_button: Button = Button.new()
	_buttons.append(new_button)
	
	new_button.set_text(p_text)
	new_button.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	new_button.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	
	if p_color != Color.TRANSPARENT:
		new_button.add_theme_color_override("font_color", p_color)
		new_button.add_theme_color_override("font_focus_color", p_color)
		new_button.add_theme_color_override("font_pressed_color", p_color)
		new_button.add_theme_color_override("font_hover_color", p_color)
	
	match typeof(p_return_value):
		TYPE_BOOL:
			if p_return_value:
				new_button.pressed.connect(func (): accept())
			else:
				new_button.pressed.connect(cancel)
		_:
			set_custom_accepted_signal(option_chosen)
			new_button.pressed.connect(func (): accept(p_return_value))
	
	_current_line.add_child(new_button)
	return self


## Moves to a new line
func new_line() -> UIPopupDialog:
	if not is_node_ready():
		return self
	
	_current_line = HBoxContainer.new()
	_current_line.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	
	container.add_child(_current_line)
	return self


## Fowards Promise.then
func then(p_callback: Callable) -> UIPopupDialog:
	_promise.then(p_callback)
	return self


## Fowards Promise.catch
func catch(p_callback: Callable) -> UIPopupDialog:
	_promise.catch(p_callback)
	return self


## Sets the imbedded Promise
func set_promise(p_promise: Promise) -> UIPopupDialog:
	_promise = p_promise
	return self
