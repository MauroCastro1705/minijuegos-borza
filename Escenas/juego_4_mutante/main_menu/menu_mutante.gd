extends Node2D


func _on_play_pressed() -> void:
	TransitionManager.change_scene("res://Escenas/juego_4_mutante/main_4.tscn")


func _on_volver_pressed() -> void:
	TransitionManager.change_to_menu()
