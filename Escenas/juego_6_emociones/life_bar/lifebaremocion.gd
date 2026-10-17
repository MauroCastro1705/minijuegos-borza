extends Control

@onready var panel: Panel = %Panel
@onready var panel_2: Panel = %Panel2
@onready var panel_3: Panel = %Panel3
@onready var panel_4: Panel = %Panel4
@onready var panel_5: Panel = %Panel5

var life: int = 5
var panels: Array[Panel] = []
signal life_ended
const GREY := Color(0.4, 0.4, 0.4, 1.0)
const NORMAL := Color(1, 1, 1, 1)

func _ready() -> void:
	panels = [panel, panel_2, panel_3, panel_4, panel_5]
	life = panels.size()

func reduce_life() -> void:
	if life <= 1:
		life_ended.emit()
		return
	life -= 1
	panels[life].modulate = GREY
