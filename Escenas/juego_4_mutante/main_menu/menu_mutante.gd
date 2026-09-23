extends Node2D

@onready var musica: AudioStreamPlayer2D = $musica

func _ready() -> void:
	musica.play()

func _on_play_pressed() -> void:
	TransitionManager.change_scene("res://Escenas/juego_4_mutante/main_4.tscn")


func _on_volver_pressed() -> void:
	TransitionManager.change_to_menu()


func _on_musica_finished() -> void:
	musica.play()
