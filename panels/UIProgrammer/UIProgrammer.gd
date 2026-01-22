# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIProgrammer extends UIPanel
## Programmer to adust the settings and paramiters of Fixtures


## Emitted when the number of controlers per page is changed
signal controlers_per_page_changed(controlers: int)


## The default number of ParameterControlers per page
@export var default_controlers_per_page: int = 4

## Min size X for tab buttons
@export var tab_button_min_size: int = 80


@export_group("Nodes")

## The HBoxContainer for all tab buttons
@export var tab_button_container: HBoxContainer

## The HBoxContainer for all layer buttons
@export var layer_button_container: HBoxContainer

## The HBoxContainer for ParameterControllers
@export var controler_container: HBoxContainer

## Zone select button
@export var zone_select: OptionButton

## Random Mode button
@export var random_mode: OptionButton

## The Template placeholder item
@export var template_placeholder: PanelContainer

## The OptionButton for selecting the current page
@export var page_select_option: OptionButton

## The button to go to the previous page
@export var prev_page_button: Button 

## The button to go to the next page
@export var next_page_button: Button


## RefMap for Programmer.Category: Button
var _tab_buttons: RefMap = RefMap.new()

## RefMap for Programmer.Layer: Button
var _layer_buttons: RefMap = RefMap.new()

## The ButtonGroup for all tab buttons
var _tab_button_group: ButtonGroup = ButtonGroup.new()

## The ButtonGroup for all layer buttons
var _layer_button_group: ButtonGroup = ButtonGroup.new()

## Contains all placeholder items
var _placeholder_items: Array[Control]

## Contains all ParameterControllers
var _controlers: Array[ParameterController]

## Stores all pages by category { Category: { "zone": { index: { entry... } } }
var _pages: Dictionary[Programmer.Category, Dictionary]

## Stores all parameters that are currenty being shown by page by zone
var _shown_parameters: Dictionary[Programmer.Category, Dictionary]

## State for all category overrides colors
var _category_overrides: Dictionary[Programmer.Category, bool]

## Number of controlers per page
var _controlers_per_page: int = default_controlers_per_page

## The current category
var _current_category: Programmer.Category = Programmer.Category.DIMMER

## The current zone
var _current_zone: String = Fixture.RootZone

## Current page number
var _current_page: int = 0

## The current programmer layer
var _current_layer: Programmer.Layer = Programmer.Layer.VALUE

## The OptionButton index of each zone
var _zone_indexes: Dictionary[String, int] = {}

## All zones that have override values in them
var _zones_with_overrides: Dictionary[String, Variant]

## Stores all fixture overrides: { "zone": { Programmer.Category: { "parameter": null } } }
var _overrides_by_parameter: Dictionary[String, Dictionary]

## All the currently selected fixtures
var _fixtures: Array


## init
func _init() -> void:
	super._init()
	_set_class_name("UIProgrammer")
	
	settings_manager.register_setting("ControlersPerPage", Data.Type.INT, set_controlers_per_page, get_controlers_per_page, [controlers_per_page_changed]).set_min_max(1, 10)


## ready
func _ready() -> void:
	Values.connect_to_selection_value("selected_fixtures", _on_selected_fixtures_changed)
	Programmer.cleared.connect(_clear_overrides)
	
	template_placeholder.get_parent().remove_child(template_placeholder)
	
	_create_controlers_and_placeholders()
	_create_tab_buttons()
	_create_layer_buttons()


## Sets the category to display
func set_category(p_category: Programmer.Category) -> void:
	_current_category = p_category
	set_page(_current_page)


## Sets the page number
func set_page(p_page: int) -> void:
	_current_page = abs(clamp(p_page, 0, get_page_count() - 1))
	page_select_option.select(_current_page)
	_update_page()


## Sets the selected zone
func set_zone(p_zone: String) -> void:
	_current_zone = p_zone
	_update_page()
	_update_zone_override()


