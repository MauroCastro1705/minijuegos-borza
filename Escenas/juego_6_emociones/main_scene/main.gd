extends Node2D
@export var emocion_scene:PackedScene
var spawn_timer
@onready var center: Marker2D = $Marker2D
@onready var marker_2d_2: Marker2D = $Marker2D2
@onready var marker_2d_3: Marker2D = $Marker2D3
@onready var marker_2d_4: Marker2D = $Marker2D4
@onready var marker_2d_5: Marker2D = $Marker2D5
var emocion_positions: Array[Marker2D] = []
@onready var centro: Node2D = $centro
@onready var label: Label = $Label

func _ready() -> void:
	emocion_positions = [marker_2d_2, marker_2d_3, marker_2d_4, marker_2d_5]
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = 2
	spawn_timer.timeout.connect(_spawn_emocion)
	spawn_timer.start()


func _spawn_emocion():
	var new_emocion = emocion_scene.instantiate()
	get_parent().add_child(new_emocion)
	new_emocion.position = emocion_positions.pick_random().global_position
	new_emocion.marker = center
