extends Node2D

@export var enemy_scene: PackedScene  # Arrastra la escena del enemigo aquí
@export var spawn_interval: float = 2.0  # Tiempo entre spawns
@export var max_enemies: int = 5  # Cantidad máxima de enemigos a spawnear
@export var auto_spawn: bool = true  # Si empieza a spawnear automáticamente

@export var spawn_point: Marker2D

var enemies_spawned: int = 0
var spawn_timer: Timer

func _ready() -> void:
	# Crear y configurar el timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	if auto_spawn:
		spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemies_spawned < max_enemies and enemy_scene:
		spawn_enemy()
		enemies_spawned += 1
		
		# Si ya spawnearon todos los enemigos, detener el timer
		if enemies_spawned >= max_enemies:
			spawn_timer.stop()

func spawn_enemy() -> void:
	if not enemy_scene or not spawn_point:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	get_parent().add_child(enemy)  # O usa add_child(enemy) si el spawner es el padre directo

# Funciones adicionales útiles
func start_spawning() -> void:
	if not spawn_timer.is_stopped():
		return
	enemies_spawned = 0
	spawn_timer.start()

func stop_spawning() -> void:
	spawn_timer.stop()

func reset_spawner() -> void:
	enemies_spawned = 0
	spawn_timer.stop()
	if auto_spawn:
		spawn_timer.start()
