extends Node2D
# Game Manager - Combate por turnos estilo Pokémon



@export var base_enemy: PackedScene

# --- Incrementos por ronda (ajustables desde el inspector) ---
@export var incremento_hp: float = 0.15          # +15% HP por ronda
@export var incremento_fuerza: float = 0.10      # +10% fuerza por ronda
@export var incremento_velocidad: float = 0.05   # +5% velocidad por ronda
@export var incremento_defensa: float = 0.03     # +3% defensa acumulada por ronda
@export var delay_spawn_enemigo: float = 1.0     # pausa antes de spawnear al siguiente
@onready var dna_loot: Node2D = $DNA_loot

@onready var reference_rect: ReferenceRect = $ReferenceRect
@onready var inventory: Node2D = $Inventory
@onready var enemy_mutant: CharacterBody2D = $Enemy_mutant
@onready var mutante: CharacterBody2D = $Mutante
@onready var item_tooltip: Panel = $CanvasLayer/ItemTooltip
@onready var timer_for_attaks: Timer = $Timer_for_attaks
@onready var item_spawner: ItemSpawner = $ItemSpawner
@onready var tuto: Control = $tuto
@onready var game_over_screen: Node2D = $game_over_screen
@onready var canvas_layer: CanvasLayer = $CanvasLayer

# --- Estado del combate ---
enum Turno { JUGADOR, ENEMIGO }
var turno_actual: Turno = Turno.JUGADOR
var batalla_activa: bool = false

@export var tiempo_entre_ataques: float = 0.8

# --- Progresión acumulada del enemigo ---
var ronda_actual: int = 0
var _hp_multi: float = 1.0
var _fuerza_multi: float = 1.0
var _velocidad_multi: float = 1.0
var _defensa_bonus: float = 0.0

# --- Spawn ---
var _pos_spawn_enemigo: Vector2
var _spawneando_enemigo: bool = false

var tutorial_mensajes:Array[String] = [
		"Bienvenido al laboratorio de M enterprises, aqui crearas y mejoraras al sujeto de prueba",
		"En la parte inferior tenes varios espacios para guardar, instalar o consumir ADN",
		"Deberas combatir con tu sujeto de pruba contra otros, luego de cada batalla podras colocar nuevos ADN en tu mutante para mejorar",
		"Los Mutantes pelean automaticamente, Usa el mouse para jugar!"
	]

func _ready() -> void:
	canvas_layer.show()
	game_over_screen.hide()
	set_tutorial_text()
	tuto.show()
	Global.drag_limits = reference_rect.get_global_rect()
	item_spawner.item_spawned.connect(_on_item_spawned)
	Global.player_died.connect(_player_died)

	# Guardar la posición inicial del enemigo para futuros spawns
	if is_instance_valid(enemy_mutant):
		_pos_spawn_enemigo = enemy_mutant.global_position
	else:
		push_warning("No hay Enemy_mutant inicial en la escena")

	# Configurar el timer
	timer_for_attaks.one_shot = true
	timer_for_attaks.wait_time = tiempo_entre_ataques
	if not timer_for_attaks.timeout.is_connected(_on_timer_for_attaks_timeout):
		timer_for_attaks.timeout.connect(_on_timer_for_attaks_timeout)

	# Conectar muerte de ambos mutantes
	if mutante.has_signal("died"):
		mutante.died.connect(_on_mutante_aliado_muerto)
	if enemy_mutant.has_signal("died"):
		enemy_mutant.died.connect(_on_mutante_enemigo_muerto)

func set_tutorial_text():
	tuto.set_mensajes(tutorial_mensajes)


func _on_start_button_pressed() -> void:
	inventory.can_apply_mutagens = false
	inventory.set_items_locked(true)
	iniciar_batalla()


func _player_died() -> void:
	inventory.can_apply_mutagens = true
	inventory.set_items_locked(false)
	detener_batalla()


# ---------------- CONTROL DE BATALLA ----------------
func iniciar_batalla() -> void:
	if batalla_activa or _spawneando_enemigo:
		return
	if not is_instance_valid(mutante) or not is_instance_valid(enemy_mutant):
		push_warning("Faltan mutantes para iniciar batalla")
		return
	batalla_activa = true
	mutante.en_batalla = true
	turno_actual = Turno.JUGADOR
	_siguiente_turno()


func detener_batalla() -> void:
	batalla_activa = false
	mutante.en_batalla = false
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

	timer_for_attaks.start()


func _atacar_con(atacante: Node, defensor: Node) -> void:
	if not is_instance_valid(atacante) or not is_instance_valid(defensor):
		return
	if atacante.has_method("atacar"):
		atacante.atacar(defensor)
	elif atacante.has_method("_atacar"):
		atacante._atacar(defensor)
	else:
		push_warning("El atacante no tiene método 'atacar': %s" % atacante.name)


