# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIClock extends UIPanel
## A clock


## Emitted when the show year state is changed
signal show_year_changed(show_year: bool)

## Emitted when the show month state is changed
signal show_month_changed(show_month: bool)

## Emitted when the show day state is changed
signal show_day_changed(show_day: bool)

## Emitted when the show hour state is changed
signal show_hour_changed(show_hour: bool)

## Emitted when the show minute state is changed
signal show_minute_changed(show_minute: bool)

## Emitted when the show second state is changed
signal show_second_changed(show_second: bool)

## Emitted when the show millisecond state is changed
signal show_millisecond_changed(show_millisecond: bool)

## Emitted when the use twelve hour state is changed
signal use_twelve_hour_changed(use_twelve_hour: bool)

## Emitted when the font scale multiplier is changed
signal font_scale_multiplier_changed(font_scale_multiplier: float)

## Emitted when the font color is changed
signal font_color_changed(font_color: Color)


## Contains english names for all months
const Months: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

## Contains english names for all week days
const WeekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]


## The Label to show the time
@export var label: Label


## Shows the year
var _show_year: bool = false

## Shows the month
var _show_month: bool = false

## Shows the day
var _show_day: bool = false

## Shows the hour
var _show_hour: bool = true

## Shows the minute
var _show_minute: bool = true

## Shows the second
var _show_second: bool = true

## Shows the millisecond
var _show_millisecond: bool = false

## Displays the hour in AM/PM time
var _use_twelve_hour: bool = false

## The font scale multiplier
var _font_scale_multiplier: float = 0.9

## Font color
var _font_color: Color = Color.WHITE


## init
func _init() -> void:
	super._init()
	
	_set_class_name("UIClock")
	
	settings_manager.register_setting("ShowYear", Data.Type.BOOL, set_show_year, get_show_year, [show_year_changed])
	settings_manager.register_setting("ShowMonth", Data.Type.BOOL, set_show_month, get_show_month, [show_month_changed])
	settings_manager.register_setting("ShowDay", Data.Type.BOOL, set_show_day, get_show_day, [show_day_changed])
	settings_manager.register_setting("ShowHour", Data.Type.BOOL, set_show_hour, get_show_hour, [show_hour_changed])
	settings_manager.register_setting("ShowMinute", Data.Type.BOOL, set_show_minute, get_show_minute, [show_minute_changed])
	settings_manager.register_setting("ShowSecond", Data.Type.BOOL, set_show_second, get_show_second, [show_second_changed])
	settings_manager.register_setting("ShowMillisecond", Data.Type.BOOL, set_show_millisecond, get_show_millisecond, [show_millisecond_changed])
	
	settings_manager.register_setting("UseTwelveHour", Data.Type.BOOL, set_use_twelve_hour, get_use_twelve_hour, [use_twelve_hour_changed])
	settings_manager.register_setting("FontScaleMultiplier", Data.Type.FLOAT, set_font_scale_multiplier, get_font_scale_multiplier, [font_scale_multiplier_changed]).set_min_max(0.1, 5.0)
	settings_manager.register_setting("FontColor", Data.Type.COLOR, set_font_color, get_font_color, [font_color_changed])

## ready
func _ready() -> void:
	label.label_settings = label.label_settings.duplicate()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	_update_font_size()


## process
func _process(delta: float) -> void:
	var date_time: Dictionary = Time.get_datetime_dict_from_system()
	var result: PackedStringArray = []
	
	if _show_year:
		result.append(str(date_time.year))
	
	if _show_month:
		result.append(Months[date_time.month])
	
	if _show_day:
		result.append(WeekDays[date_time.weekday])
	
	if _show_hour:
		result.append(Utils.format_12_hour(date_time.hour) if _use_twelve_hour else ("%02d" % date_time.hour))
	
	if _show_minute:
		result.append("%02d" % date_time.minute)
	
	if _show_second:
		result.append("%02d" % date_time.second)
	
	if _show_millisecond:
		var now_sec: float = Time.get_unix_time_from_system()
		var ms_in_second: int = int((now_sec - floor(now_sec)) * 1000)
		result.append("%03d" % ms_in_second)
	
	label.set_text(":".join(result))


## Sets the show year state
func set_show_year(p_show_year: bool, p_no_signal: bool = false) -> void:
	_show_year = p_show_year
	queue(_update_font_size)
	
	if not p_no_signal:
		show_year_changed.emit(_show_year)


## Sets the show month state
func set_show_month(p_show_month: bool, p_no_signal: bool = false) -> void:
	_show_month = p_show_month
	queue(_update_font_size)
	
	if not p_no_signal:
		show_month_changed.emit(_show_month)


## Sets the show day state
func set_show_day(p_show_day: bool, p_no_signal: bool = false) -> void:
	_show_day = p_show_day
	queue(_update_font_size)
	
	if not p_no_signal:
		show_day_changed.emit(_show_day)


