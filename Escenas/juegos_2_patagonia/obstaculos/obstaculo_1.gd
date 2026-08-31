extends RigidBody2D
#obstaculo

@export var SPEED:float = 300

func _ready():
	# Rotación aleatoria para variedad
	rotation = randf_range(-0.2, 0.2)


func _physics_process(delta):
	# Movimiento hacia abajo (el río fluye)
	position.y += SPEED * delta
	
	# Si sale de la pantalla, se elimina
	if position.y > get_viewport().size.y + 50:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("hubo hit")
		Global.hit.emit()
