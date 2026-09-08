extends Control
#buy health
#repair_coil

@onready var cost: Label = %cost
@onready var buy_button: Button = $buy_button
var inicial_value:int = 10 #costo del upgrade
@export var bobina:StaticBody2D
@export var heal_value:float = 25

func _ready() -> void:
	cost.text = str(inicial_value)

func _process(_delta: float) -> void:
	if Global.corriente < inicial_value:
		buy_button.disabled = true
	else:
		buy_button.disabled = false


func _on_buy_button_pressed() -> void:
	Global.corriente -= inicial_value
	bobina.repair_coil(heal_value)
	#Global.bobina_dmg += 5
	inicial_value = int(inicial_value * 1.3)
	Global.buy_upgrade.emit()
	cost.text = str(inicial_value)
