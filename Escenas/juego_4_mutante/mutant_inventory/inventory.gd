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


func set_items_locked(locked: bool) -> void:
	for socket in sockets:
		socket.set_interaction_locked(locked)
	heal_socket.set_interaction_locked(locked)



		
func _update_label() -> void:
	if not is_instance_valid(mutante) or not is_instance_valid(mutant_info):
		return

	var fuerza = mutante.get("fuerza")
	var multi_danio = mutante.get("multi_danio")
	var velocidad = mutante.get("velocidad")
	var multi_velocidad = mutante.get("multi_velocidad")
	var defensa = mutante.get("defensa")
	var crit_chance = mutante.get("crit_chance")
	var current_health = mutante.get("current_health")
	var max_health = mutante.get("max_health")

	if not fuerza is int and not fuerza is float:
		fuerza = 0
	if not multi_danio is int and not multi_danio is float:
		multi_danio = 1.0
	if not velocidad is int and not velocidad is float:
		velocidad = 0.0
	if not multi_velocidad is int and not multi_velocidad is float:
		multi_velocidad = 1.0
	if not defensa is int and not defensa is float:
		defensa = 0.0
	if not crit_chance is int and not crit_chance is float:
		crit_chance = 0.0
	if not current_health is int and not current_health is float:
		current_health = 0.0
	if not max_health is int and not max_health is float:
		max_health = 0.0

	var danio_efectivo = int(fuerza * multi_danio)
	var vel_efectiva = velocidad * multi_velocidad
	var defensa_pct := int(round(defensa * 100))
	var crit_chance_pct := int(round(crit_chance * 100))

	mutant_info.text = (
		"Fuerza: %d\n" % danio_efectivo
		+ "Velocidad: %.0f\n" % vel_efectiva
		+ "Critico: %d%%\n" % crit_chance_pct
		+ "DEF: %d%%\n" % defensa_pct
		+ "HP: %d / %d" % [int(current_health), int(max_health)]
	)
	if is_instance_valid(apply_mutagen_button):
		apply_mutagen_button.disabled = not can_apply_mutagens
	


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