## Sets the layer
func set_layer(p_layer: Programmer.Layer) -> void:
	_current_layer = p_layer


## Sets the number of controlers per page
func set_controlers_per_page(p_per_page: int) -> void:
	if p_per_page == _controlers_per_page or p_per_page < 1:
		return
	
	_controlers_per_page = p_per_page
	_create_controlers_and_placeholders()
	_update_page()


## Gets the number of controlers per page
func get_controlers_per_page() -> int:
	return _controlers_per_page


## Gets the total number of pages
func get_page_count() -> int:
	var items: int = _pages.get(_current_category, {}).get(_current_zone, []).size()
	return int(ceil(float(items) / float(_controlers_per_page)))


## Seralizes this UIProgrammer
func serialize() -> Dictionary:
	return super.serialize().merged({
		"controlers_per_page": get_controlers_per_page()
	})


## Deserializes this UIProgrammer
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	set_controlers_per_page(type_convert(p_serialized_data.get("controlers_per_page", _controlers_per_page), TYPE_INT))


## Creates the default set of placeholders and controlers
func _create_controlers_and_placeholders() -> void:
	for placeholder: PanelContainer in _placeholder_items:
		placeholder.queue_free()
	
	for controler: ParameterController in _controlers:
		controler.queue_free()
	
	_placeholder_items.clear()
	_controlers.clear()
	
	for index: int in range(0, _controlers_per_page):
		var placeholder: PanelContainer = template_placeholder.duplicate()
		placeholder.get_child(0).set_text(str(index + 1))
		
		var controler: ParameterController = preload("res://panels/UIProgrammer/ParameterController/ParameterController.tscn").instantiate()
		controler.hide()
		
		controler_container.add_child(placeholder)
		controler_container.add_child(controler)
		
		controler.value_changed.connect(_on_controler_value_changed.bind(controler))
		controler.function_selected.connect(_on_controler_function_selected.bind(controler))
		controler.fixture_override_added.connect(_on_controler_fixture_override_added.bind(controler))
		controler.erase_pressed.connect(_on_controler_erase_pressed.bind(controler))
		
		_placeholder_items.append(placeholder)
		_controlers.append(controler)


## Creates the tab buttons
func _create_tab_buttons() -> void:
	for category: Programmer.Category in Programmer.Category.values():
		var tab_button: Button = Button.new()
		
		tab_button.set_toggle_mode(true)
		tab_button.set_disabled(true)
		tab_button.set_button_group(_tab_button_group)
		
		tab_button.set_text(Programmer.get_category_as_string(category).capitalize())
		tab_button.set_custom_minimum_size(Vector2(tab_button_min_size, 0))
		
		tab_button.pressed.connect(set_category.bind(category))
		
		_tab_buttons.map(category, tab_button)
		_category_overrides[category] = false
		
		tab_button_container.add_child(tab_button)
	
	_tab_buttons.left(Programmer.Category.DIMMER).set_pressed_no_signal(true)


## Creates the layer buttons
func _create_layer_buttons() -> void:
	for layer: Programmer.Layer in Programmer.Layer.values():
		var layer_button: Button = Button.new()
		
		layer_button.set_toggle_mode(true)
		layer_button.set_disabled(true)
		layer_button.set_button_group(_layer_button_group)
		
		layer_button.set_text(Programmer.Layer.keys()[layer].capitalize())
		layer_button.set_custom_minimum_size(Vector2(tab_button_min_size, 0))
		
		layer_button.pressed.connect(set_layer.bind(layer))
		_layer_buttons.map(layer, layer_button)
		
		layer_button_container.add_child(layer_button)
	
	_layer_buttons.left(Programmer.Layer.VALUE).set_pressed_no_signal(true)


