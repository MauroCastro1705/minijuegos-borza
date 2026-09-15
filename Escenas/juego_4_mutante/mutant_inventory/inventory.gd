extends Node2D
@onready var socket_spe: StaticBody2D = $sockets_mutante/socket_spe
@onready var socket_spe_2: StaticBody2D = $sockets_mutante/socket_spe2
@onready var socket_spe_3: StaticBody2D = $sockets_mutante/socket_spe3
@onready var socket_spe_4: StaticBody2D = $sockets_mutante/socket_spe4
@onready var socket_spe_5: StaticBody2D = $sockets_mutante/socket_spe5
@onready var socket_spe_6: StaticBody2D = $sockets_mutante/socket_spe6

@export var mutante:CharacterBody2D
var can_apply_mutagens:bool = true
@onready var apply_mutagen_button: Button = $apply_mutagen
@onready var mutant_info: Label = %mutant_info
@onready var sockets:Array = [socket_spe, socket_spe_2,socket_spe_3,socket_spe_4, socket_spe_5, socket_spe_6 ]

func _ready() -> void:
	Global.pick_up.connect(_update_label)
	_update_label()


func usar_mutagenos() -> void:
	if can_apply_mutagens:
		for i in sockets :
			i._on_something(mutante)
		
func _update_label() -> void:
	var danio_efectivo = int(mutante.fuerza * mutante.multi_danio)
	var vel_efectiva = mutante.velocidad * mutante.multi_velocidad
	var rango_efectivo = mutante.rango_ataque * mutante.multi_rango
	var atk_speed_efectivo = mutante.atk_speed * mutante.multi_atk_speed
	var defensa_pct := int(round(mutante.defensa * 100))

	mutant_info.text = (
		"Fuerza: %d\n" % danio_efectivo
		+ "Velocidad: %.0f\n" % vel_efectiva
		+ "Rango: %.0f\n" % rango_efectivo
		+ "Atk Speed: %.2f\n" % atk_speed_efectivo
		+ "DEF: %d%%\n" % defensa_pct
		+ "HP: %d / %d" % [int(mutante.current_health), int(mutante.max_health)]
	)
	if not can_apply_mutagens:
		apply_mutagen_button.disabled = true
	else: apply_mutagen_button.disabled = false
	


func _on_apply_mutagen_pressed() -> void:
	_update_label()
	usar_mutagenos()
