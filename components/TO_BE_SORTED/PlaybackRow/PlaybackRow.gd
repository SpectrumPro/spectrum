# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name PlaybackRowComponent extends MarginContainer
## The playback row container used in the playbacks panel


## Emitted when a button or slider is selected in a dummy row
signal dummy_row_item_selected(item: Control)

## Emitted when the label is changed
signal label_changed(new_label: String)


## The buttons and sliders
@onready var button1: TriggerButton = get_node("PanelContainer/MarginContainer/VBoxContainer/Button1")
@onready var button2: TriggerButton = get_node("PanelContainer/MarginContainer/VBoxContainer/Button2")
@onready var button3: TriggerButton = get_node("PanelContainer/MarginContainer/VBoxContainer/Button3")
@onready var button4: TriggerButton = get_node("PanelContainer/MarginContainer/VBoxContainer/Button4")
@onready var button5: TriggerButton = get_node("PanelContainer/MarginContainer/VBoxContainer/Button5")
@onready var slider: TriggerSlider = get_node("PanelContainer/MarginContainer/VBoxContainer/Slider")


## Config for auto mode, will auto set up buttons and slider for differnt object types
@onready var auto_config: Dictionary = {
	"Scene": {
		button1: {
			"label": "Toggle",
			"button_down": { "method_name": "Toggle", "args": [] },
		},
		button2: {
			"label": "Enable",
			"button_down": { "method_name": "on", "args": [] },
		},
		button3: {"visible": false},
		button4: {
			"label": "Disable",
			"button_down": { "method_name": "off", "args": [] },
		},
		button5: {"visible": false},
		slider: { 
			"trigger": { "method_name": "intensity" },
			"feedback": { "method_name": "intensity" }
		}
	},
	"CueList": {
		button1: {
			"label": "Enable", 
			"button_down": { "method_name": "on" },
		},
		button2: {
			"label": "Pause",
			"button_down": { "method_name": "pause" },
		},
		button3: {
			"label": "Disable",
			"button_down": { "method_name": "off" },
		},
		button4: {
			"label": "Go Previous",
			"button_down": { "method_name": "go_previous" },
		},
		button5: {
			"label": "Go Next",
			"button_down": { "method_name": "go_next" },
		},
		slider: { 
			"trigger": { "method_name": "intensity" },
			"feedback": { "method_name": "intensity" }
		}
	}
}


## Sets the value of the slider, converting from 0-1 to 0-155
func set_slider_value(value: float) -> void:
	slider.set_value_no_signal(remap(value, 0.0, 1.0, 0, 255))


## Sets and gets the label text
func set_label(text: String) -> void: 
	$PanelContainer/MarginContainer/VBoxContainer/Label.text = text
	label_changed.emit(text)

func get_label() -> String: return $PanelContainer/MarginContainer/VBoxContainer/Label.text


## Creates a dummy version of this playback row. Will copy all visual settings. Used in settings menues
func create_dummy_row() -> Control:
	var dummy_row: PlaybackRowComponent = Interface.components.PlaybackRow.instantiate()
	dummy_row.set_label(get_label())
	label_changed.connect(dummy_row.set_label)
	
	var connect_signals_function: Callable = func () -> void:
		await dummy_row.ready 
		dummy_row.button1.focus_entered.connect(func () -> void: dummy_row_item_selected.emit(button1))
		dummy_row.button2.focus_entered.connect(func () -> void: dummy_row_item_selected.emit(button2))
		dummy_row.button3.focus_entered.connect(func () -> void: dummy_row_item_selected.emit(button3))
		dummy_row.button4.focus_entered.connect(func () -> void: dummy_row_item_selected.emit(button4))
		dummy_row.button5.focus_entered.connect(func () -> void: dummy_row_item_selected.emit(button5))
		dummy_row.slider.focus_entered.connect(func () -> void: dummy_row_item_selected.emit(slider))
		
		dummy_row.button1.make_dummy_of(button1)
		dummy_row.button2.make_dummy_of(button2)
		dummy_row.button3.make_dummy_of(button3)
		dummy_row.button4.make_dummy_of(button4)
		dummy_row.button5.make_dummy_of(button5)
		
	connect_signals_function.call()
	
	return dummy_row 


## Auto configures the buttons and slider for a component
func load_auto_config(component: EngineComponent) -> void:
	if component.self_class_name in auto_config:
		for trigger: Control in auto_config[component.self_class_name].keys():
			
			if trigger is TriggerButton:
				var button: TriggerButton = trigger
				var config: Dictionary = auto_config[component.self_class_name][button].duplicate(true)
				
				if config.get("button_down", ""): config.button_down.uuid = component.uuid
				if config.get("button_up", ""): config.button_up.uuid = component.uuid
				
				button.deserialize(config)
			
			if trigger is TriggerSlider:
				var slider: TriggerSlider = trigger
				var config: Dictionary = auto_config[component.self_class_name][slider].duplicate(true)
				
				if config.get("trigger", {}): config.trigger.uuid = component.uuid
				if config.get("feedback", {}): config.feedback.uuid = component.uuid
				
				slider.deserialize(config)
				
		
		set_label(component.name())


## Saves this PlayBack row into a dict
func serialize() -> Dictionary:
	return {
		"label": get_label(),
		"button1": button1.serialize(),
		"button2": button2.serialize(),
		"button3": button3.serialize(),
		"button4": button4.serialize(),
		"button5": button5.serialize(),
		"slider": slider.serialize()
	}


## Loads this playback row from a dict
func deserialize(serialized_data: Dictionary) -> void:
	set_label(serialized_data.get("label", get_label()))
	
	button1.deserialize(serialized_data.get("button1", {}))
	button2.deserialize(serialized_data.get("button2", {}))
	button3.deserialize(serialized_data.get("button3", {}))
	button4.deserialize(serialized_data.get("button4", {}))
	button5.deserialize(serialized_data.get("button5", {}))
	slider.deserialize(serialized_data.get("slider", {}))
