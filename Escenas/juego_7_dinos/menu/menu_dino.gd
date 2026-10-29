extends Node2D
#menu indio juego 5

@onready var musica: AudioStreamPlayer2D = $musica
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	musica.play()
	canvas_layer.show()

func _on_play_pressed() -> void:
	TransitionManager.change_scene("res://Escenas/juego_7_dinos/main/main_scene.tscn")





func _on_volver_pressed() -> void:
	TransitionManager.change_to_menu()


func _on_musica_finished() -> void:
	musica.play()
