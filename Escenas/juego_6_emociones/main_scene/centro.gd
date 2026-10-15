extends Node2D
@onready var emocion_1: Area2D = $emocion_1
@onready var emocion_2: Area2D = $emocion_2
@onready var emocion_3: Area2D = $emocion_3
@onready var emocion_4: Area2D = $emocion_4



@onready var color_rect: ColorRect = $emocion_1/ColorRect
@onready var color_rect_2: ColorRect = $emocion_2/ColorRect2
@onready var color_rect_3: ColorRect = $emocion_3/ColorRect3
@onready var color_rect_4: ColorRect = $emocion_4/ColorRect4



var color_1: Color = Color.DARK_RED
var color_2: Color = Color.BLUE_VIOLET
var color_3: Color = Color.DARK_GREEN
var color_4: Color = Color.DARK_GOLDENROD

var emociones: Array = []
var SPEED: float = 50.0

func _ready() -> void:
	color_rect.self_modulate = color_1
	color_rect_2.self_modulate = color_2
	color_rect_3.self_modulate = color_3
	color_rect_4.self_modulate = color_4


func _on_emocion_1_area_entered(area: Area2D) -> void:
	if area.is_in_group("alegria"):
		print("Alegria")
		area.queue_free()
	else:
		print("mal")
		area.queue_free()


func _on_emocion_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("tristeza"):
		print("tristeza")
		area.queue_free()
	else:
		print("mal")
		area.queue_free()


func _on_emocion_3_area_entered(area: Area2D) -> void:
	if area.is_in_group("calma"):
		print("calma")
		area.queue_free()
	else:
		print("mal")
		area.queue_free()


func _on_emocion_4_area_entered(area: Area2D) -> void:
	if area.is_in_group("enojo"):
		print("enojo")
		area.queue_free()
	else:
		print("mal")
		area.queue_free()
