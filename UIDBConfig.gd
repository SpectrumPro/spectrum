## File path for all UIPanels
const UI_PANEL_LOCATION: String = "res://panels/"

## File path for all UIPanels
const UI_POPUP_LOCATION: String = "res://panels/popups/"

## File path for all UIComponents
const UI_COMPONENT_LOCATION: String = "res://components/"

## File path for all UIPanels
const DATA_INPUT_LOCATION: String = "res://components/DataInputs/"

## File path for all UIPanels
const ICON_LOCATION: String = "res://assets/icons/"


## All user defined UIPanels
static var panels: Dictionary[String, PackedScene] = {
	"UIDesk":				load(_p("UIDesk")),
	"UIFunctions":			load(_p("UIFunctions")),
	"UIPlaybacks":			load(_p("UIPlaybacks")),
	"UIUniverses":			load(_p("UIUniverses")),
	"UIFixtures":			load(_p("UIFixtures")),
	"UIFixtureGroups":		load(_p("UIFixtureGroups")),
	"UISettings":			load(_p("UISettings")),
	"UISaveLoad":			load(_p("UISaveLoad")),
	"UICore":				load(_p("UICore")),
	"UIDebug":				load(_p("UIDebug")),
	"UIVirtualFixtures":	load(_p("UIVirtualFixtures")),
	"UIProgrammer":			load(_p("UIProgrammer")),
	"UIColorPicker":		load(_p("UIColorPicker")),
	"UIClock":				load(_p("UIClock")),
	"UICuePlayback":		load(_p("UICuePlayback")),
	"UIColorBlock":			load(_p("UIColorBlock")),
	"UICueSheet":			load(_p("UICueSheet")),
	"UIDataEditor":			load(_p("UIDataEditor")),
}

## All user defined UIPanels
static var popups: Dictionary[String, PackedScene]

## All user defined UIPanels
static var components: Dictionary[String, PackedScene]

## All user defined UIPanels
static var data_inputs: Dictionary[Data.Type, Variant] = {
	Data.Type.OBJECT:			{
		Data.Sub.Type.OBJECT_ENGINECOMPONENT: 	load(_d("DataInputEngineComponent")),
		Data.Sub.Type.OBJECT_FIXTUREMANIFEST: 	load(_d("DataInputFixtureManifest")),
		Data.Sub.Type.OBJECT_NETWORKITEM: 		load(_d("DataInputNetworkItem")),
	}
}

## All user defined UIPanels
static var class_icons: Dictionary[String, Texture2D] = {
	"NetworkManager": 		load(_i("Network")),
	"Network": 				load(_i("Network")),
	"Constellation": 		load(_i("Graph3")),
	"Universe":				load(_i("Universe")),
	"Fixture":				load(_i("Fixture")),
	"DMXFixture":			load(_i("DMXFixture")),
	"Function":				load(_i("Function")),
	"CueList":				load(_i("CueList")),
	"Scene":				load(_i("Scene")),
	"FunctionGroup":		load(_i("FunctionGroup")),
	"DMXOutput":			load(_i("DMXOutput")),
	"ArtNetOutput":			load(_i("ArtNet")),
	"FixtureGroup":			load(_i("FixtureGroup")),
	"TriggerBlock":			load(_i("TriggerBlock")),
}

## Categorys of the user defined panels
static var panels_by_category: Dictionary[String, Array] = {
	"System": [
		"UISettings",
		"UISaveLoad",
		"UICore",
		"UIComponentSettings",
	],
	"Playbacks": [
		"UIPlaybacks",
		"UICuePlayback",
	],
	"Programming": [
		"UIProgrammer",
		"UIColorPicker",
		"UICueSheet",
		"UIDataEditor",
	],
	"Components": [
		"UIUniverses",
		"UIFunctions",
		"UIFixtures",
		"UIFixtureGroups"
	],
	"Views": [
		"UIVirtualFixtures",
		"UIDesk",
	],
	"Utils": [
		"UIClock",
		"UIDebug",
		"UIColorBlock",
	]
}

## Config
static var config: Dictionary[String, Variant] = {
	"panels": panels,
	"popups": popups,
	"components": components,
	"data_inputs": data_inputs,
	"class_icons": class_icons,
	"panels_by_category": panels_by_category
}


## Returns the file path of a UIPanel
static func _p(p_panel_class: String) -> String:
	return str(UI_PANEL_LOCATION, p_panel_class, "/", p_panel_class, ".tscn")


## Returns the file path of a UIPopup
static func _u(p_popup_class: String) -> String:
	return str(UI_POPUP_LOCATION, p_popup_class, "/", p_popup_class, ".tscn")


## Returns the file path of a UIComponent
static func _c(p_component_class: String) -> String:
	return str(UI_COMPONENT_LOCATION, p_component_class, "/", p_component_class, ".tscn")


## Returns the file path of a DataInput
static func _d(p_data_input_class: String) -> String:
	return str(DATA_INPUT_LOCATION, p_data_input_class, "/", p_data_input_class, ".tscn")


## Returns the file path of a Icon
static func _i(p_data_input_class: String) -> String:
	return str(ICON_LOCATION, p_data_input_class, ".svg")
