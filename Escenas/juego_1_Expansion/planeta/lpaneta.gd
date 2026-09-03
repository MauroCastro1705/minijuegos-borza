extends CharacterBody2D

@export var speed: float = 400.0

@export var friction: float = 7.0  ## Qué tan rápido se frena (más alto = más rápido)
@export var acceleration: float = 10.0  ## Qué tan rápido acelera (más alto = más rápido)

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector != Vector2.ZERO:
		var target_velocity = input_vector * speed
		velocity = velocity.lerp(target_velocity, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		if velocity.length() < 1.0:
			velocity = Vector2.ZERO
	move_and_slide()
