extends CharacterBody2D


@onready var barra_vida: HealthBar3 = $BarraVida_mutante
@onready var number_position: Marker2D = $Marker2D
var number_real_position
@onready var hurt_effect: CPUParticles2D = $hurt_effect
@onready var mutant_info: Label = %mutant_info

signal died

# --- Identidad y nombres ---
@export var nombre: String = "Test XC-047"
@export var nombres_disponibles: Array[String] = ["Fran Mutantear", "El ArtE", "La Furia v.015", "Moco rojo", "Claudio" , "Borza splinter 74" , "Ar3p4 Vol4t1L" ]

# --- Stats base (matchean con el GameManager) ---
var max_health: float = 60
var current_health: float
var fuerza: int = 5            # daño base
var velocidad: float = 100.0     # solo informativo en formato Pokémon
var defensa: float = 0.0         # 0.0 = sin reducción, 0.5 = 50% menos daño
const DEFENSA_MAX: float = 0.9

# Alias por compatibilidad con código viejo
var enemy_dmg: int:
	get: return fuerza
	set(value): fuerza = value

var is_dead: bool = false
var nombre_anterior: String = ""


func _ready() -> void:
	number_real_position = number_position.position
	current_health = max_health
	barra_vida.health_depleted.connect(_on_health_depleted)
	barra_vida.max_health = max_health
	barra_vida.current_health = current_health
	_actualizar_info()


func _physics_process(_delta: float) -> void:
	pass


# ------------------ RECIBIR DAÑO ------------------
func take_damage(damage: int) -> void:
	if is_dead:
		return

	var danio_final: int = int(round(damage * (1.0 - defensa)))
	danio_final = max(danio_final, 1)  # siempre al menos 1

	print("enemigo recibió daño: ", danio_final, " (original: ", damage, ")")
	number_real_position = number_position.global_position
	DamageNumbers.display_numbers_tesla(danio_final, number_real_position)
	hurt_effect.emitting = true
	DamageNumbers.flash_sprite(self)

	current_health -= danio_final
	if barra_vida:
		barra_vida.take_damage(danio_final)
	_actualizar_info()


func randomizar_nombre() -> void:
	if nombres_disponibles.is_empty():
		return

	var opciones := nombres_disponibles.duplicate()
	if not nombre_anterior.is_empty():
		opciones.erase(nombre_anterior)

	if opciones.is_empty():
		nombre = nombre_anterior if not nombre_anterior.is_empty() else nombres_disponibles.pick_random()
	else:
		nombre = opciones.pick_random()

	nombre_anterior = nombre
	_actualizar_info()


func _actualizar_info() -> void:
	if not is_instance_valid(mutant_info):
		return
	mutant_info.text = (
		"%s\n" % nombre
		+ "HP: %d / %d\n" % [int(current_health), int(max_health)]
		+ "Daño: %d\n" % fuerza
		+ "DEF: %d%%" % int(round(defensa * 100))
	)


func _on_health_depleted():
	if is_dead:
		return
	is_dead = true
	Global.enemy_died.emit()
	died.emit()
	barra_vida.hide()
	print("enemigo murio")
	queue_free()


# ------------------ ATACAR ------------------
func atacar(objetivo: Node2D) -> void:
	if is_dead:
		return
	if not is_instance_valid(objetivo):
		return

	var damage: int = int(fuerza)
	if objetivo.has_method("take_damage"):
		var direccion := (objetivo.global_position - global_position).normalized()
		var pos_original := global_position
		var distancia_lunge := 25.0

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)

		tween.tween_property(self, "global_position",
			pos_original + direccion * distancia_lunge, 0.08).set_ease(Tween.EASE_OUT)

		tween.tween_callback(func():
			objetivo.take_damage(damage)
			print("enemigo ataco por ", damage)
		)

		tween.tween_property(self, "global_position",
			pos_original, 0.15).set_ease(Tween.EASE_IN)
