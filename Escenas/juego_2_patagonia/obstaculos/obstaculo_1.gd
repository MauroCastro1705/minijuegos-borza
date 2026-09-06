extends RigidBody2D
#obstaculo

var SPEED
var impacto_position = Vector2.ZERO  # Guardar posición exacta del impacto
@onready var explosion: GPUParticles2D = $explosion_scene

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
		
		# Guardar la posición exacta del impacto
		impacto_position = global_position
		
		# Mostrar explosión en el punto de impacto
		show_explosion()

func show_explosion():
	explosion.emitting = true
