extends Node2D
# rayo

@export var trap_dmg: int = 15

@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var timer: Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var trap_time:float = 3.0 ##tiempo entre disparos de la trampa

func _ready() -> void:
	# Configuramos el timer como cooldown de un solo disparo
	timer.wait_time = trap_time
	timer.one_shot = true

	# Conectar la señal de fin de animación
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

	# Arrancar el ciclo
	_activate_trap()


func _activate_trap() -> void:
	collision_shape_2d.set_deferred("disabled", false)
	animated_sprite_2d.play("rayo")


func _on_animation_finished() -> void:
	# Cuando termina la animación, apagamos la hitbox y arrancamos el cooldown
	collision_shape_2d.set_deferred("disabled", true)
	timer.start()


func _on_timer_timeout() -> void:
	# Pasado el cooldown, volvemos a encender la trampa
	_activate_trap()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(trap_dmg)
