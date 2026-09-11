extends Control

@onready var game_texture: TextureRect = %TextureRect

@onready var chains: TextureRect = $chains
@onready var theme_name: Label = %name
@onready var button: Button = %Button

@export var scene_path:String = "" ##sin comillas el path
@export var game_name:String = ""
@export var game_img:Texture2D
@export var disable_buton:bool = true ##desabilita el boton

func _ready() -> void:
	theme_name.text = game_name
	game_texture.texture = game_img
	if disable_buton:
		button.disabled = true
		chains.show()
	else:
		chains.hide()

func _on_button_pressed() -> void:
	TransitionManager.change_scene(scene_path)
