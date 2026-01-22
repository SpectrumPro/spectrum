# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIColorPicker extends UIPanel
## UI Panel for showing a color picker


## The TextureRect for the Pad
@export var _pad: TextureRect

## Crosshair for the Pad
@export var _crosshair: TextureRect

## The VSlider for the Value
@export var _value_slider: VSlider

## Mix Mode selection
@export var _mix_mode: OptionButton


## The current color
var _color: Color = Color.WHITE

## Time since last call
var _last_call_time: int = 0

## 45 times per second
var _call_interval: float = 1.0 / 45.0

## All current selected fixtures
var _fixtures: Array

## The refernce fixture
var _refernce_fixture: Fixture


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIColorPicker")
	Values.connect_to_selection_value("selected_fixtures", _on_selected_fixture_changed)
	_on_selected_fixture_changed(Values.get_selection_value("selected_fixtures"))


## Called when the color is changed, will only output CoreEngine.call_interval times per second to avoid overloading the server
func _update_programmer() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	if current_time - _last_call_time >= _call_interval:
		_last_call_time = current_time
		Programmer.shortcut_set_color(_fixtures, _color, _mix_mode.selected)


## Called when the pad is resized
func _update_pad() -> void:
	_crosshair.position = Vector2(
		remap(_color.h, 0, 1, 0, _pad.size.x),
		remap(_color.s, 0, 1, _pad.size.y, 0)
		) - _crosshair.size / 2
	_update_slider()


## Updates the slider and backgroud color
func _update_slider() -> void:
	_pad.self_modulate = Color(_color.v, _color.v, _color.v)
	_crosshair.modulate = Color(1-_color.v , 1-_color.v , 1-_color.v)
	_value_slider.set_value_no_signal(_color.v)


## Called when the selected fixtures change
func _on_selected_fixture_changed(p_fixtures: Array) -> void:
	if _refernce_fixture:
		_refernce_fixture.remove_subscription(Fixture.RootZone, "ColorAdd_R", _on_fixture_red_changed)
		_refernce_fixture.remove_subscription(Fixture.RootZone, "ColorAdd_G", _on_fixture_green_changed)
		_refernce_fixture.remove_subscription(Fixture.RootZone, "ColorAdd_B", _on_fixture_blue_changed)
	
	_fixtures = p_fixtures
	_refernce_fixture = p_fixtures[0] if p_fixtures else null
	
	if _refernce_fixture:
		_refernce_fixture.subscribe_to_parameter(Fixture.RootZone, "ColorAdd_R", _on_fixture_red_changed)
		_refernce_fixture.subscribe_to_parameter(Fixture.RootZone, "ColorAdd_G", _on_fixture_green_changed)
		_refernce_fixture.subscribe_to_parameter(Fixture.RootZone, "ColorAdd_B", _on_fixture_blue_changed)


## Called when the red parameter is changed on the fixture
func _on_fixture_red_changed(p_red: float, _p_function: String, _p_override: bool) -> void:
	_color.r = p_red
	_update_pad()


## Called when the green parameter is changed on the fixture
func _on_fixture_green_changed(p_green: float, _p_function: String, _p_override: bool) -> void:
	_color.g = p_green
	_update_pad()


## Called when the blue parameter is changed on the fixture
func _on_fixture_blue_changed(p_blue: float, _p_function: String, _p_override: bool) -> void:
	_color.b = p_blue
	_update_pad()


## Called for all GUI imputs on the pad
func _on_texture_rect_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouse and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos: Vector2 = _pad.get_local_mouse_position().clamp(Vector2.ZERO, _pad.size)
		
		_color.h = remap(mouse_pos.x, 0, _pad.size.x, 0, 1)
		_color.s = remap(mouse_pos.y, _pad.size.y, 0, 0, 1)
		
		_crosshair.position = mouse_pos - _crosshair.size / 2
		_update_programmer()


## Called when the pad value slider is moved
func _on_pad_value_slider_value_changed(p_value: float) -> void:
	_color.v = p_value
	_update_slider()
	_update_programmer()
