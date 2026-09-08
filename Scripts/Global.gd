extends Node

@warning_ignore("unused_signal")
signal update
@warning_ignore("unused_signal")
signal hit
@warning_ignore("unused_signal")
signal  pick_up

@warning_ignore("unused_signal")
signal enemy_hit
@warning_ignore("unused_signal")
signal enemy_died
@warning_ignore("unused_signal")
signal buy_upgrade


#planeta expansion
var materia:int = 0
var planeta_finished:bool = false

var hielo_speed:float = 1.0 #para gravity scale

##score juego 2
var comida:int = 0
var score_pinguino:int = 0

##juego 3
var corriente:int = 120
var enemy_corriente:int = 5
var bobina_dmg:int = 5
var bobina_speed:float = 1.0
var click_damage: float = 3  # Daño por click (ajustable)
var click_cooldown: float = 1.0  # Cooldown entre clicks en segundos
