extends Control
@onready var click_dmg: Label = %click_dmg
@onready var coil_dmg: Label = %coil_dmg

func _ready() -> void:
	Global.buy_upgrade.connect(_update_info)
	_update_info()




func _update_info():
	click_dmg.text = "Tesla Click Dmg: " + str(int(Global.click_damage))
	coil_dmg.text = "Tesla Coil Dmg: " + str(int(Global.bobina_dmg))
