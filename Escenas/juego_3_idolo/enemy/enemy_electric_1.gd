extends CharacterBody2D
@onready var walk_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_sprite: AnimatedSprite2D = $death_sprite
@onready var attack_timer: Timer = $attack_timer
@onready var rayo_1: Node2D = $Rayo1
@onready var damage_timer: Timer = $damage_timer
@onready var barra_vida: HealthBar2 = $BarraVida_electrica

var bobina
var enemy_dmg:int = 5
signal died
var max_health:float = 50
var current_health: float
var is_dead: bool = false
var SPEED:float = 80

var can_attack:bool = true

# Variables para el click damage
var click_damage: float = 10.0  # Daño por click (ajustable)
var click_cooldown: float = 0.2  # Cooldown entre clicks en segundos
var last_click_time: float = 0.0  # Último momento en que se hizo click

func _ready() -> void:
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
	DamageNumbers.display_numbers_tesla(damage, global_position)
	
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
	death_sprite.show()
	death_sprite.play("default") #mostramos el sprite de explosion
	walk_sprite.hide() #escondemos el sprite original
	barra_vida.hide()
	await death_sprite.animation_finished
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

# ============ NUEVAS FUNCIONES PARA CLICK ============

@warning_ignore("unused_parameter")
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	# Verificar si es un click izquierdo y el enemigo no está muerto
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_dead:
		_handle_click_damage()

func _handle_click_damage() -> void:
	# Verificar cooldown
	var current_time = Time.get_ticks_msec() / 1000.0  # Tiempo en segundos
	if current_time - last_click_time >= click_cooldown:
		last_click_time = current_time
		
		# Aplicar daño por click
		var damage_to_apply = click_damage
		_show_click_effect()
		# ceil redondea hacia arriba para daño entero
		take_damage_no_effect(ceil(damage_to_apply))
		

func _show_click_effect() -> void:
	modulate = Color(1, 0.8, 0.8)  # Efecto de flash rojo
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)

# Funciones públicas para modificar el daño y cooldown desde otros scripts
func set_click_damage(new_damage: float) -> void:
	click_damage = new_damage

func set_click_cooldown(new_cooldown: float) -> void:
	click_cooldown = new_cooldown

# Función para mejorar el daño por click (para upgrades)
func upgrade_click_damage(percentage: float) -> void:
	click_damage *= (1.0 + percentage / 100.0)

# Función para reducir el cooldown (para upgrades)
func upgrade_click_cooldown(percentage: float) -> void:
	click_cooldown *= (1.0 - percentage / 100.0)
	click_cooldown = max(click_cooldown, 0.05)  # Mínimo 0.05 segundos
