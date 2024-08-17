extends Control


signal go_back()

var main_licenses := [
	["Godot Engine", Engine.get_license_text()],
	["VCR OSD Mono Font", "Free for both personal and commercial use"],
]

@onready var third_party_panel: PanelContainer = %ThirdPartyPanel
@onready var third_party_label: RichTextLabel = %ThirdPartyLabel
@onready var third_party_button: Button = %ThirdPartyButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	third_party_label.text = generate_license_bbcode_text()


func _on_back_button_pressed() -> void:
	go_back.emit()


func _on_third_party_button_pressed() -> void:
	if third_party_panel.visible:
		third_party_panel.hide()
		third_party_button.text = "Show" + third_party_button.text.substr(4)
	else:
		third_party_panel.show()
		third_party_button.text = "Hide" + third_party_button.text.substr(4)


func generate_license_bbcode_text() -> String:
	var text := "[center][font_size=36][b]Licenses[/b][/font_size][/center]"

	for license: Array in main_licenses:
		text += "\n\n[center][font_size=20][b]" + license[0] + "[/b][/font_size][/center]\n\n"
		text += "[font_size=13]" + license[1].strip_edges() + "[/font_size]"

	text += "\n\n[center][font_size=26][b]All Third-Party Licenses[/b][/font_size][/center]"

	# These engine license/copyright functions are not incredibly obvious how to usefully extract information from.
	# This is similar to how it's done in the "About Godot" -> "Third-party Licenses" -> "All Components" screen
	for info in Engine.get_copyright_info():
		text += "\n\n[center][font_size=18][b]" + info.name + "[/b][/font_size][/center]\n[font_size=14]"
		for part: Dictionary in info.parts:
			for copyright: String in part.copyright:
				text += "\n(c) " + copyright
			text += "\nLicense: " + part.license
		text += "[/font_size]"

	var engine_licenses := Engine.get_license_info()
	for license: String in engine_licenses:
		text += "\n\n[center][font_size=18][b]" + license + "[/b][/font_size][/center]\n\n"
		text += "[font_size=12]" + engine_licenses[license] + "[/font_size]"

	return text
