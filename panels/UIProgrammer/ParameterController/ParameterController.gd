# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ParameterController extends PanelContainer
## Controls a parameter of a fixrure


## Emitted when the value is changed
signal value_changed(value: float)

## Emitted when a function is selected
signal function_selected(function: String)

## Emitted when an override is added to the refernce fixture
signal fixture_override_added()

## Emitted when the erase is pressed
signal erase_pressed()


## FunctionList node for displaying all parameter functions
@export var _function_list: OptionButton

## The VSlider node for changing a parameter's value
@export var _slider: VSlider

## The NameLabel for the parameter
@export var _title_button: Button

## TitleBar PanelContainer
@export var _title_bar: PanelContainer

## The Label to show the value
@export var _value_label: Label

## The GridContainer to contain all preset buttons
@export var _preset_container: GridContainer


## Font size in PX for the preset buttons
const PRESET_BUTTON_FONT_SIZE: int = 12

## Number of Intensity percentage presets to show
const NUM_INTENSITY_PRESETS: int = 5


## The Fixture this ParameterControler is basing its value updates off
var _refernce_fixture: Fixture

## Current override state of the refernce fixture
var _override_state: bool = false

## The parameter this ParameterController controls
var _parameter: String = ""

## The zone of this parameter
var _zone: String = ""

## All the current displayed functions
var _functions: Array[String]

## The StyleBoxFlat for the title
var _title_stylebox: StyleBoxFlat = null

## Default color of this ParameterController
var _default_color: Color = Color(0.129, 0.129, 0.129)


## Ready
func _ready() -> void:
	_title_stylebox = _title_bar.get_theme_stylebox("panel").duplicate()
	_title_bar.add_theme_stylebox_override("panel", _title_stylebox)
	_default_color = _title_stylebox.get_bg_color()


## Sets the parameter
func set_parameter(p_parameter: String) -> void:
	_parameter = p_parameter
	_title_button.set_text(_parameter)


## Sets the zone
func set_zone(p_zone: String) -> void:
	_zone = p_zone


## Sets the value of this parameter, no signal
func set_value(value: float) -> void:
	_slider.set_value_no_signal(value)
	_set_label_value(value)


## Setst the value of this ParameterControler to the current fixture value
func set_value_fixture() -> void:
	if not _refernce_fixture:
		return
	
	set_value(_refernce_fixture.get_current_value(_zone, _parameter))
	set_function(_refernce_fixture.get_current_function(_zone, _parameter))


## Sets the current selected function
func set_function(function: String) -> void:
	_function_list.select(_functions.find(function))
	
	if is_instance_valid(_refernce_fixture):
		load_presets()
	else:
		load_presets.call_deferred()


## Sets the state of the override background
func set_override_bg(p_state: bool) -> void:
	var target: Color
	
	if p_state:
		target = ThemeManager.Colors.Statuses.ProgrammerOverride
	else:
		target = _default_color
	
	get_tree().create_tween().tween_property(_title_stylebox, "bg_color", target, ThemeManager.Constants.Times.InterfaceFadeFast)
	_override_state = p_state


## Adds an item to the function list
func add_function(function: String) -> void:
	_functions.append(function)
	_function_list.add_item(function)
	_function_list.selected = 1


## Checks if this ParameterController has a function:
func has_function(function: String) -> bool:
	return _functions.has(function)


## Gets the parameter
func get_parameter() -> String:
	return _parameter


## Gets the zone
func get_zone() -> String:
	return _zone


## Gets the current value
func get_value() -> float:
	return _slider.value


## Gets the current selected function
func get_function() -> String:
	var selected: int = _function_list.get_selected_id() == -1
	
	if selected == -1:
		return ""
	else:
		return _function_list.get_item_text(selected)


## Gets the refernce fixture
func get_refernce_fixture() -> Fixture:
	return _refernce_fixture
 

## Subscribes to the given fixture
func subscribe(p_fixture: Fixture) -> void:
	if is_instance_valid(_refernce_fixture):
		remove_subscription()
	
	_refernce_fixture = p_fixture
	_refernce_fixture.subscribe_to_parameter(_zone, _parameter, _on_fixture_value_changed)
	
	_override_state = _refernce_fixture.has_override(_zone, _parameter)


## Removes the subscription to the fixture
func remove_subscription() -> void:
	if not is_instance_valid(_refernce_fixture):
		return
	
	_refernce_fixture.remove_subscription(_zone, _parameter, _on_fixture_value_changed)


## Loads all the presets based on the current selected function
func load_presets() -> void:
	for old_preset: Control in _preset_container.get_children():
		old_preset.queue_free()
	
	if not _refernce_fixture:
		return
	
	match _refernce_fixture.get_function_control_type(_zone, _parameter, get_function()):
		Fixture.ControlType.INTENSITY, Fixture.ControlType.VALUE:
			var presets: Array[float] = _generate_preset_values(NUM_INTENSITY_PRESETS)
			
			for value: float in presets:
				_add_preset_button(value, str(int(value * 100)) + "%")


## Clears this ParameterController
func clear() -> void:
	_functions.clear()
	_function_list.clear()
	_slider.set_value_no_signal(0)
	_refernce_fixture = null
	
	remove_subscription()
	set_override_bg(false)
	load_presets()


## Returns an array with preset values
func _generate_preset_values(p_num_presets: int) -> Array[float]:
	if p_num_presets <= 0:
		return []
	if p_num_presets == 1:
		return [1.0]
	
	var presets: Array[float] = []
	var step: float = 1.0 / float(p_num_presets - 1)
	
	for i in range(p_num_presets):
		presets.append(i * step)
	
	return presets


## Adds a preset value button
func _add_preset_button(p_value: float, p_text: String) -> void:
	var new_button: Button = Button.new()
	
	new_button.set_text(p_text)
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(_set_value.bind(p_value))
	
	_preset_container.add_child(new_button)


## Sets and emits the value
func _set_value(p_value: float) -> void:
	value_changed.emit(p_value)
	_set_label_value(p_value)


## Sets the value on the label
func _set_label_value(p_value: float) -> void:
	_value_label.set_text(str(snappedf(p_value * 100, 0.1)) + "%")


## Called when the value is changed on the selected fixture
func _on_fixture_value_changed(p_value: float, p_function: String, p_override: bool) -> void:
	set_value(p_value)
	set_function(p_function)
	
	if p_override != _override_state and p_override:
		fixture_override_added.emit()
		_override_state = p_override


## Called when the Erace button is pressed
func _on_erase_pressed() -> void:
	erase_pressed.emit()


## Called when the default button is pressed
func _on_default_pressed() -> void:
	_set_value(_refernce_fixture.get_default(_zone, _parameter, get_function()))


## Called when a function is selected
func _on_function_list_item_selected(index: int) -> void:
	function_selected.emit(_function_list.get_item_text(index))


## Called for each GUI input on the value label
func _on_value_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.button_index == MOUSE_BUTTON_LEFT and p_event.is_pressed():
		_set_value(get_value())
