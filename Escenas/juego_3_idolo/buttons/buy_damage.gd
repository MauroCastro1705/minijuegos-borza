extends Control
@onready var cost: Label = %cost
@onready var buy_button: Button = $buy_button
var inicial_value:int = 20 #costo del upgrade

func _ready() -> void:
	cost.text = str(inicial_value)

func _process(_delta: float) -> void:
	if Global.corriente < inicial_value:
		buy_button.disabled = true
	else:
		buy_button.disabled = false


func _on_buy_button_pressed() -> void:
	Global.corriente -= inicial_value
	Global.bobina_dmg += 5
	inicial_value += int(inicial_value * 1.7)
