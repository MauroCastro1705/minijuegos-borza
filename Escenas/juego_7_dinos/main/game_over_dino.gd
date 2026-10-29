extends Node2D


func _on_restart_pressed() -> void:
	TransitionManager.change_to_menu()
