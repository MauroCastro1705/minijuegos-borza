extends Node2D
@export var emocion_scene:PackedScene
var spawn_timer
@onready var center: Marker2D = $Marker2D
@onready var camera_2d: Camera2D = $centro/Camera2D

var emocion_positions: Array[Marker2D] = []
@onready var centro: Node2D = $centro
@onready var score:int = 0
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var marker_2d_2: Marker2D = %Marker2D2
@onready var marker_2d_3: Marker2D = %Marker2D3
@onready var marker_2d_4: Marker2D = %Marker2D4
@onready var marker_2d_5: Marker2D = %Marker2D5
@onready var score_label: Label = %score
@onready var lifebaremocion: Control = $CanvasLayer/Lifebaremocion
@onready var game_over: Node2D = $CanvasLayer/game_over

@onready var emocion_speed:float = 50.0

@onready var _camera_default_offset: Vector2 = camera_2d.offset
var _camera_shake_tween: Tween
var can_spawn:bool = true

func _ready() -> void:
	canvas_layer.show()
	game_over.hide()
	emocion_positions = [marker_2d_2, marker_2d_3, marker_2d_4, marker_2d_5]
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = 2
	spawn_timer.timeout.connect(_spawn_emocion)
	spawn_timer.start()
	centro.score_up.connect(_score_up)
	centro.wrong_emotion.connect(_wrong_emotion)
	lifebaremocion.life_ended.connect(_player_died)


func _score_up():
	score += 1
	score_label.text = "Score: " + str((score * 10))
	check_score()
	
func _wrong_emotion():
	_shake_camera()
	lifebaremocion.reduce_life()

func _player_died():
	can_spawn = false
	game_over.show()


func _shake_camera() -> void:
	if _camera_shake_tween and _camera_shake_tween.is_running():
		_camera_shake_tween.kill()
	camera_2d.offset = _camera_default_offset

	_camera_shake_tween = create_tween()
	var shake_duration := 0.24
	var shake_strength := 15.0
	var shake_steps := 5
	for step in range(shake_steps):
		var strength := shake_strength * (1.0 - float(step) / shake_steps)
		var shake_offset := Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		_camera_shake_tween.tween_property(
			camera_2d,
			"offset",
			_camera_default_offset + shake_offset,
			shake_duration / shake_steps
		)
	_camera_shake_tween.tween_property(
		camera_2d,
		"offset",
		_camera_default_offset,
		shake_duration / shake_steps
	)


func _spawn_emocion():
	if not can_spawn:
		return
	else:
		var new_emocion = emocion_scene.instantiate()
		get_parent().add_child(new_emocion)
		new_emocion.position = emocion_positions.pick_random().global_position
		new_emocion.marker = centro.centro_marker
		new_emocion.SPEED = emocion_speed
		print("speed actual: " , emocion_speed)

func check_score():
	emocion_speed = 50 + score * 2.5


func _on_restart_pressed() -> void:
	TransitionManager.change_scene("res://Escenas/juego_6_emociones/emociones_menu/menu_emociones.tscn")
