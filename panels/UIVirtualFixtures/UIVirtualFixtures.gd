# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIVirtualFixtures extends UIPanel
## Layout view for showing vixtures


## Zoom step value for zoom buttons
const zoom_step: Vector2 = Vector2(0.05, 0.05)

## Min zoom size
const min_zoom: float = 0.2

## Max zoom size
const max_zoom: float = 5


## The fake scroll container, only used for the scroll bars
@export var dummy_scroll: ScrollContainer

## The real scroll container that moves the content
@export var real_scroll: ScrollContainer

## The virtual fixture container
@export var fixture_container: VirtualFixtureContainer

## The Remove fixture button
@export var remove_fixture_button: Button 

## The HorizontalAlign
@export var horizontal_align_button: Button

## The VerticalAlign
@export var vertical_align_button: Button

## The GridAlign button
@export var grid_align_button: Button

## The ComponentButton
@export var component_button: ComponentButton


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIVirtualFixtures")


## ready
func _ready() -> void:
	dummy_scroll.get_h_scroll_bar().value_changed.connect(real_scroll.set_h_scroll)
	dummy_scroll.get_v_scroll_bar().value_changed.connect(real_scroll.set_v_scroll)
	
	real_scroll.get_h_scroll_bar().value_changed.connect(dummy_scroll.get_h_scroll_bar().set_value_no_signal)
	real_scroll.get_v_scroll_bar().value_changed.connect(dummy_scroll.get_v_scroll_bar().set_value_no_signal)
	
	var canvas_size: Vector2 = $Table/RealScroll/ScrollSize.size
	real_scroll.scroll_horizontal = (canvas_size.x / 2) - size.x / 2
	real_scroll.scroll_vertical = (canvas_size.y / 2) - size.y / 2
	
	fixture_container.selected_virtual_fixtures_changed.connect(_on_selected_virtual_fixtures_changed)
	set_edit_mode_disabled(true)


## Zooms in the canvas
func _zoom_in() -> void:
	fixture_container.scale += zoom_step
	#_update_scroll_containers()


## Zooms out the canvas
func _zoom_out() -> void:
	fixture_container.scale -= zoom_step
	#_update_scroll_containers()


## Sets edit mode state
func _edit_mode_toggled(p_edit_mode: bool) -> void:
	fixture_container.set_edit_mode(_edit_mode)
	$TitleBar/HBoxContainer/EditControls/HBoxContainer/Edit.button_pressed = _edit_mode
	$GridAlignSize.hide()


## Called when the selected virtual fixtures changes
func _on_selected_virtual_fixtures_changed(p_fixtures: Array) -> void:
	var disabled: bool = p_fixtures == []
	remove_fixture_button.disabled = disabled
	horizontal_align_button.disabled = disabled
	vertical_align_button.disabled = disabled
	grid_align_button.disabled = disabled
	
	if disabled:
		$GridAlignSize.hide()


## Called when when there is a GUI input on the fixture container
func _on_fixture_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
		real_scroll.scroll_horizontal -= event.relative.x
		dummy_scroll.scroll_horizontal = real_scroll.scroll_horizontal
		
		real_scroll.scroll_vertical -= event.relative.y
		dummy_scroll.scroll_vertical = real_scroll.scroll_vertical


## Updates the width and height of the scroll containers with the new canvas size and zoom level
func _update_scroll_containers() -> void:
	real_scroll.get_node("ScrollSize").custom_minimum_size = fixture_container.size * fixture_container.scale
	dummy_scroll.get_node("ScrollSize").custom_minimum_size = fixture_container.size * fixture_container.scale


## Calle when the grid align button is pressed
func _on_grid_align_pressed() -> void:
	$GridAlignSize.show()


## Saves this VirtualFixture layout into a dict
func serialize() -> Dictionary:
	return super.serialize().merged({
		"fixture_group": component_button.get_component_uuid(),
		"scroll_h": real_scroll.scroll_horizontal,
		"scroll_v": real_scroll.scroll_vertical,
		"zoom": fixture_container.scale.x
	})


## Loads this VirtualFixture layout from a dict
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	var group_uuid: String = type_convert(p_serialized_data.get("fixture_group", ""), TYPE_STRING)
	var zoom: int = type_convert(p_serialized_data.get("zoom", fixture_container.scale.x), TYPE_INT)
	
	component_button.look_for(group_uuid)
	
	real_scroll.scroll_horizontal = type_convert(p_serialized_data.get("scroll_h", real_scroll.scroll_horizontal), TYPE_INT)
	real_scroll.scroll_vertical = type_convert(p_serialized_data.get("scroll_v", real_scroll.scroll_vertical), TYPE_INT)
	
	fixture_container.scale = Vector2(
		zoom,
		zoom
	)