## Sets the show hour state
func set_show_hour(p_show_hour: bool, p_no_signal: bool = false) -> void:
	_show_hour = p_show_hour
	queue(_update_font_size)
	
	if not p_no_signal:
		show_hour_changed.emit(_show_hour)


## Sets the show minute state
func set_show_minute(p_show_minute: bool, p_no_signal: bool = false) -> void:
	_show_minute = p_show_minute
	queue(_update_font_size)
	
	if not p_no_signal:
		show_minute_changed.emit(_show_minute)


## Sets the show second state
func set_show_second(p_show_second: bool, p_no_signal: bool = false) -> void:
	_show_second = p_show_second
	queue(_update_font_size)
	
	if not p_no_signal:
		show_second_changed.emit(_show_second)


## Sets the show millisecond state
func set_show_millisecond(p_show_millisecond: bool, p_no_signal: bool = false) -> void:
	_show_millisecond = p_show_millisecond
	queue(_update_font_size)
	
	if not p_no_signal:
		show_millisecond_changed.emit(_show_millisecond)


## Sets the use twelve hour state
func set_use_twelve_hour(p_use_twelve_hour: bool, p_no_signal: bool = false) -> void:
	_use_twelve_hour = p_use_twelve_hour
	queue(_update_font_size)
	
	if not p_no_signal:
		use_twelve_hour_changed.emit(_use_twelve_hour)


## Sets the font scale multiplier
func set_font_scale_multiplier(p_font_scale_multiplier: float, p_no_signal: bool = false) -> void:
	_font_scale_multiplier = p_font_scale_multiplier
	queue(_update_font_size)
	
	if not p_no_signal:
		font_scale_multiplier_changed.emit(_font_scale_multiplier)


## Sets the font color
func set_font_color(p_font_color: Color, p_no_signal: bool = false) -> void:
	_font_color = p_font_color
	label.get_label_settings().set_font_color(_font_color)
	
	if not p_no_signal:
		font_color_changed.emit(_font_color)


## Gets the show year state
func get_show_year() -> bool:
	return _show_year


## Gets the show month state
func get_show_month() -> bool:
	return _show_month


## Gets the show day state
func get_show_day() -> bool:
	return _show_day


## Gets the show hour state
func get_show_hour() -> bool:
	return _show_hour


## Gets the show minute state
func get_show_minute() -> bool:
	return _show_minute


## Gets the show second state
func get_show_second() -> bool:
	return _show_second


## Gets the show millisecond state
func get_show_millisecond() -> bool:
	return _show_millisecond


## Gets the use twelve hour state
func get_use_twelve_hour() -> bool:
	return _use_twelve_hour


## Gets the font scale multiplier
func get_font_scale_multiplier() -> float:
	return _font_scale_multiplier


## Gets the font color
func get_font_color() -> Color:
	return _font_color


## Serializes this UIClock
func serialize() -> Dictionary:
	return super.serialize().merged({
		"show_year": _show_year,
		"show_month": _show_month,
		"show_day": _show_day,
		"show_hour": _show_hour,
		"show_minute": _show_minute,
		"show_second": _show_second,
		"show_millisecond": _show_millisecond,
		"font_scale_multiplier": _font_scale_multiplier,
		"font_color": var_to_str(_font_color),
	})


## Deserialize this UIClock
func deserialize(p_serialized_data: Dictionary) -> void:
	super.deserialize(p_serialized_data)
	print("deser")
	set_show_year(type_convert(p_serialized_data.get("show_year", _show_year), TYPE_BOOL), true)
	set_show_month(type_convert(p_serialized_data.get("show_month", _show_month), TYPE_BOOL), true)
	set_show_day(type_convert(p_serialized_data.get("show_day", _show_day), TYPE_BOOL), true)
	set_show_hour(type_convert(p_serialized_data.get("show_hour", _show_hour), TYPE_BOOL), true)
	set_show_minute(type_convert(p_serialized_data.get("show_minute", _show_minute), TYPE_BOOL), true)
	set_show_second(type_convert(p_serialized_data.get("show_second", _show_second), TYPE_BOOL), true)
	set_show_millisecond(type_convert(p_serialized_data.get("show_millisecond", _show_millisecond), TYPE_BOOL), true)
	
	set_font_scale_multiplier(type_convert(p_serialized_data.get("font_scale_multiplier", _font_scale_multiplier), TYPE_FLOAT), true)
	set_font_color(type_convert(str_to_var(type_convert(p_serialized_data.get("font_color", _font_color), TYPE_STRING)), TYPE_COLOR), true)


## Sets font size
func _update_font_size() -> void:
	label.label_settings.font_size += 32
	var text_width: int = label.label_settings.font.get_string_size(label.text, label.horizontal_alignment, -1, label.label_settings.font_size).x
	
	if text_width > size.x and text_width > 0:
		var scale_factor: float = size.x / text_width * _font_scale_multiplier
		label.label_settings.set_font_size(int(label.label_settings.font_size * scale_factor))
