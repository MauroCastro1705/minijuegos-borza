extends CharacterBody2D


var materia:int = 0
@export var speed: float = 300.0

func _physics_process(_delta: float) -> void:
	# Obtener la entrada del jugador
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Normalizar y aplicar velocidad
	velocity = input_vector * speed
	
	# Mover el personaje
	move_and_slide()
