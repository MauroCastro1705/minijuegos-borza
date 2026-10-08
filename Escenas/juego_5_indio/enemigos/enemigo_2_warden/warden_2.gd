extends CharacterBody2D
# prision warden melee

@onready var number_position: Marker2D = $Marker2D
var number_real_position
@onready var hurt_effect: CPUParticles2D = $hurt_effect
@onready var attack_area: Area2D = $attack_area
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_friction: float = 900.0  # qué tan rápido se frena

signal died

# --- Stats base (matchean con el GameManager) ---
var max_health: float = 60
var current_health: float
var fuerza: int = 1            # daño base
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
var _jugador: Node2D
var atacado:bool = false

func _ready() -> void:
	number_real_position = number_position.position
	_pos_inicial = global_position
	current_health = max_health
	_girar_hacia(_direccion)

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

	if is_instance_valid(_jugador):
		var diferencia_x := _jugador.global_position.x - global_position.x
		if not is_zero_approx(diferencia_x):
			_girar_hacia(1 if diferencia_x > 0.0 else -1)
		
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	else:
		if not atacado:
			if is_instance_valid(_jugador):
				velocity.x = 0
				if animated_sprite_2d.animation != "attack" or not animated_sprite_2d.is_playing():
					if animated_sprite_2d.animation != "idle" or not animated_sprite_2d.is_playing():
						animated_sprite_2d.play("idle")
			else:
				# Chequear límites de patrulla antes de avanzar para evitar sobrepasarlos.
				var desplazamiento := global_position.x - _pos_inicial.x
				if _direccion == 1 and desplazamiento >= distancia_patrulla:
					_direccion = -1
					_girar_hacia(_direccion)
				elif _direccion == -1 and desplazamiento <= -distancia_patrulla:
					_direccion = 1
					_girar_hacia(_direccion)

				velocity.x = _direccion * velocidad
				if animated_sprite_2d.animation != "walk" or not animated_sprite_2d.is_playing():
					animated_sprite_2d.play("walk")
		else:
			velocity.x = 0

	move_and_slide()

	if not is_instance_valid(_jugador) and not atacado and knockback_velocity.length() == 0 and is_on_wall():
		_direccion *= -1
		_girar_hacia(_direccion)
	
	# --- Cooldown de ataque ---
	if not _puede_atacar:
		_timer_ataque -= delta
		if _timer_ataque <= 0.0:
			_puede_atacar = true

func apply_knockback(origin_position: Vector2, force: float) -> void:
	var direction = (global_position - origin_position).normalized()
	knockback_velocity = direction * force


func _girar_hacia(direccion: int) -> void:
	animated_sprite_2d.flip_h = direccion < 0


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
		_jugador = body
		var diferencia_x := body.global_position.x - global_position.x
		if not is_zero_approx(diferencia_x):
			_girar_hacia(1 if diferencia_x > 0.0 else -1)
		if _puede_atacar:
			atacar(body)
			_puede_atacar = false
			_timer_ataque = cooldown_ataque


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == _jugador:
		_jugador = null
		_girar_hacia(_direccion)
