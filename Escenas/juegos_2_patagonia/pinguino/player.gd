extends CharacterBody2D
#player pinguino


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var combo_label: Label = $combo_label

@export var speed: float = 400.0
@export var lane_width: float = 100.0
@export var lanes: int = 5

var target_x: float = 0.0
var current_lane: int = 2
var initial_x: float = 0.0  # Guardamos la posición inicial

func _ready():
	initial_x = global_position.x
	target_x = initial_x  # Comenzamos desde la posición inicial
	combo_label.hide()

func _physics_process(delta):
	global_position.x = move_toward(global_position.x, target_x, speed * delta)
	
func _input(event):
	if event.is_action_pressed("ui_left") and current_lane > 0:
		current_lane -= 1
		# Calculamos offset desde el centro
		var offset = (current_lane - 1) * lane_width
		target_x = initial_x + offset
	elif event.is_action_pressed("ui_right") and current_lane < lanes - 1:
		current_lane += 1
		var offset = (current_lane - 1) * lane_width
		target_x = initial_x + offset

func _combo_breaker():
	combo_label.show()
	animation_player.play("combo")
	await animation_player.animation_finished
	combo_label.hide()
	
