extends Area2D

@export var pickup_scene: PackedScene
@export var spawn_interval: float = 1.5
@export var min_spawn_interval: float = 1.0
@export var max_obstacles_per_wave: int = 1

var spawn_timer: Timer
var rng = RandomNumberGenerator.new()
var spawn_rect: Rect2

func _ready():
	rng.randomize()
	
	# Configurar el rectángulo de spawn basado en la colisión del Area2D
	_setup_spawn_rect()
	
	# Crear y configurar el timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_obstacle)
	spawn_timer.start()
	

func _setup_spawn_rect():
	# Buscar el CollisionShape2D hijo
	var collision_shape = get_child(0) if get_child_count() > 0 else null
	var shape = collision_shape.shape
	if shape is RectangleShape2D:
		var extents = shape.extents
		var pos = global_position
		spawn_rect = Rect2(
			pos.x - extents.x,
			pos.y - extents.y,
			extents.x * 2,
			extents.y * 2
			)
		print("Área de spawn configurada: ", spawn_rect)
	else:
		print("ERROR: La forma de colisión debe ser RECTANGULAR (RectangleShape2D)")
			# Crear un rectángulo por defecto
		spawn_rect = Rect2(global_position.x - 200, global_position.y - 300, 400, 600)
		# Crear un rectángulo por defecto
		spawn_rect = Rect2(global_position.x - 200, global_position.y - 300, 400, 600)

func _spawn_obstacle():
	# Disminuir intervalo con el tiempo (dificultad creciente)
	spawn_interval = max(min_spawn_interval, spawn_interval - 0.01)
	spawn_timer.wait_time = spawn_interval
	
	# Cuántos obstáculos en esta oleada
	var count = rng.randi_range(1, max_obstacles_per_wave)
	
	for i in range(count):
		var obstacle = pickup_scene.instantiate()
		get_parent().add_child(obstacle)  # Añadir al padre (Main) en lugar de al spawner
		
		# Posición aleatoria DENTRO del área de spawn
		var spawn_position = _get_random_position_in_area()
		
		# Posición Y escalonada para no solapar
		var y_offset = i * 80
		obstacle.position = Vector2(
			spawn_position.x,
			spawn_position.y - y_offset
		)

func _get_random_position_in_area() -> Vector2:
	if spawn_rect == Rect2():
		# Si no hay área configurada, usar valores por defecto
		return Vector2(
			rng.randf_range(-200, 200),
			rng.randf_range(-50, -150)
		)
	
	# Generar posición aleatoria dentro del rectángulo
	var x = rng.randf_range(spawn_rect.position.x, spawn_rect.position.x + spawn_rect.size.x)
	var y = rng.randf_range(spawn_rect.position.y, spawn_rect.position.y + spawn_rect.size.y)
	
	return Vector2(x, y)


# Función para pausar el spawn (útil para game over)
func toggle_spawn(paused: bool):
	if paused:
		spawn_timer.stop()
	else:
		spawn_timer.start()

# Función para cambiar el intervalo de spawn dinámicamente
func set_spawn_interval(new_interval: float):
	spawn_interval = clamp(new_interval, min_spawn_interval, 10.0)
	spawn_timer.wait_time = spawn_interval
		
