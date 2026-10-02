extends CharacterBody2D
# prision warden melee

@onready var number_position: Marker2D = $Marker2D
var number_real_position
@onready var hurt_effect: CPUParticles2D = $hurt_effect
@onready var attack_area: Area2D = $attack_area
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


signal died

# --- Stats base (matchean con el GameManager) ---
var max_health: float = 60
var current_health: float
var fuerza: int = 5            # daño base
var velocidad: float = 100.0

# Alias por compatibilidad con código viejo
var enemy_dmg: int:
	get: return fuerza
	set(value): fuerza = value

var is_dead: bool = false
var nombre_anterior: String = ""

# --- Patrullaje ---
@export var distancia_patrulla: float = 150.0   # cuánto camina hacia cada lado
@export var cooldown_ataque: float = 1.0        # segundos entre ataques

var _direccion: int = 1                         # 1 = derecha, -1 = izquierda
var _pos_inicial: Vector2
var _puede_atacar: bool = true
var _timer_ataque: float = 0.0
var _jugador_en_area: bool = false              # true si el jugador está dentro del área


func _ready() -> void:
	number_real_position = number_position.position
	_pos_inicial = global_position
	current_health = max_health

	# Conectar el área de ataque con el jugador
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	if not attack_area.body_exited.is_connected(_on_attack_area_body_exited):
		attack_area.body_exited.connect(_on_attack_area_body_exited)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# --- Gravedad ---
	if not is_on_floor():
		velocity.y += 980 * delta

	# --- Movimiento ---
	if _jugador_en_area:
		# El jugador está encima/pegado: nos detenemos
		velocity.x = 0
		
	else:
		velocity.x = _direccion * velocidad
		animated_sprite_2d.play("walk")

		# Chequear límites de patrulla
		var desplazamiento = global_position.x - _pos_inicial.x
		if _direccion == 1 and desplazamiento >= distancia_patrulla:
			_direccion = -1
			_girar()
		elif _direccion == -1 and desplazamiento <= -distancia_patrulla:
			_direccion = 1
			_girar()

		# También gira si toca pared
		if is_on_wall():
			_direccion *= -1
			_girar()

	move_and_slide()
	
	# --- Cooldown de ataque ---
	if not _puede_atacar:
		_timer_ataque -= delta
		if _timer_ataque <= 0.0:
			_puede_atacar = true


func _girar() -> void:
	scale.x = abs(scale.x) * _direccion
	# attack_area.position.x = abs(attack_area.position.x) * _direccion


# ------------------ RECIBIR DAÑO ------------------
func take_damage(damage: int) -> void:
	if is_dead:
		return
	number_real_position = number_position.global_position
	DamageNumbers.display_numbers_tesla(damage, number_real_position)
	hurt_effect.emitting = true
	DamageNumbers.flash_sprite(self)

	current_health -= damage
	if current_health <= 0:
		_on_health_depleted()


func _on_health_depleted():
	if is_dead:
		return
	is_dead = true
	Global.enemy_died.emit()
	died.emit()

	print("enemigo murio")
	queue_free()


# ------------------ ATACAR ------------------
func atacar(objetivo: Node2D) -> void:
	if is_dead:
		return
	if not is_instance_valid(objetivo):
		return

	var damage: int = int(fuerza)
	if objetivo.has_method("take_damage"):
		animated_sprite_2d.play("attack")
		objetivo.take_damage(damage)


# ------------------ ÁREA DE ATAQUE ------------------
func _on_attack_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if body.is_in_group("player"):
		_jugador_en_area = true
		if _puede_atacar:
			atacar(body)
			_puede_atacar = false
			_timer_ataque = cooldown_ataque


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_jugador_en_area = false