func _on_timer_for_attaks_timeout() -> void:
	_siguiente_turno()


# ---------------- PROGRESIÓN DEL ENEMIGO ----------------
func _guardar_y_mejorar_stats() -> void:
	# Guardar los stats del enemigo que acaba de morir
	if is_instance_valid(enemy_mutant):
		var stats_guardados := {
			"max_health": enemy_mutant.max_health,
			"fuerza": enemy_mutant.fuerza,
			"velocidad": enemy_mutant.velocidad,
			"defensa": enemy_mutant.defensa
		}
		print("Stats del enemigo derrotado (ronda %d): %s" % [ronda_actual, stats_guardados])

	# Acumular progresión para la próxima ronda
	ronda_actual += 1
	_hp_multi *= (1.0 + incremento_hp)
	_fuerza_multi *= (1.0 + incremento_fuerza)
	_velocidad_multi *= (1.0 + incremento_velocidad)
	_defensa_bonus = min(_defensa_bonus + incremento_defensa, 0.9)

	print(">>> Ronda %d | HP x%.2f | DMG x%.2f | SPD x%.2f | DEF +%.2f" % [
		ronda_actual, _hp_multi, _fuerza_multi, _velocidad_multi, _defensa_bonus
	])


func _crear_nuevo_enemigo() -> void:
	if base_enemy == null:
		push_warning("base_enemy no está asignado en el inspector")
		return

	_spawneando_enemigo = true
	batalla_activa = false
	timer_for_attaks.stop()

	# Pausa dramática antes de spawnear
	if delay_spawn_enemigo > 0.0:
		await get_tree().create_timer(delay_spawn_enemigo).timeout

	# Instanciar el nuevo enemigo
	var nuevo := base_enemy.instantiate()

	nuevo.max_health = int(nuevo.max_health * _hp_multi)
	nuevo.fuerza = int(nuevo.fuerza * _fuerza_multi)
	nuevo.velocidad = nuevo.velocidad * _velocidad_multi
	nuevo.defensa = min(nuevo.defensa + _defensa_bonus, 0.9)

	# Posicionar donde estaba el original
	nuevo.global_position = _pos_spawn_enemigo

	# Meter a la escena
	add_child(nuevo)

	# Actualizar referencia y reconectar señal
	enemy_mutant = nuevo as CharacterBody2D
	if enemy_mutant.has_signal("died"):
		enemy_mutant.died.connect(_on_mutante_enemigo_muerto)

	print("Nuevo enemigo spawneado → HP: %d | Fuerza: %d | Vel: %.1f | DEF: %.2f" % [
		enemy_mutant.max_health, enemy_mutant.fuerza,
		enemy_mutant.velocidad, enemy_mutant.defensa
	])

	_spawneando_enemigo = false
	# El jugador debe pulsar Start de nuevo para la siguiente ronda.
	# Si prefieres auto-iniciar, descomenta esto:
	# iniciar_batalla()


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
	spawn_dna(4)
	# Guardar stats y acumular progresión
	_guardar_y_mejorar_stats()

	on_victoria()

	# Spawnear al siguiente enemigo (más fuerte)
	_crear_nuevo_enemigo()


# ---------------- EXTENSIONES ----------------
func on_victoria() -> void:
	print("¡Victoria! Ronda %d superada" % ronda_actual)
	inventory.can_apply_mutagens = true
	inventory.set_items_locked(false)
	# TODO: mostrar UI de victoria, sumar recompensa, etc.

func on_derrota() -> void:
	print("Derrota en ronda %d..." % ronda_actual)
	inventory.can_apply_mutagens = true
	inventory.set_items_locked(false)
	# TODO: mostrar UI de derrota, reiniciar, etc.
	game_over_screen.show()


# ---------------- UTILIDADES ----------------
func resetear_progreso() -> void:
	ronda_actual = 0
	_hp_multi = 1.0
	_fuerza_multi = 1.0
	_velocidad_multi = 1.0
	_defensa_bonus = 0.0
	print("Progresión del enemigo reseteada")
	
func spawn_dna(level: int) -> void:
	var dna_items = dna_loot.get_dna_loot(level)
	item_spawner.spawn_items(dna_items)

func _on_item_spawned(item: Item) -> void:
	item.tooltip_requested.connect(item_tooltip._on_item_tooltip_requested)
	item.tooltip_hidden.connect(item_tooltip._on_item_tooltip_hidden)


func _on_volver_pressed() -> void:
	TransitionManager.change_scene("res://Escenas/juego_4_mutante/main_menu/menu_mutante.tscn")
