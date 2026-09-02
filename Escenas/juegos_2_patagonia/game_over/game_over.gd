extends Node2D
@onready var comida: Label = $comida
@onready var puntaje: Label = $puntaje

func _ready() -> void:
	comida.text = "Comida: " + str(Global.comida)
	puntaje.text = "Puntaje: " + str(Global.score_pinguino)


func _on_button_pressed() -> void:
	TransitionManager.change_scene("res://Escenas/juegos_2_patagonia/tutorial/tutorial.tscn")
