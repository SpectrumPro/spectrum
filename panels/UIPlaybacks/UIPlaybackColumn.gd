# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIPlaybackColumn extends UIComponent
## The playback column container used in the playbacks panel

#
### Emitted when a button, or slider is pressed when in UIPlaybacks.Mode.EDIT
#signal control_pressed_edit_mode(control: Control)
#
#
### The Title Button
#@export var title_button: Button
#
### Button 1
#@export var button1: Button
#
### Button 2
#@export var button2: Button
#
### Button 3
#@export var button3: Button
#
### Button 4
#@export var button4: Button
#
### Button 5
#@export var button5: Button
#
### Button 6
#@export var button6: Button
#
### Slider
#@export var slider: VSlider
#
### All buttons, with a null for the slider
#@onready var _buttons: Array[Button] = [button1, button2, button3, null, button4, button5, button6]
#
#
### The current TriggerBlock
#var _trigger_block: TriggerBlock
#
### The EngineComponent asigned to this column
#var _component: EngineComponent
#
### Row start index
#var _row_start: int = 0
#
### Row Column
#var _column: int
#
### Edit mode state
#var _edit_mode: bool = false
#
### Current Mode
#var _mode: UIPlaybacks.Mode
#
### Autoconfig for Components
#var _auto_config: Dictionary[String, Array] = {
	#"Function": ["toggle", "flash", "on", "set_intensity", "off", "play", "pause"],
	#"CueList": ["go_previous", "go_next", "on", "set_intensity", "off", "play", "pause"],
#}
#
### Signals to connect to the component
#var _component_signal_connections: Dictionary[String, Callable] = {
	#"name_changed": _on_component_name_changed
#}
#
#
### Init
#func _init() -> void:
	#super._init()
	#_set_class_name("UIPlaybackColumn")
#
#
### Bind Signals
#func _ready() -> void:
	#for button: Button in _buttons:
		#if button:
			#var index: int = _buttons.find(button)
			#
			#button.pressed.connect(_on_button_pressed.bind(index))
			#button.button_down.connect(_on_button_down.bind(index))
			#button.button_up.connect(_on_button_up.bind(index))
			#
			#var id: String = str(_row_start + index) + "." + str(_column)
			#button.name = id
			#(button.get_node("ID") as Label).set_text(id)
#
#
### Sets the FunctionGroup
#func set_trigger_block(trigger_block: TriggerBlock) -> void:
	#_trigger_block = trigger_block
#
#
### Sets the column
#func set_column(column: int) -> void:
	#_column = column
#
#
### Sets the component
#func set_component(component: EngineComponent, no_remove: bool = false) -> void:
	#if component == _component:
		#return
	#
	#Utils.disconnect_signals(_component_signal_connections, _component)
	#_component = component
	#Utils.connect_signals(_component_signal_connections, _component)
	#
	#_set_disalbed(component == null)
	#title_button.text = component.get_name()
	#title_button.tooltip_text = component.get_name()
	#
	#if not no_remove and _trigger_block:
		#_trigger_block.reset_column(_column)
		#
		#var class_tree: Array[String] = _component.get_class_tree()
		#class_tree.reverse()
		#
		#for classname: String in class_tree:
			#if classname in _auto_config:
				#for control_method: String in _auto_config[classname]:
					#_trigger_block.add_trigger(_component, control_method, control_method.capitalize(), _row_start + _auto_config[classname].find(control_method), _column)
				#break
#
#
### Sets the edit mode state
#func set_edit_mode(edit_mode: bool) -> void:
	#_edit_mode = edit_mode
	#title_button.disabled = not edit_mode
#
#
### Sets the current mode
#func set_mode(p_mode: UIPlaybacks.Mode) -> void:
	#_mode = p_mode
#
#
### Gets all the buttons
#func get_buttons() -> Array[Button]:
	#return _buttons.duplicate()
#
#
### Sets the name of a row
#func set_row_name(row: int, p_name: String) -> void:
	#if row == 3:
		#pass # Slider
	#
	#elif row <= len(_buttons):
		#var button: Button = _buttons[row]
		#
		#if button:
			#button.set_text(p_name)
#
#
### Resets this PlaybackColumn
#func reset() -> void:
	#title_button.set_text("Empty")
	#title_button.set_tooltip_text("")
	#slider.set_editable(false)
	#_component = null
	#
	#for button: Button in _buttons:
		#if button:
			#button.set_disabled(true)
			#button.set_text("")
#
#
### Sets the disabled state of all buttons and sliders
#func _set_disalbed(disabled: bool) -> void:
	#title_button.disabled = disabled
	#slider.editable = not disabled
	#
	#for button: Button in _buttons:
		#if button:
			#button.set_disabled(disabled)
#
#
### Emitted when the component's name is changed
#func _on_component_name_changed(new_name: String) -> void:
	#title_button.set_text(new_name)
	#title_button.set_tooltip_text(new_name)
#
#
### Called when the Title Button is pressed
#func _on_title_pressed() -> void:
	#if _edit_mode:
		#match _mode:
			#UIPlaybacks.Mode.ASIGN:
				#Interface.show_object_picker(ObjectPicker.SelectMode.Single, func (objects: Array):
					#set_component(objects[0])
				#)
			#
			#UIPlaybacks.Mode.DELETE:
				#_trigger_block.reset_column(_column)
#
#
### Called when a button is clicked
#func _on_button_pressed(button_index: int) -> void:
	#if _edit_mode and _component:
		#match _mode:
			#UIPlaybacks.Mode.ASIGN:
				#Interface.show_control_method_picker(_component).then(func (control_name: String):
					#if control_name:
						#var config: Dictionary = _component.get_control_method(control_name)
						#_trigger_block.add_trigger(_component, control_name, control_name.capitalize(), _row_start + button_index, _column)
				#)
			#
			#UIPlaybacks.Mode.DELETE:
				#_trigger_block.remove_trigger(_row_start + button_index, _column)
			#
			#UIPlaybacks.Mode.EDIT:
				#control_pressed_edit_mode.emit(_buttons[button_index])
#
#
### Called when a button is pressed down
#func _on_button_down(button_index: int) -> void:
	#if _trigger_block and not _edit_mode:
		#_trigger_block.call_trigger_down(_row_start + button_index, _column)
#
#
### Called when a button is up
#func _on_button_up(button_index: int) -> void:
	#if _trigger_block and not _edit_mode:
		#_trigger_block.call_trigger_up(_row_start + button_index, _column)
#
#
### Called when the Slider value changes
#func _on_v_slider_value_changed(value: float) -> void:
	#if _edit_mode and _component:
		#match _mode:
			#UIPlaybacks.Mode.ASIGN:
				#Interface.show_control_method_picker(_component).then(func (control_name: String):
					#if control_name:
						#var config: Dictionary = _component.get_control_method(control_name)
						#_trigger_block.add_trigger(_component, control_name, control_name.capitalize(), _row_start + 3, _column)
				#)
			#
			#UIPlaybacks.Mode.DELETE:
				#_trigger_block.remove_trigger(_row_start + 3, _column)
			#
			#UIPlaybacks.Mode.EDIT:
				#control_pressed_edit_mode.emit(slider)
	#
	#elif _trigger_block and not _edit_mode:
		#_trigger_block.call_trigger_down(_row_start + 3, _column, value)
