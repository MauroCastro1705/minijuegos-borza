extends Node2D
@onready var socket_spe: StaticBody2D = $sockets_mutante/socket_spe
@onready var socket_spe_2: StaticBody2D = $sockets_mutante/socket_spe2
@onready var socket_spe_3: StaticBody2D = $sockets_mutante/socket_spe3
@onready var socket_spe_4: StaticBody2D = $sockets_mutante/socket_spe4
@onready var socket_spe_5: StaticBody2D = $sockets_mutante/socket_spe5
@onready var socket_spe_6: StaticBody2D = $sockets_mutante/socket_spe6

@onready var sockets:Array = [socket_spe, socket_spe_2,socket_spe_3,socket_spe_4, socket_spe_5, socket_spe_6 ]

func _on_battle_button_pressed() -> void:
	usar_mutagenos()


func usar_mutagenos():
	for i in sockets :
		i._on_something()
		
