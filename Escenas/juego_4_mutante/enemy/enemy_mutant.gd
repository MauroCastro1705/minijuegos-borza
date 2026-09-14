extends CharacterBody2D

@onready var attack_timer: Timer = $attack_timer
@onready var rayo_1: Node2D = $Rayo1
@onready var damage_timer: Timer = $damage_timer
@onready var barra_vida: HealthBar3 = $BarraVida_mutante

@onready var number_position: Marker2D = $Marker2D
var number_real_position
var bobina
var enemy_dmg:int = 5
signal died
var max_health:float = 50
var current_health: float
var is_dead: bool = false
var SPEED:float = 80

var can_attack:bool = true


func _ready() -> void:
	number_real_position = number_position.position
	current_health = max_health
	barra_vida.health_depleted.connect(_on_health_depleted)
	barra_vida.max_health = max_health
	barra_vida.current_health = current_health
	
func _physics_process(_delta: float) -> void:
	if not is_dead:
		velocity.x = -SPEED  # Velocidad constante hacia la izquierda
		move_and_slide()
	
func take_damage(damage: int) -> void:
	if is_dead:
		return
	print("robot recibió daño: ", damage)
	current_health -= damage
	rayo_1.show()
	damage_timer.start()
	number_real_position = number_position.global_position
	DamageNumbers.display_numbers_tesla(damage, number_real_position)
	if barra_vida:
		barra_vida.take_damage(damage)

func take_damage_no_effect(damage: int) -> void:
	if is_dead:
		return
	print("robot recibió daño de click: ", damage)
	current_health -= damage
	DamageNumbers.display_numbers_tesla(damage, global_position)
	if barra_vida:
		barra_vida.take_damage(damage)

func _on_health_depleted():
	if is_dead:
		return
	is_dead = true
	Global.corriente += Global.enemy_corriente
	Global.enemy_died.emit()
	died.emit()
	can_attack = false
	barra_vida.hide()
	print("robot murio")
	queue_free()
	
func _on_damage_timer_timeout() -> void:
	rayo_1.hide()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("bobina"):
		bobina = body
		attack_timer.start()

func _on_attack_timer_timeout() -> void:
	if can_attack:
		bobina.take_damage(enemy_dmg)
