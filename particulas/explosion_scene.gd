extends GPUParticles2D
# En explosion_particulas.gd


func _ready():
	# Reproducir la explosión
	emitting = true
	# Crear temporizador para autodestrucción
	var timer = Timer.new()
	timer.wait_time = lifetime + 0.5
	timer.one_shot = true
	add_child(timer)
	timer.start()
	# Conectar la señal time_out
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	queue_free()
