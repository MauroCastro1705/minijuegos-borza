extends CharacterBody2D

@export var speed: float = 400.0

@export var friction: float = 7.0  ## Qué tan rápido se frena (más alto = más rápido)
@export var acceleration: float = 10.0  ## Qué tan rápido acelera (más alto = más rápido)

func _physics_process(delta: float) -> void:
	# Obtener la entrada del jugador
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Si hay entrada, aplicar aceleración
	if input_vector != Vector2.ZERO:
		# Normalizar y aplicar aceleración hacia la dirección deseada
		var target_velocity = input_vector * speed
		velocity = velocity.lerp(target_velocity, acceleration * delta)
	else:
		# Si no hay entrada, aplicar fricción para frenar
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		# Si la velocidad es muy pequeña, la ponemos a cero para evitar micro-movimientos
		if velocity.length() < 1.0:
			velocity = Vector2.ZERO
	
	# Mover el personaje
	move_and_slide()