## Updates the tabs of categorys displayed to the user
func _update_categorys(p_fixtures: Array) -> void:
	var zones: Dictionary = {Fixture.RootZone: null}
	var used_categories: Dictionary[int, Variant]
	
	_pages.clear()
	zone_select.clear()
	
	_zone_indexes.clear()
	_zones_with_overrides.clear()
	_shown_parameters.clear()
	
	_fixtures = p_fixtures
	_current_zone = Fixture.RootZone
	
	for fixture: Fixture in p_fixtures:
		for zone: String in fixture.get_zones():
			var categories: Dictionary = fixture.get_parameter_categories(zone)
			
			if not zones.has(zone):
				zones[zone] = null
			
			for parameter: String in categories.keys():
				var category: int = Programmer.get_category_from_string(categories[parameter])
				
				_display_parameter(fixture, zone, parameter, category)
				
				if fixture.has_override(zone, parameter):
					used_categories[category] = true
					_zones_with_overrides[zone] = true
					
					_overrides_by_parameter.get_or_add(zone, {}).get_or_add(category, {})[parameter] = null
	
	for category: Programmer.Category in _pages.keys():
		_set_category_override(category, used_categories.has(category))
	
	zone_select.add_item(Fixture.RootZone, 0)
	zone_select.set_item_icon(0, preload("res://assets/icons/Zone.svg"))
	_zone_indexes[Fixture.RootZone] = 0
	
	var sorted_zones: Array = Utils.sort_text_and_numbers(zones.keys())
	for index: int in range(0, sorted_zones.size()):
		var zone: String = sorted_zones[index]
		var idx: int = index + 1
		
		if _zone_indexes.has(zone):
			continue
		
		zone_select.add_item(zone, idx)
		zone_select.set_item_icon(idx, preload("res://assets/icons/Zone.svg"))
		
		zone_select.get_popup().set_item_icon_modulate(idx, ThemeManager.Colors.Statuses.ProgrammerOverride if _zones_with_overrides.has(zone) else Color.WHITE)
		_zone_indexes[zone] = idx
	
	_update_page()
	_update_buttons()
	_update_zone_override()


## Displays a parameter controler for the given fixture
func _display_parameter(p_fixture: Fixture, p_zone: String, p_parameter: String, p_category: Programmer.Category) -> void:
	if _shown_parameters.get(p_category, {}).get(p_zone, {}).has(p_parameter):
		return
	
	var page: Dictionary = _pages.get_or_add(p_category, {}).get_or_add(p_zone, {})
	var index: int = Programmer.get_parameter_index(p_category, p_parameter)
	
	if index == -1:
		index = _get_next_index(page)
	
	elif page.has(index):
		page[_get_next_index(page)] = page[index]
		page.erase(index)
	
	page[index] = {
		"fixture": p_fixture,
		"parameter": p_parameter,
	}
	
	_shown_parameters.get_or_add(p_category, {}).get_or_add(p_zone, {})[p_parameter] = null


## Gets the next empty index starting from 0
func _get_next_index(p_dict: Dictionary) -> int:
	var end_index: int = 0
	
	while p_dict.has(end_index):
		end_index += 1
	
	return end_index


## Updates what ParameterControlers are shown on the current page
func _update_page() -> void:
	_update_page_buttons()
	
	for index: int in range(0, _controlers_per_page):
		var entrys_to_show: Dictionary = _pages.get(_current_category, {}).get(_current_zone, {})
		var sorted_order: Array = entrys_to_show.keys()
		var page_offset: int = _controlers_per_page * _current_page
		
		sorted_order.sort()
		
		if (sorted_order.size() - page_offset) > index:
			_placeholder_items[index].hide()
			_controlers[index].show()
			
			var entry: Dictionary = entrys_to_show[sorted_order[index + page_offset]]
			_update_controler(_controlers[index], entry.fixture, _current_zone, entry.parameter)
		
		else:
			_controlers[index].hide()
			_placeholder_items[index].show()
			
			_controlers[index].remove_subscription()


