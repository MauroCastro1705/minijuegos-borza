extends CharacterBody2D


@onready var barra_vida: HealthBar3 = $BarraVida_mutante

@onready var number_position: Marker2D = $Marker2D
var number_real_position

var enemy_dmg:int = 15
signal died
var max_health:float = 60
var current_health: float
var is_dead: bool = false
var SPEED:float = 10

var can_attack:bool = true


func _ready() -> void:
	number_real_position = number_position.position
	current_health = max_health
	barra_vida.health_depleted.connect(_on_health_depleted)
	barra_vida.max_health = max_health
	barra_vida.current_health = current_health

func _physics_process(_delta: float) -> void:
	pass


func take_damage(damage: int) -> void:
	if is_dead:
		return
	print("robot recibió daño: ", damage)
	current_health -= damage
	number_real_position = number_position.global_position
	DamageNumbers.display_numbers_tesla(damage, number_real_position)
	DamageNumbers.flash_sprite(self)
	if barra_vida:
		barra_vida.take_damage(damage)


func _on_health_depleted():
	if is_dead:
		return
	is_dead = true
	Global.enemy_died.emit()
	died.emit()
	can_attack = false
	barra_vida.hide()
	print("robot murio")
	queue_free()
	
func atacar(objetivo: Node2D) -> void:
	if not is_instance_valid(objetivo):
		return

	var damage: int = int(enemy_dmg)
	if objetivo.has_method("take_damage"):
		# Dirección hacia el objetivo
		var direccion := (objetivo.global_position - global_position).normalized()
		var pos_original := global_position
		var distancia_lunge := 25.0  # cuánto se lanza hacia adelante

		# --- Animación tipo Pokémon (lunge) ---
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)

		# 1. Lanzarse hacia adelante rápido
		tween.tween_property(self, "global_position",
			pos_original + direccion * distancia_lunge, 0.08).set_ease(Tween.EASE_OUT)

		# 2. Aplicar daño justo en el impacto
		tween.tween_callback(func():
			objetivo.take_damage(damage)
			print("mutante ataco")
		)

		# 3. Volver a la posición original
		tween.tween_property(self, "global_position",
			pos_original, 0.15).set_ease(Tween.EASE_IN)
