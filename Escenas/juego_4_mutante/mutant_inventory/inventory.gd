extends Node2D
@onready var socket_spe: StaticBody2D = $sockets_mutante/socket_spe
@onready var socket_spe_2: StaticBody2D = $sockets_mutante/socket_spe2
@onready var socket_spe_3: StaticBody2D = $sockets_mutante/socket_spe3
@onready var socket_spe_4: StaticBody2D = $sockets_mutante/socket_spe4
@onready var socket_spe_5: StaticBody2D = $sockets_mutante/socket_spe5
@onready var socket_spe_6: StaticBody2D = $sockets_mutante/socket_spe6
@onready var heal_socket: StaticBody2D = $sockets_inventario/heal_socket

@export var mutante:CharacterBody2D
var can_apply_mutagens:bool = true
@onready var apply_mutagen_button: Button = $apply_mutagen
@onready var mutant_info: Label = %mutant_info
@onready var sockets:Array = [socket_spe, socket_spe_2,socket_spe_3,socket_spe_4, socket_spe_5, socket_spe_6 ]

func _ready() -> void:
	Global.pick_up.connect(_update_label)
	for socket in sockets:
		socket.set_stat_target(mutante)
	_update_label()



		
func _update_label() -> void:
	var danio_efectivo = int(mutante.fuerza * mutante.multi_danio)
	var vel_efectiva = mutante.velocidad * mutante.multi_velocidad
	var defensa_pct := int(round(mutante.defensa * 100))

	mutant_info.text = (
		"Fuerza: %d\n" % danio_efectivo
		+ "Velocidad: %.0f\n" % vel_efectiva
		+ "DEF: %d%%\n" % defensa_pct
		+ "HP: %d / %d" % [int(mutante.current_health), int(mutante.max_health)]
	)
	if not can_apply_mutagens:
		apply_mutagen_button.disabled = true
	else: apply_mutagen_button.disabled = false
	


func _on_apply_mutagen_pressed() -> void:
	usar_mutagenos()
	_update_label()
	
func usar_mutagenos() -> void:
	if can_apply_mutagens:
		for i in sockets :
			i._on_something(mutante)

func _on_dna_for_hp_pressed() -> void:
	if not heal_socket.has_item():
		print("no hay item para consumir")
		return

	# Curar al mutante
	mutante.heal(20)

	# Consumir el item
	var item_consumido = heal_socket.occupied_item
	if is_instance_valid(item_consumido):
		item_consumido.queue_free()

	# Limpiar el socket: referencia, color y colisión
	heal_socket.clear_item()  # ya pone occupied_item = null y color IDLE
	heal_socket.get_node("CollisionShape2D").set_deferred("disabled", false)

	_update_label()
