extends Control

@export var fade_duration: float = 0.5
@onready var juegos: VBoxContainer = $juegos
@onready var titulo: Label = $titulo
@onready var start_button: Button = $Button

func _ready() -> void:
	juegos.hide()

func _on_button_pressed() -> void:
	start_button.hide()
	titulo.hide()
	juegos.show()
