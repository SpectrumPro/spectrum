static var config: Dictionary[String, Variant] = {
	"scale_factor": 1,
	"save_ui_on_quit": true,
	"default_ui_panel": UICore,
	"window_popup_config": {
		UIMainMenu:				CoreInterface.PopupConfig.new("UIMainMenu", ""),
		UIManifestSelector:		CoreInterface.PopupConfig.new("UIManifestSelector"),
		UIComponentSettings:	CoreInterface.PopupConfig.new("UIComponentSettings", "set_component"),
		UIParameterList:		CoreInterface.PopupConfig.new("UIParameterList", "set_fixtures"),
		UISaveLoad:				CoreInterface.PopupConfig.new("UISaveLoad", ""),
		UISettings:				CoreInterface.PopupConfig.new("UISettings", ""),
	},
	"startup_notices": [
		StartUpNotice.new()
		.set_title("Beta Software Notice!")
		.set_title_icon("res://assets/logos/spectrum/dark_scaled/spectrum_dark-64x64.png")
		.set_version(Details.version)
		.set_bbcode_body(
			"""[ul]
			Spectrum is currently in [b]active development[/b] and is considered [b]beta software[/b].
			Features may change, bugs may exist, and stability is [b]not yet guaranteed[/b].
			It is [b]not recommended for mission-critical or production use[/b] at this stage.
			[/ul]"""
		.replace("\t", ""))
		.set_confirm_button_text("Acknowledge")
		.set_link_text("Github Issues")
		.set_link_url("https://github.com/SpectrumPro/Spectrum/issues")
		.set_notice_id("BETANOTICEV1.0.0-beta.3")
	]
}
