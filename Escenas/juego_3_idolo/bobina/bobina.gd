extends Node2D

@export var bobina_health:int = 150
var is_dead
@onready var damge_position: Marker2D = $damge_position
var position_final
@onready var attack_timer: Timer = $attack_timer
var bobina_dmg:int = 25
var enemy
@onready var rayos: Node2D = $rayos
@onready var efecto_timer: Timer = $efecto_timer
@onready var particulas: CPUParticles2D = $CPUParticles2D
@export var bobina_nivel:int = 1


func _ready() -> void:
	position_final = damge_position.global_position
	particulas.amount = 12 #aumentar segun bobina_nivel



func take_damage(damage: int) -> void:
	if is_dead:
		return
	print("bobina recibió daño: ", damage)
	bobina_health -= damage
	DamageNumbers.display_numbers_tesla(damage,position_final )
	


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigo"):
		enemy = body
		attack_timer.start()


func _on_attack_timer_timeout() -> void:
	_apply_dmg()
		

func _apply_dmg():
	if enemy: #si hay enemigo hago...
		efecto_timer.start()
		rayos.show()
		enemy.take_damage(bobina_dmg)


func _on_efecto_timer_timeout() -> void:
	rayos.hide()
