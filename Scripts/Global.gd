extends Node

@warning_ignore("unused_signal")
signal update
@warning_ignore("unused_signal")
signal hit
@warning_ignore("unused_signal")
signal  pick_up

@warning_ignore("unused_signal")
signal enemy_hit

#planeta expansion
var materia:int = 0
var planeta_finished:bool = false

var hielo_speed:float = 1.0 #para gravity scale

##score juego 2
var comida:int = 0
var score_pinguino:int = 0
