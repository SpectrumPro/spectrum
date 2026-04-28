# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name VirtualFixture extends UIComponent
## Control to display a fixture in the UIVirtualFixtures tabke


## Emitted when this virtual fixture is moved
signal move_requested(by: Vector2)

## Emitted when this fixture is clicked
signal clicked()

## Emitted when the mouse left button is released
signal released()


## Color of this VF when it the fixture is selected
const fixture_selected_color: Color = Color.ROYAL_BLUE

## Color of this VF when self is selected
const self_selected_color: Color = Color.WHITE


## The position of this VirtualFixtue with out grid snapping
var no_snap_pos: Vector2

## The fixture linked to this virtual fixture
var _fixture: Fixture = null


## Signals to connect to the fixture
var _fixture_signal_connections: SignalGroup = SignalGroup.new([], {
	"override_changed": _on_override_value_changed,
	"override_erased": _on_override_value_erased,
	"all_override_removed": _on_override_value_erased,
	"parameter_changed": _on_parameter_changed,
	"parameter_erased": _on_parameter_eraced,
	"manifest_changed": _on_dmx_fixture_manifest_changed,
	"name_changed": set_label_name
})


## init
func _init() -> void:
	super._init()
	
	_set_class_name("VirtualFixture")


## ready
func _ready() -> void:
	no_snap_pos = position


## Sets the fixture linked to this virtual fixture
func set_fixture(control_fixture: Fixture) -> void:
	_fixture_signal_connections.disconnect_object(_fixture)
	_fixture = control_fixture
	_fixture_signal_connections.connect_object(_fixture)
	
	if _fixture.has_overrides():
		$Override.show()
	
	if _fixture is DMXFixture and not _fixture.get_manifest():
		pass
	else:
		render_color()
	
	set_label_name(control_fixture.get_name())
	$UUID.text = control_fixture.get_uuid()


## Gets the fixture linked to this virtual fixture
func get_fixture() -> Fixture:
	return _fixture


## Sets the BG color of this virtual fixture
func render_color():
	var base_color: Color = Color.WHITE
	var parameters: Dictionary = _fixture.get_all_values().get("root", {})
	var overrides: Dictionary = _fixture.get_all_override_values().get("root", {})
	
	parameters.merge(overrides, true)
	
	if _fixture.has_parameter("root", "ColorAdd_R") and "ColorAdd_R" in parameters:
		base_color.r = parameters["ColorAdd_R"].value
	
	if _fixture.has_parameter("root", "ColorAdd_G") and "ColorAdd_G" in parameters:
		base_color.g = parameters["ColorAdd_G"].value
	
	if _fixture.has_parameter("root", "ColorAdd_B") and "ColorAdd_B" in parameters:
		base_color.b = parameters["ColorAdd_B"].value
	
	
	if _fixture.has_parameter("root", "ColorRGB_Red") and "ColorRGB_Red" in parameters:
		base_color.r = parameters["ColorRGB_Red"].value
	
	if _fixture.has_parameter("root", "ColorRGB_Green") and "ColorRGB_Green" in parameters:
		base_color.g = parameters["ColorRGB_Green"].value
	
	if _fixture.has_parameter("root", "ColorRGB_Blue") and "ColorRGB_Blue" in parameters:
		base_color.b = parameters["ColorRGB_Blue"].value
	
	
	if _fixture.has_parameter("root", "ColorAdd_W") and "ColorAdd_W" in parameters:
		base_color = Utils.blend_color_additive(base_color, Color.WHITE * parameters["ColorAdd_W"].value)
	
	if _fixture.has_parameter("root", "ColorAdd_RY") and "ColorAdd_RY" in parameters:
		base_color = Utils.blend_color_additive(base_color, Color.ORANGE * parameters["ColorAdd_RY"].value)
	
	if _fixture.has_parameter("root", "ColorAdd_UV") and "ColorAdd_UV" in parameters:
		base_color = Utils.blend_color_additive(base_color, Color.BLUE_VIOLET * parameters["ColorAdd_UV"].value)
	
	
	if _fixture.has_parameter("root", "ColorSub_C") and "ColorSub_C" in parameters:
		base_color.r -= parameters["ColorSub_C"].value
	
	if _fixture.has_parameter("root", "ColorSub_M") and "ColorSub_M" in parameters:
		base_color.g -= parameters["ColorSub_M"].value
	
	if _fixture.has_parameter("root", "ColorSub_Y") and "ColorSub_Y" in parameters:
		base_color.b -= parameters["ColorSub_Y"].value
	
	
	if _fixture.has_parameter("root", "Dimmer"):
		if "Dimmer" in parameters:
			base_color = base_color * parameters["Dimmer"].value
		else:
			base_color = Color.BLACK
	
	
	set_color(base_color)


## Sets the base color
func set_color(color: Color) -> void:
	color.a = 1
	$Color.modulate = color


## Sets the selection highlight
func set_fixture_selected(state: bool) -> void:
	if state:
		$Highlight.modulate = fixture_selected_color
		$Highlight.show()
	else:
		$Highlight.hide()


## Sets the self highlight
func set_self_selected(state: bool) -> void:
	if state:
		$Highlight.modulate = self_selected_color
		$Highlight.show()
	else:
		$Highlight.hide()


## Sets the name label
func set_label_name(p_name: String) -> void:
	$Name.text = p_name


## Called when a parameter is changed on a fixture
func _on_parameter_changed(zone: String, parameter: String, function: String, value: Variant) -> void:
	render_color()


## Called when a parameter is eraced on a fixture
func _on_parameter_eraced(zone: String, parameter: String) -> void:
	render_color()


## Called when a override value is changed on a fixture
func _on_override_value_changed(zone: String, parameter: String, function: String, value: Variant) -> void: 
	$Override.show()
	render_color()


## Called when an override value is removed from the fixture
func _on_override_value_erased(zone: String = "", parameter: String = "") -> void:
	if not _fixture.has_overrides():
		$Override.hide()
	
	render_color()


## Called when the manifest is changed on a DMXFixture
func _on_dmx_fixture_manifest_changed(p_manifest: FixtureManifest, p_mode: String):
	render_color()



func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		move_requested.emit(event.relative) 
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			clicked.emit()
			
		elif event.is_released():
			released.emit()
