extends Node


@onready var main_menu: CenterContainer = $MainMenu
@onready var credits_menu: Control = $CreditsMenu


func _ready() -> void:
	(main_menu.get_node("%PlayButton") as Button).grab_focus()


func _on_main_menu_show_credits() -> void:
	main_menu.hide()
	credits_menu.show()
	(credits_menu.get_node("%BackButton") as Button).grab_focus()


func _on_credits_menu_go_back() -> void:
	credits_menu.hide()
	main_menu.show()
	(main_menu.get_node("%CreditsButton") as Button).grab_focus()
