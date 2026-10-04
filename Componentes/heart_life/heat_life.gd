extends Node2D

@onready var heart_1: TextureRect = %heart_1
@onready var heart_2: TextureRect = %heart_2
@onready var heart_3: TextureRect = %heart_3
@onready var amount: Label = $Panel2/HBoxContainer/amount

var hearts: Array[TextureRect] = []
var current_life: int = 3

const DARK_COLOR := Color(0.3, 0.3, 0.3, 1.0)  # color "oscurecido"
const FULL_COLOR := Color(1, 1, 1, 1)

func _ready() -> void:
	# Se construye aquí porque los @onready ya están listos
	Global.pick_up.connect(_manzana)
	hearts = [heart_1, heart_2, heart_3]
	current_life = hearts.size()
	_update_hearts()
	amount.text = str(Global.materia)

func _manzana():
	amount.text = str(Global.materia)

func reduce_life() -> void:
	if current_life <= 0:
		return
	current_life -= 1
	_update_hearts()
	if current_life == 0:
		_on_no_life()  # opcional: game over

func _update_hearts() -> void:
	for i in hearts.size():
		# Los últimos corazones se oscurecen primero (de derecha a izquierda)
		if i < current_life:
			hearts[i].modulate = FULL_COLOR
		else:
			hearts[i].modulate = DARK_COLOR

func _on_no_life() -> void:
	print("¡Sin vida!")
	# aquí puedes emitir señal, reiniciar, etc.
