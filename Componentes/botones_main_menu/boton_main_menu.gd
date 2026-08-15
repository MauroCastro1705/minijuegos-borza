extends Control
@onready var theme_name: Label = $MarginContainer/VBoxContainer/name
@onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var button: Button = $MarginContainer/VBoxContainer/Button
@onready var chains: TextureRect = $chains

@export var scene_path:String = "" ##sin comillas el path
@export var game_name:String = ""
@export var game_img:Texture2D
@export var disable_buton:bool = true ##desabilita el boton

func _ready() -> void:
	theme_name.text = game_name
	texture_rect.texture = game_img
	if disable_buton:
		button.disabled = true
		chains.show()
	else:
		chains.hide()

func _on_button_pressed() -> void:
	TransitionManager.change_scene(scene_path)
