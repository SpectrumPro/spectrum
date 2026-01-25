class_name UIColorBlock extends UIPanel
## A Color Block


## Emitted when the color is changed
signal color_changed(color: Color)

## Emitted when the border color is changed
signal border_color_changed(border_color: Color)

## Emitted when the border width is changed
signal border_width_changed(border_width: int)

## Emitted when the corner radius is changed
signal corner_radius_changed(corner_radius: int)

## Emitted when the show panel border state is changed
signal show_panel_border_changed(show_panel_border: bool)


## The ColorRect to show the color
@export var panel: Panel


## The StyleBoxFlat for the panel
var _style_box: StyleBoxFlat

## The current color
var _color: Color = Color.WHITE

## Border color
var _border_color: Color = Color.BLACK

## Border width
var _border_width: int = 1

## Corner radius of the panel
var _corner_radius: int = 2

## True of the UIPanel border should be shown
var _show_panel_border: bool = true


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIColorBlock")
	
	settings_manager.register_setting("Color", Data.Type.COLOR, set_color, get_color, [color_changed])
	settings_manager.register_setting("BorderColor", Data.Type.COLOR, set_border_color, get_border_color, [border_color_changed])
	settings_manager.register_setting("BorderWidth", Data.Type.INT, set_border_width, get_border_width, [border_width_changed]).set_min_max(0, INF)
	settings_manager.register_setting("CornerRadius", Data.Type.INT, set_corner_radius, get_corner_radius, [corner_radius_changed]).set_min_max(0, INF)
	settings_manager.register_setting("ShowPanelBorder", Data.Type.BOOL, set_show_panel_border, get_show_panel_border, [show_panel_border_changed])


## ready
func _ready() -> void:
	_style_box = panel.get_theme_stylebox("panel").duplicate()
	panel.add_theme_stylebox_override("panel", _style_box)


## Sets the BG color
func set_color(p_color: Color, p_no_signal: bool = false) -> void:
	_color = p_color
	_style_box.set_bg_color(_color)
	
	if not p_no_signal:
		color_changed.emit(_color)


## Sets the border color
func set_border_color(p_border_color: Color, p_no_signal: bool = false) -> void:
	_border_color = p_border_color
	_style_box.set_border_color(_border_color)

	if not p_no_signal:
		border_color_changed.emit(_border_color)


## Sets the border width
func set_border_width(p_border_width: int, p_no_signal: bool = false) -> void:
	_border_width = p_border_width
	_style_box.set_border_width_all(_border_width)

	if not p_no_signal:
		border_width_changed.emit(_border_width)


## Sets the corner radius
func set_corner_radius(p_corner_radius: int, p_no_signal: bool = false) -> void:
	_corner_radius = p_corner_radius
	_style_box.set_corner_radius_all(_corner_radius)
	
	if not p_no_signal:
		corner_radius_changed.emit(_corner_radius)


## Sets the show panel border state
func set_show_panel_border(p_show_panel_border: bool, p_no_signal: bool = false) -> void:
	_show_panel_border = p_show_panel_border
	add_theme_stylebox_override("panel", ThemeManager.StyleBoxes.UIPanelBase if _show_panel_border else StyleBoxEmpty.new())
	
	if not p_no_signal:
		show_panel_border_changed.emit(_show_panel_border)


## Returns the current color
func get_color() -> Color:
	return _color


## Returns the border color
func get_border_color() -> Color:
	return _border_color


## Returns the border width
func get_border_width() -> int:
	return _border_width


## Returns the corner radius
func get_corner_radius() -> int:
	return _corner_radius


## Returns the show panel border state
func get_show_panel_border() -> bool:
	return _show_panel_border


## Saves the current settings of this panel to a Dictionary
func serialize() -> Dictionary:
	return super.serialize().merged({
		"color": var_to_str(_color),
		"border_color": var_to_str(_border_color),
		"border_width": _border_width,
		"corner_radius": _corner_radius,
		"show_panel_border": _show_panel_border,
	})


## Loads the settings of this panel from a Dictionary
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	
	set_color(type_convert(str_to_var(type_convert(p_serialized_data.get("color", ""), TYPE_STRING)), TYPE_COLOR), true)
	set_border_color(type_convert(str_to_var(type_convert(p_serialized_data.get("border_color", ""), TYPE_STRING)), TYPE_COLOR), true)
	set_border_width(p_serialized_data.get("border_width", _border_width), true)
	set_corner_radius(p_serialized_data.get("corner_radius", _corner_radius), true)
	set_show_panel_border(type_convert(p_serialized_data.get("show_panel_border", _show_panel_border), TYPE_BOOL))
