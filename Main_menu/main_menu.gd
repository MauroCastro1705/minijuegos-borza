extends Control

@export var fade_duration: float = 0.5
@onready var juegos: VBoxContainer = $juegos
@onready var titulo: Label = $titulo
@onready var start_button: Button = $Button
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	juegos.hide()
	canvas_layer.show()
	
func _on_button_pressed() -> void:
	start_button.hide()
	titulo.hide()
	juegos.show()
