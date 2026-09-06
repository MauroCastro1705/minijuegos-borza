extends CharacterBody2D
@onready var walk_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_sprite: AnimatedSprite2D = $death_sprite
@onready var barra_vida: HealthBar = $BarraVida
@onready var attack_timer: Timer = $attack_timer
@onready var rayo_1: Node2D = $Rayo1
@onready var damage_timer: Timer = $damage_timer


signal died
var max_health:float = 50
var current_health: float
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	barra_vida.health_depleted.connect(_on_health_depleted)
	barra_vida.max_health = max_health
	barra_vida.current_health = current_health
	
	
	
func take_damage(damage: int) -> void:
	if is_dead:
		return
	print("robot recibió daño: ", damage)
	current_health -= damage
	rayo_1.show()
	damage_timer.start()
	DamageNumbers.display_numbers(damage, global_position)
	
	if barra_vida:
		barra_vida.take_damage(damage)

	
func _on_health_depleted():
	if is_dead:
		return
	is_dead = true
	died.emit()
	death_sprite.play("default") #mostramos el sprite de explosion
	walk_sprite.hide() #escondemos el sprite original
	await death_sprite.animation_finished
	queue_free()


func _on_damage_timer_timeout() -> void:
	rayo_1.hide()
