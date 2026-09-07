extends Node2D

@export var bobina_health:int = 150
var is_dead: bool = false
@onready var damage_position: Marker2D = $damge_position
var position_final: Vector2
@onready var attack_timer: Timer = $attack_timer
@onready var rayos: Node2D = $rayos
@onready var efecto_timer: Timer = $efecto_timer
@onready var particulas: CPUParticles2D = $CPUParticles2D
@export var bobina_nivel:int = 1


# Lista de enemigos en rango (orden de entrada)
var enemies_in_range: Array = []

func _ready() -> void:
	position_final = damage_position.global_position
	particulas.amount = 12 #aumentar segun bobina_nivel
	rayos.hide()

func take_damage(damage: int) -> void:
	if is_dead:
		return
	print("bobina recibió daño: ", damage)
	bobina_health -= damage
	DamageNumbers.display_numbers_tesla(damage, position_final)
	
	# Si la salud llega a 0, destruir la torreta
	if bobina_health <= 0:
		is_dead = true
		queue_free()

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigo") and not body in enemies_in_range:
		enemies_in_range.append(body)
		# Si no hay timer activo y hay enemigos, empezar a atacar
		if not attack_timer.is_stopped() == false:
			attack_timer.wait_time = Global.bobina_speed
			attack_timer.start()

func _on_hit_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemigo") and body in enemies_in_range:
		enemies_in_range.erase(body)
		# Si no quedan enemigos, detener el timer
		if enemies_in_range.is_empty():
			attack_timer.stop()
			rayos.hide()

func _on_attack_timer_timeout() -> void:
	# Limpiar enemigos muertos o inválidos
	_clean_invalid_enemies()
	
	if not enemies_in_range.is_empty():
		var current_enemy = enemies_in_range[0] # El primero en entrar
		
		# Verificar si el enemigo sigue siendo válido
		if is_instance_valid(current_enemy) and not current_enemy.is_dead:
			_apply_dmg(current_enemy)
		else:
			# Si el enemigo ya no es válido, eliminarlo y seguir con el siguiente
			enemies_in_range.erase(current_enemy)
			_on_attack_timer_timeout() # Llamada recursiva para procesar siguiente

func _apply_dmg(enemy: Node2D) -> void:
	if enemy and is_instance_valid(enemy) and not enemy.is_dead:
		rayos.show()
		efecto_timer.start()
		enemy.take_damage(Global.bobina_dmg)
		
		# Mover el rayo hacia la posición del enemigo
		#rayos.global_position = global_position
		#rayos.rotation = #global_position.angle_to_point(enemy.global_position)

func _on_efecto_timer_timeout() -> void:
	rayos.hide()

func _clean_invalid_enemies() -> void:
	# Eliminar enemigos muertos o que ya no existen
	var i = enemies_in_range.size() - 1
	while i >= 0:
		var enemy = enemies_in_range[i]
		if not is_instance_valid(enemy) or enemy.is_dead:
			enemies_in_range.remove_at(i)
		i -= 1

# Método auxiliar para debug
func get_enemies_count() -> int:
	return enemies_in_range.size()
