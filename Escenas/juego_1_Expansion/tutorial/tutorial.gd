extends Node2D

@onready var tutorial: Node2D = $tutorial
@onready var game_over: Node2D = $game_over
@onready var button: Button = $CanvasLayer/Button

func _ready() -> void:
	if Global.planeta_finished:
		tutorial.hide()
		game_over.show()
		button.text = "Volver al menu"
		
	else:
		tutorial.show()
		game_over.hide()
		button.text = "COMENZAR"

func _on_button_pressed() -> void:
	if Global.planeta_finished:
		TransitionManager.change_scene("res://Main_menu/MainMenu.tscn")
	else:
		TransitionManager.change_scene("res://Escenas/juego_1_Expansion/expansion.tscn")
