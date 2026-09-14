extends Node2D
@onready var button: Button = $Button
@onready var mutante: CharacterBody2D = $Mutante
@onready var countdown_timer: CustomTimer = $CountdownTimer


func _on_button_pressed() -> void:
	mutante.iniciar_batalla()
