extends Node2D
# Game Manager - Combate por turnos estilo Pokémon

@onready var reference_rect: ReferenceRect = $ReferenceRect
@onready var inventory: Node2D = $Inventory
@onready var enemy_mutant: CharacterBody2D = $Enemy_mutant
@onready var mutante: CharacterBody2D = $Mutante
@onready var item_tooltip: Panel = $CanvasLayer/ItemTooltip
@onready var item: Item = $Item
@onready var timer_for_attaks: Timer = $Timer_for_attaks

# --- Estado del combate ---
enum Turno { JUGADOR, ENEMIGO }
var turno_actual: Turno = Turno.JUGADOR
var batalla_activa: bool = false

@export var tiempo_entre_ataques: float = 0.8   # pausa entre ataques


func _ready() -> void:
	Global.drag_limits = reference_rect.get_global_rect()
	item.tooltip_requested.connect(item_tooltip._on_item_tooltip_requested)
	item.tooltip_hidden.connect(item_tooltip._on_item_tooltip_hidden)
	Global.player_died.connect(_player_died)

	# Configurar el timer como "one shot" para control de turnos
	timer_for_attaks.one_shot = true
	timer_for_attaks.wait_time = tiempo_entre_ataques
	if not timer_for_attaks.timeout.is_connected(_on_timer_for_attaks_timeout):
		timer_for_attaks.timeout.connect(_on_timer_for_attaks_timeout)

	# Conectar muerte de ambos mutantes (si tienen la señal)
	if mutante.has_signal("died"):
		mutante.died.connect(_on_mutante_aliado_muerto)
	if enemy_mutant.has_signal("died"):
		enemy_mutant.died.connect(_on_mutante_enemigo_muerto)


func _on_start_button_pressed() -> void:
	inventory.can_apply_mutagens = false
	iniciar_batalla()


func _player_died() -> void:
	inventory.can_apply_mutagens = true
	detener_batalla()


# ---------------- CONTROL DE BATALLA ----------------
func iniciar_batalla() -> void:
	if batalla_activa:
		return
	if not is_instance_valid(mutante) or not is_instance_valid(enemy_mutant):
		push_warning("Faltan mutantes para iniciar batalla")
		return
	batalla_activa = true
	turno_actual = Turno.JUGADOR
	_siguiente_turno()


func detener_batalla() -> void:
	batalla_activa = false
	timer_for_attaks.stop()


func _siguiente_turno() -> void:
	if not batalla_activa:
		return
	if not is_instance_valid(mutante) or not is_instance_valid(enemy_mutant):
		return

	# Comprobar muerte antes de atacar
	if mutante.current_health <= 0:
		_on_mutante_aliado_muerto()
		return
	if enemy_mutant.current_health <= 0:
		_on_mutante_enemigo_muerto()
		return

	# Ejecutar ataque según el turno
	if turno_actual == Turno.JUGADOR:
		_atacar_con(mutante, enemy_mutant)
		turno_actual = Turno.ENEMIGO
	else:
		_atacar_con(enemy_mutant, mutante)
		turno_actual = Turno.JUGADOR

	# Pausa antes del próximo ataque
	timer_for_attaks.start()


func _atacar_con(atacante: Node, defensor: Node) -> void:
	if not is_instance_valid(atacante) or not is_instance_valid(defensor):
		return
	# Acepta tanto `atacar` como `_atacar` para no romper nada
	if atacante.has_method("atacar"):
		atacante.atacar(defensor)
	elif atacante.has_method("_atacar"):
		atacante._atacar(defensor)
	else:
		push_warning("El atacante no tiene método 'atacar': %s" % atacante.name)


func _on_timer_for_attaks_timeout() -> void:
	_siguiente_turno()


# ---------------- CALLBACKS DE MUERTE ----------------
func _on_mutante_aliado_muerto() -> void:
	if not batalla_activa:
		return
	batalla_activa = false
	timer_for_attaks.stop()
	on_derrota()


func _on_mutante_enemigo_muerto() -> void:
	if not batalla_activa:
		return
	batalla_activa = false
	timer_for_attaks.stop()
	on_victoria()


# ---------------- ESTAS SON LAS QUE EXTENDÉS A TU GUSTO ----------------
func on_victoria() -> void:
	print("¡Victoria!")
	inventory.can_apply_mutagens = true
	# TODO: mostrar UI, dar recompensa, pasar a la siguiente ronda, etc.

func on_derrota() -> void:
	print("Derrota...")
	inventory.can_apply_mutagens = true
	# TODO: mostrar UI de derrota, reiniciar, etc.
