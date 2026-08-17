extends Node2D

@export var meteorite_scene: PackedScene
@export var enemy_scene: PackedScene
@onready var meteor_spawn: Timer = $meteor_spawn
@onready var materia_bar: ProgressBar = $materia_bar
@onready var enemy_spawn: Timer = $enemy_spawn
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var vhs_effect: ColorRect = $CanvasLayer/ColorRect
@onready var vhs_button: Button = %vhs
@onready var planeta: CharacterBody2D = $planeta
@onready var total_score: Label = $total_materia
@onready var materia_count: Label = $materia_count
@onready var camera_2d: Camera2D = $Camera2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var score:int = 0
var LEVELS: Dictionary = {
	1: 6,
	2: 8,
	3: 12,
	4: 20,
	5: 30,
	6: 500
}
var current_level: int = 1
var current_materia: int = 0  # Materia acumulada en el nivel actual
var materia_needed: int = 6   # Materia necesaria para el nivel actual

func _ready() -> void:
	vhs_effect.show()
	Global.update.connect(_update)
	Global.hit.connect(_camera_hit)
	
	
	# Inicializar barra
	upgrade_barra()
	_update()
	
	meteor_spawn.start()
	enemy_spawn.start()
	
	for i in range(7):
		spawn_meteorite_from_edge()

func _update():
	score += 10
	total_score.text = "Score " + str(score)
	
	current_materia = Global.materia
	materia_bar.value = current_materia
	materia_needed = LEVELS[current_level]
	update_counter()
	
	if current_materia == materia_needed:
		current_level += 1
		materia_needed = LEVELS[current_level]
		Global.materia = 0
		print("subimos a nivel: ", current_level)
		print("materia para proximo nivel: " , materia_needed)
		level_up()
		upgrade_barra()
	
func upgrade_barra():
	current_materia = Global.materia
	materia_bar.max_value = materia_needed
	materia_bar.value = current_materia
	update_counter()

func update_counter():
	materia_count.text = str(current_materia) + " / " + str(materia_needed)

var tween: Tween

func level_up():
	if not tween or not tween.is_valid():
		tween = create_tween()
	
	var duration = 0.6
	var ease_type = Tween.EASE_IN_OUT

	var new_speed = max(planeta.speed - 75.0, 50.0)
	var new_friction = planeta.friction + 8
	var new_acceleration = max(planeta.acceleration - 5, 30.0)
	var new_scale = planeta.scale + Vector2(0.5, 0.5)
	var new_wait_time = max(enemy_spawn.wait_time - 0.5, 0.2)
	
	audio_stream_player.play()
	
	tween.tween_property(planeta, "speed", new_speed, duration)\
		.set_ease(ease_type).set_trans(Tween.TRANS_QUAD)
	
	tween.parallel().tween_property(planeta, "friction", new_friction, duration)\
		.set_ease(ease_type).set_trans(Tween.TRANS_QUAD)
	
	tween.parallel().tween_property(planeta, "acceleration", new_acceleration, duration)\
		.set_ease(ease_type).set_trans(Tween.TRANS_QUAD)
	
	tween.parallel().tween_property(planeta, "scale", new_scale, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	# Animaciones de la barra de materia
	tween.parallel().tween_property(materia_bar, "modulate", Color.YELLOW, 0.1)
	tween.parallel().tween_property(materia_bar, "modulate", Color.WHITE, 0.3).set_delay(0.1)
	
	tween.parallel().tween_property(materia_bar, "scale", Vector2(1.3, 1.3), 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(materia_bar, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.15)
	
	# Mostrar texto de expansión
	DamageNumbers.display_text("Expansion", planeta.position, Color.WHITE, 35)
	
	enemy_spawn.wait_time = new_wait_time
	print("wait time ", enemy_spawn.wait_time)

func spawn_meteorite_from_edge():
	var meteorite = meteorite_scene.instantiate()
	var viewport_size = get_viewport().size
	
	var edge = randi_range(0, 3)
	match edge:
		0:
			meteorite.position = Vector2(randf_range(0, viewport_size.x), -50)
		1:
			meteorite.position = Vector2(viewport_size.x + 50, randf_range(0, viewport_size.y))
		2:
			meteorite.position = Vector2(randf_range(0, viewport_size.x), viewport_size.y + 50)
		3:
			meteorite.position = Vector2(-50, randf_range(0, viewport_size.y))
	
	add_child(meteorite)

func spawn_enemy_from_edge():
	var enemy = enemy_scene.instantiate()
	var viewport_size = get_viewport().size
	
	var edge = randi_range(0, 3)
	match edge:
		0:
			enemy.position = Vector2(randf_range(0, viewport_size.x), -50)
		1:
			enemy.position = Vector2(viewport_size.x + 50, randf_range(0, viewport_size.y))
		2:
			enemy.position = Vector2(randf_range(0, viewport_size.x), viewport_size.y + 50)
		3:
			enemy.position = Vector2(-50, randf_range(0, viewport_size.y))
	
	add_child(enemy)

func _on_meteor_spawn_timeout() -> void:
	spawn_meteorite_from_edge()

func _on_enemy_spawn_timeout() -> void:
	spawn_enemy_from_edge()

func _on_vhs_toggled(toggled_on: bool) -> void:
	if toggled_on:
		vhs_effect.hide()
		vhs_button.text = "VHS - desac."
	else:
		vhs_effect.show()
		vhs_button.text = "VHS - activado"
		
func _camera_hit():
	camera_2d.shake()
