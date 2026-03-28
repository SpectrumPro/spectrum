## Internal actions
static var internal_actions: Dictionary[String, Callable] = {
	"clear_programmer": Programmer.clear,
	"ui_cancel": Interface.hide_all_popup_panels,
	"command_palette": Interface.toggle_popup_visable.bind(UICommandPalette, self),
	"screenshot": Interface.take_screenshot,
}

## Config
static var config: Dictionary[String, Variant] = {
	"internal_actions": internal_actions
}
