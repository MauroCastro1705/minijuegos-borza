extends Node2D

@export var enemy_scene: PackedScene  # Arrastra la escena del enemigo aquí
@export var spawn_interval: float = 2.0  # Tiempo entre spawns
@export var auto_spawn: bool = false  # Ahora por defecto NO auto-spawn, empieza con el botón

@onready var battle_button: Button = $"../battle_button"

@onready var game_over_screen: Node2D = $"../game_over_screen"
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"


# Configuración de oleadas
@export var wave1_enemies: int = 3
@export var wave2_enemies: int = 5
@export var wave3_enemies: int = 8

# --- NUEVO: múltiples puntos de spawn ---
@export var spawn_points: Array[Marker2D] = []
# "random" elige un punto aleatorio cada vez
# "round_robin" recorre los puntos en orden
enum SpawnMode { RANDOM, ROUND_ROBIN }
@export var spawn_mode: SpawnMode = SpawnMode.RANDOM

@onready var wave_info: Label = $wave_info

var enemies_spawned: int = 0
var active_enemies: int = 0
var spawn_timer: Timer
var current_wave: int = 1
var total_waves: int = 3
var wave_started: bool = false
var waiting_for_wave: bool = false
var game_started: bool = false   # Controla si ya se pulsó Begin

# Índice para el modo round_robin
var _spawn_index: int = 0


func _ready() -> void:
	game_over_screen.hide()
	# Crear y configurar el timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Estado inicial: botón habilitado con texto "Begin"
	battle_button.disabled = false
	battle_button.text = "Begin"
	
	# Validación: avisar si no hay puntos de spawn asignados
	if spawn_points.is_empty():
		push_warning("No hay spawn_points asignados. Añade al menos uno en el inspector.")
	
	update_wave_info()
	
	if auto_spawn:
		game_started = true
		start_next_wave()


func _on_spawn_timer_timeout() -> void:
	if enemies_spawned < get_current_wave_enemy_count() and enemy_scene:
		spawn_enemy()
		enemies_spawned += 1
		
		if enemies_spawned >= get_current_wave_enemy_count():
			spawn_timer.stop()


# --- NUEVO: obtiene un punto de spawn según el modo configurado ---
func _get_spawn_point() -> Marker2D:
	if spawn_points.is_empty():
		return null
	# Filtrar puntos válidos (por si alguno fue liberado)
	var valid_points := spawn_points.filter(func(p): return is_instance_valid(p))
	if valid_points.is_empty():
		return null
	
	match spawn_mode:
		SpawnMode.ROUND_ROBIN:
			var point = valid_points[_spawn_index % valid_points.size()]
			_spawn_index += 1
			return point
		_:
			return valid_points[randi() % valid_points.size()]


func spawn_enemy() -> void:
	if not enemy_scene:
		return
	
	var punto: Marker2D = _get_spawn_point()
	if punto == null:
		push_warning("No hay un Marker2D válido en spawn_points.")
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = punto.global_position
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	else:
		push_warning("La escena del enemigo no tiene la señal 'died'")
	
	get_parent().add_child(enemy)
	active_enemies += 1


func _on_enemy_died() -> void:
	active_enemies -= 1
	if active_enemies < 0:
		active_enemies = 0
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	if enemies_spawned >= get_current_wave_enemy_count() and active_enemies <= 0:
		waiting_for_wave = true
		update_wave_info()
		
		if current_wave >= total_waves:
			battle_button.disabled = true
			print("¡Todas las oleadas completadas!")
			wave_info.text = "¡Todas las oleadas completadas!"
			on_all_waves_completed()
		else:
			battle_button.disabled = false
			battle_button.text = "Next Wave"
			print("Oleada " + str(current_wave) + " completada. Pulsa el botón para continuar.")


func start_next_wave() -> void:
	if current_wave > total_waves:
		print("No hay más oleadas disponibles")
		return
	
	if not wave_started or waiting_for_wave:
		wave_started = true
		waiting_for_wave = false
		enemies_spawned = 0
		active_enemies = 0
		# Reiniciar el índice de round_robin al empezar oleada (opcional)
		_spawn_index = 0
		battle_button.disabled = true
		update_wave_info()
		spawn_timer.start()
		print("Oleada " + str(current_wave) + " comenzada")


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


func advance_to_next_wave() -> void:
	if current_wave < total_waves:
		current_wave += 1
		start_next_wave()


func update_wave_info() -> void:
	var current_wave_enemies = get_current_wave_enemy_count()
	var next_wave_enemies = get_next_wave_enemy_count()
	
	var info_text = "Wave " + str(current_wave) + "/" + str(total_waves) + "\n"
	info_text += "Current wave: " + str(current_wave_enemies) + "\n"
	
	if current_wave < total_waves:
		info_text += "Next wave: " + str(next_wave_enemies) + " Robots"
	else:
		info_text += "Last wave"
	
	if not game_started:
		info_text += "\n[Press Begin]"
	elif waiting_for_wave and current_wave < total_waves:
		info_text += "\n[Press Next Wave]"
	elif waiting_for_wave and current_wave >= total_waves:
		info_text += "\n[All waves cleared]"
	else:
		info_text += "\nEnemies alive: " + str(active_enemies)
	
	wave_info.text = info_text
	print(info_text)


func start_spawning() -> void:
	if not spawn_timer.is_stopped():
		return
	enemies_spawned = 0
	active_enemies = 0
	spawn_timer.start()


func stop_spawning() -> void:
	spawn_timer.stop()


func reset_spawner() -> void:
	current_wave = 1
	enemies_spawned = 0
	active_enemies = 0
	waiting_for_wave = false
	wave_started = false
	game_started = false
	_spawn_index = 0
	spawn_timer.stop()
	battle_button.disabled = false
	battle_button.text = "Begin"
	update_wave_info()


func on_all_waves_completed() -> void:
	game_over_screen.show()
	animation_player.play("game_over")


func _on_wave_button_pressed() -> void:
	# Primer pulsación: comenzar la wave 1
	if not game_started:
		game_started = true
		battle_button.text = "Next Wave"
		start_next_wave()
		return
	
	# Pulsaciones siguientes: avanzar a la siguiente wave cuando la actual haya terminado
	if waiting_for_wave and current_wave < total_waves:
		advance_to_next_wave()
	elif waiting_for_wave and current_wave >= total_waves:
		battle_button.disabled = true
		print("¡Ya completaste todas las oleadas!")