## Updated a ParameterControler with the given fixture, zone, and parameter
func _update_controler(p_controler: ParameterController, p_fixture: Fixture, p_zone: String, p_parameter: String) -> void:
	var old_value: float = p_controler.get_value()
	p_controler.clear()
	
	for function: String in p_fixture.get_parameter_functions(p_zone, p_parameter):
		p_controler.add_function(function)
	
	p_controler.set_zone(p_zone)
	p_controler.set_parameter(p_parameter)
	p_controler.set_function(p_fixture.get_current_function(p_zone, p_parameter))
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_method(p_controler.set_value, old_value, p_fixture.get_current_value(p_zone, p_parameter), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	
	p_controler.set_override_bg(p_fixture.has_override(p_zone, p_parameter))
	p_controler.subscribe(p_fixture)


## Updates tab buttons to enable ones with parameters
func _update_buttons() -> void:
	for category: Programmer.Category in _tab_buttons.get_left():
		_tab_buttons.left(category).set_disabled(not _pages.has(category))
	
	var has_fixtures: bool = bool(_fixtures.size())
	
	zone_select.set_disabled(not has_fixtures)
	page_select_option.set_disabled(not has_fixtures)
	random_mode.set_disabled(not has_fixtures)
	
	set_button_array_enabled(_layer_buttons.get_right(), not has_fixtures)
	
	if not has_fixtures:
		next_page_button.set_disabled(true)
		prev_page_button.set_disabled(true)


## Updates the page buttons
func _update_page_buttons() -> void:
	prev_page_button.set_disabled(_current_page == 0)
	next_page_button.set_disabled(_current_page + 1 == get_page_count())
	
	if get_page_count() == page_select_option.get_item_count():
		return
	
	page_select_option.clear()
	
	for index in range(0, get_page_count()):
		page_select_option.add_item(str(index))
	
	page_select_option.select(_current_page)


## Updates the override hilight on the zone select button
func _update_zone_override() -> void:
	_set_button_override(zone_select, _zones_with_overrides.has(_current_zone))


## Enabled or disabled override on a Category
func _set_category_override(p_category: Programmer.Category, p_override: bool) -> void:
	if _category_overrides[p_category] == p_override:
		return
	
	_set_button_override(_tab_buttons.left(p_category), p_override)
	_category_overrides[p_category] = p_override


## Enables or disables override on a zone
func _set_zone_override(p_zone: String, p_override: bool) -> void:
	if not _zone_indexes.has(p_zone) or _zones_with_overrides.get(p_zone) == p_override:
		return
	
	zone_select.get_popup().set_item_icon_modulate(_zone_indexes[p_zone], ThemeManager.Colors.Statuses.ProgrammerOverride if p_override else Color.WHITE)
	_zones_with_overrides[p_zone] = p_override
	
	if p_zone == _current_zone:
		_set_button_override(zone_select, p_override)


## Sets the override color on a BaseButton
func _set_button_override(p_button: BaseButton, p_override: bool) -> void:
	p_button.begin_bulk_theme_override()
	
	if p_override:
		p_button.add_theme_color_override("font_color", ThemeManager.Colors.Statuses.ProgrammerOverride)
		p_button.add_theme_color_override("font_focus_color", ThemeManager.Colors.Statuses.ProgrammerOverride)
		p_button.add_theme_color_override("font_pressed_color", ThemeManager.Colors.Statuses.ProgrammerOverride)
		p_button.add_theme_color_override("font_hover_color", ThemeManager.Colors.Statuses.ProgrammerOverride)
		p_button.add_theme_color_override("font_hover_pressed_color", ThemeManager.Colors.Statuses.ProgrammerOverride)
	else:
		p_button.remove_theme_color_override("font_color")
		p_button.remove_theme_color_override("font_focus_color")
		p_button.remove_theme_color_override("font_pressed_color")
		p_button.remove_theme_color_override("font_hover_color")
		p_button.remove_theme_color_override("font_hover_pressed_color")
	
	p_button.end_bulk_theme_override()


## Handles setting overrides when a controler value is changed
func _handle_controler_override(p_controler: ParameterController) -> void:
	var parameter: String = p_controler.get_parameter()
	
	if _overrides_by_parameter.get(_current_zone, {}).get(_current_category, {}).has(parameter):
		return
	
	_overrides_by_parameter.get_or_add(_current_zone, {}).get_or_add(_current_category, {})[parameter] = null
	
	_set_category_override(_current_category, true)
	_set_zone_override(_current_zone, true)
	
	p_controler.set_override_bg(true)


## Handles removing overrides when a controler's erase button is pressed
func _handle_controler_erase(p_controler: ParameterController) -> void:
	var parameter: String = p_controler.get_parameter()
	
	if not _overrides_by_parameter.get(_current_zone, {}).get(_current_category, {}).has(parameter):
		return
	
	_overrides_by_parameter[_current_zone][_current_category].erase(parameter)
	
	if not _overrides_by_parameter[_current_zone][_current_category]:
		_set_category_override(_current_category, false)
		_overrides_by_parameter[_current_zone].erase(_current_category)
		
		if not _overrides_by_parameter[_current_zone]:
			_set_zone_override(_current_zone, false)
			_overrides_by_parameter.erase(_current_zone)
	
	p_controler.set_override_bg(false)


## Clears all override colors
func _clear_overrides() -> void:
	for controler: ParameterController in _controlers:
		controler.set_override_bg(false)
		controler.set_value_fixture()
	
	for category: Programmer.Category in _category_overrides:
		_set_category_override(category, false)
	
	for zone: String in _zones_with_overrides:
		_set_zone_override(zone, false)
	
	_zones_with_overrides.clear()
	_overrides_by_parameter.clear()


## Called when the fixture selection changes
func _on_selected_fixtures_changed(fixtures: Array) -> void:
	if visible and fixtures != _fixtures:
		_update_categorys(fixtures)


## Called when the page back button is pressed
func _on_page_back_pressed() -> void:
	set_page(_current_page - 1)


## Called when the page fowards button is pressed
func _on_page_fowards_pressed() -> void:
	set_page(_current_page + 1)


## Called when a zone is selected
func _on_zone_select_item_selected(index: int) -> void:
	set_zone(zone_select.get_item_text(index))


## Called when the store button is pressed
func _on_store_pressed() -> void:
	Interface.prompt_object_picker(self, EngineComponent, Function).then(func (p_function: Function):
		Programmer.store_into(p_function)
	)


## Called when the clear button is pressed
func _on_clear_pressed() -> void:
	Programmer.clear()
	_clear_overrides()


## Called when the value on a ParameterControler is changed
func _on_controler_value_changed(p_value: float, p_controler: ParameterController) -> void:
	_handle_controler_override(p_controler)
	
	match _current_layer:
		Programmer.Layer.VALUE:
			Programmer.set_parameter(_fixtures, p_controler.get_parameter(), p_controler.get_function(), p_value, p_controler.get_zone())


## Emitted when the function on the ParameterControler is changed
func _on_controler_function_selected(p_function: String, p_controler: ParameterController) -> void:
	_handle_controler_override(p_controler)
	var value: float = p_controler.get_refernce_fixture().get_default(_current_zone, p_controler.get_parameter(), p_function)
	Programmer.set_parameter(_fixtures, p_controler.get_parameter(), p_function, value, _current_zone)


## Called when an override is added to a ParameterControlers refernce fixture
func _on_controler_fixture_override_added(p_controler: ParameterController) -> void:
	_handle_controler_override(p_controler)


## Called when the erase button is pressed on a ParameterController
func _on_controler_erase_pressed(p_controler: ParameterController) -> void:
	Programmer.erase_parameter(_fixtures, p_controler.get_parameter(), p_controler.get_zone())
	_handle_controler_erase(p_controler)
