extends Node2D

# En tu script principal (ej: spawner de meteoritos)
@export var meteorite_scene: PackedScene  # Asignar en el editor
@onready var meteor_spawn: Timer = $meteor_spawn
@onready var materia_bar: ProgressBar = $materia_bar


func _ready() -> void:
	Global.update.connect(_update)
	_update()
	meteor_spawn.start()
	spawn_meteorite_from_edge()
	spawn_meteorite_from_edge()
	spawn_meteorite_from_edge()
	spawn_meteorite_from_edge()
	spawn_meteorite_from_edge()
	spawn_meteorite_from_edge()
	spawn_meteorite_from_edge()



func _update():
	materia_bar.value = Global.materia

# Versión mejorada con spawn desde bordes
func spawn_meteorite_from_edge():
	var meteorite = meteorite_scene.instantiate()
	var viewport_size = get_viewport().size
	
	# Elegir borde aleatorio (0=arriba, 1=derecha, 2=abajo, 3=izquierda)
	var edge = randi_range(0, 3)
	match edge:
		0: # Arriba
			meteorite.position = Vector2(randf_range(0, viewport_size.x), -50)
		1: # Derecha
			meteorite.position = Vector2(viewport_size.x + 50, randf_range(0, viewport_size.y))
		2: # Abajo
			meteorite.position = Vector2(randf_range(0, viewport_size.x), viewport_size.y + 50)
		3: # Izquierda
			meteorite.position = Vector2(-50, randf_range(0, viewport_size.y))
	
	add_child(meteorite)
	
	


func _on_meteor_spawn_timeout() -> void:
	spawn_meteorite_from_edge()
