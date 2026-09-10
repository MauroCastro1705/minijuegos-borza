extends Node2D
@onready var tuto: Control = $tuto


func _on_button_pressed() -> void:
	TransitionManager.change_to_menu()


func _on_tutorial_button_pressed() -> void:
	tuto.hide()
