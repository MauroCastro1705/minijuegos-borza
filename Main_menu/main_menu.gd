extends Control

@export var fade_duration: float = 0.5
@onready var juegos: VBoxContainer = $juegos
@onready var start_button: Button = $StartButton
@onready var titulo: Label = $titulo

func _ready() -> void:
	juegos.hide()

func _on_start_button_pressed():
	start_button.hide()
	titulo.hide()
	juegos.show()
	
