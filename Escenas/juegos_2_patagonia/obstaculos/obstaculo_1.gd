extends RigidBody2D
#obstaculo

var SPEED

func _ready():
	# Rotación aleatoria para variedad
	rotation = randf_range(-0.2, 0.2)
	SPEED = Global.hielo_speed
	gravity_scale = Global.hielo_speed

func _physics_process(delta):
	position.y += SPEED * delta
	gravity_scale = Global.hielo_speed
	
	# Si sale de la pantalla, se elimina
	if position.y > get_viewport().size.y + 50:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("hubo hit")
		Global.hit.emit()
		
