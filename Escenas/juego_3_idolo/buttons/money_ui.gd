extends Control



@onready var label: Label = %Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var new_score: HBoxContainer = $new_score
@onready var new_value: Label = $new_score/new_value


func _ready() -> void:
	Global.enemy_died.connect(_animation)
	_update_label()
	
	
	
func _update_label():
	label.text = str(Global.corriente)
	
func _animation():
	new_score.show()
	new_value.text = "+" + str(Global.enemy_corriente)
	animation_player.play("update")
	await animation_player.animation_finished
	_update_label()
	new_score.hide()
