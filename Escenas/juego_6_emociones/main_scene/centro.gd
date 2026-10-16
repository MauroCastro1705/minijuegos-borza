extends CharacterBody2D

@onready var emocion_1: Area2D = $emocion_1
@onready var emocion_2: Area2D = $emocion_2
@onready var emocion_3: Area2D = $emocion_3
@onready var emocion_4: Area2D = $emocion_4
@onready var centro_marker: Marker2D = $centro

@onready var corner: TextureRect = $corner
@onready var corner_2: TextureRect = $corner2
@onready var corner_3: TextureRect = $corner3
@onready var corner_4: TextureRect = $corner4

var color_1: Color = Color.DARK_RED
var color_2: Color = Color.BLUE_VIOLET
var color_3: Color = Color.DARK_GREEN
var color_4: Color = Color.DARK_GOLDENROD
signal score_up
@export var speed: float = 300.0   # píxeles por segundo

# --- Rotación ---
@export var rotation_step_deg: float = 90.0   # cuánto gira por pulsación
@export var rotation_speed: float = 15.0      # qué tan rápido alcanza el objetivo
var target_rotation: float = 0.0
var rotating: bool = false

func _ready() -> void:
	corner.self_modulate = color_1
	corner_2.self_modulate = color_2
	corner_3.self_modulate = color_3
	corner_4.self_modulate = color_4
	target_rotation = rotation

func _unhandled_input(event: InputEvent) -> void:
	if rotating:
		return
	if event.is_action_pressed("left_click"):
		target_rotation -= deg_to_rad(rotation_step_deg)
		rotating = true
	elif event.is_action_pressed("right_click"):
		target_rotation += deg_to_rad(rotation_step_deg)
		rotating = true

func _physics_process(delta: float) -> void:
	# --- Movimiento con colisiones ---
	var input_dir := Input.get_vector("left", "right", "up", "down")
	velocity = input_dir * speed
	move_and_slide()

	# --- Rotación ---
	if rotating:
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)
		if abs(angle_difference(rotation, target_rotation)) < 0.01:
			rotation = target_rotation
			rotating = false

func _on_emocion_1_area_entered(area: Area2D) -> void:
	if area.is_in_group("alegria"):
		print("Alegria")
		score_up.emit()
		area.queue_free()
	else:
		print("mal")
		area.queue_free()


func _on_emocion_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("tristeza"):
		print("tristeza")
		area.queue_free()
		score_up.emit()
	else:
		print("mal")
		area.queue_free()


func _on_emocion_3_area_entered(area: Area2D) -> void:
	if area.is_in_group("calma"):
		print("calma")
		area.queue_free()
		score_up.emit()
	else:
		print("mal")
		area.queue_free()


func _on_emocion_4_area_entered(area: Area2D) -> void:
	if area.is_in_group("enojo"):
		print("enojo")
		area.queue_free()
		score_up.emit()
	else:
		print("mal")
		area.queue_free()
