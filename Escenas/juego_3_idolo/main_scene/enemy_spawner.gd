extends Node2D

@export var enemy_scene: PackedScene  # Arrastra la escena del enemigo aquí
@export var spawn_interval: float = 2.0  # Tiempo entre spawns
@export var auto_spawn: bool = true  # Si empieza a spawnear automáticamente
@onready var button: Button = $"../Button"

# Configuración de oleadas
@export var wave1_enemies: int = 3
@export var wave2_enemies: int = 5
@export var wave3_enemies: int = 8

@export var spawn_point: Marker2D
@onready var wave_info: Label = $wave_info

var enemies_spawned: int = 0
var spawn_timer: Timer
var current_wave: int = 1
var total_waves: int = 3
var wave_started: bool = false
var waiting_for_wave: bool = false

func _ready() -> void:
	# Crear y configurar el timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	update_wave_info()
	
	if auto_spawn:
		start_next_wave()

func _on_spawn_timer_timeout() -> void:
	if enemies_spawned < get_current_wave_enemy_count() and enemy_scene:
		spawn_enemy()
		enemies_spawned += 1
		
		# Si ya spawnearon todos los enemigos de la oleada
		if enemies_spawned >= get_current_wave_enemy_count():
			spawn_timer.stop()
			waiting_for_wave = true
			update_wave_info()
			
			# Verificar si es la última oleada
			if current_wave >= total_waves:
				print("¡Todas las oleadas completadas!")
				wave_info.text = "¡Todas las oleadas completadas!"

func spawn_enemy() -> void:
	if not enemy_scene or not spawn_point:
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point.global_position
	get_parent().add_child(enemy)

# Función para comenzar la próxima oleada
func start_next_wave() -> void:
	if current_wave > total_waves:
		print("No hay más oleadas disponibles")
		return
	
	if not wave_started or waiting_for_wave:
		wave_started = true
		waiting_for_wave = false
		enemies_spawned = 0
		update_wave_info()
		spawn_timer.start()
		print("Oleada " + str(current_wave) + " comenzada")

# Función para obtener la cantidad de enemigos de la oleada actual
func get_current_wave_enemy_count() -> int:
	match current_wave:
		1:
			return wave1_enemies
		2:
			return wave2_enemies
		3:
			return wave3_enemies
		_:
			return 0

# Función para obtener la cantidad de enemigos de la próxima oleada
func get_next_wave_enemy_count() -> int:
	match current_wave + 1:
		1:
			return wave1_enemies
		2:
			return wave2_enemies
		3:
			return wave3_enemies
		_:
			return 0

# Función para avanzar a la siguiente oleada
func advance_to_next_wave() -> void:
	if current_wave < total_waves:
		current_wave += 1
		start_next_wave()

# Actualizar información de oleadas en el label
func update_wave_info() -> void:
	var current_wave_enemies = get_current_wave_enemy_count()
	var next_wave_enemies = get_next_wave_enemy_count()
	
	var info_text = "Wave " + str(current_wave) + "/" + str(total_waves) + "\n"
	info_text += "Current wave: " + str(current_wave_enemies) + "\n"
	
	if current_wave < total_waves:
		info_text += "Next wave: " + str(next_wave_enemies) + " Robots"
	else:
		info_text += "Last wave"
	
	if waiting_for_wave and current_wave <= total_waves:
		info_text += "\n[Press button for next wave]"
	
	wave_info.text = info_text
	print(info_text)

# Funciones adicionales útiles
func start_spawning() -> void:
	if not spawn_timer.is_stopped():
		return
	enemies_spawned = 0
	spawn_timer.start()

func stop_spawning() -> void:
	spawn_timer.stop()

func reset_spawner() -> void:
	current_wave = 1
	enemies_spawned = 0
	waiting_for_wave = false
	wave_started = false
	spawn_timer.stop()
	update_wave_info()
	if auto_spawn:
		start_next_wave()



func _on_button_pressed() -> void:
	if waiting_for_wave and current_wave < total_waves:
		advance_to_next_wave()
	elif waiting_for_wave and current_wave >= total_waves:
		button.disabled = true
		print("¡Ya completaste todas las oleadas!")
