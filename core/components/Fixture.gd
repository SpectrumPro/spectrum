# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name Fixture extends EngineComponent
## Engine class to control parameters of fixtures

## Emitted when the color of this fixture is changed 
signal color_changed(color: Color)

#signal mode_changed(mode: int) ## Emitted when the mode of the fixture is change

## Emitted when the channel of the fixture is changed
signal channel_changed(new_channel: int)

var current_values: Dictionary = {
	"set_color": 			Color.BLACK,
	"ColorIntensityWhite": 	0,
	"ColorIntensityAmber": 	0,
	"ColorIntensityUV": 	0,
	"Dimmer": 				0
}

## Universe channel of this fixture
var channel: int


## Called when this EngineComponent is ready
func _component_ready() -> void:
	name = "Fixture"
	self_class_name = "Fixture"

## INTERNAL: called when the color of this fixture is changed on the server
func on_color_changed(new_color: Color) -> void:
	current_values.set_color = new_color
	color_changed.emit(current_values.set_color)


## Sets the channel of this fixture
func set_channel(p_channel: int) -> void:
	Client.send({
		"for": self.uuid,
		"call": "set_channel",
		"args": [p_channel]
	})


## INTERNAL: called when the channel is changed on the server
func on_channel_changed(p_channel: int) -> void:
	channel = p_channel
	channel_changed.emit(channel_changed)


func _on_load_request(serialized_data: Dictionary) -> void:
	channel = serialized_data.get("channel", 1)
	
	current_values.merge(serialized_data.get("current_values", {}), true)
	
