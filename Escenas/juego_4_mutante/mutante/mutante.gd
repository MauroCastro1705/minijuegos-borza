extends CharacterBody2D
# Mutante Auto Battler
@onready var barra_vida: HealthBar3 = $BarraVida_mutante
@onready var sprite: Sprite2D = $Sprite2D
signal died
var is_dead: bool = false
var max_health: float = 50
var current_health: float

# --- Stats base ---
var fuerza: int = 15
var velocidad: float = 150.0
var multi_danio: float = 1.0
var multi_velocidad: float = 1.0

var defensa: float = 0.0
const DEFENSA_MAX: float = 0.9
var bonus_vida: int = 0

var puede_atacar: bool = true
var en_batalla: bool = false

const STR_POR_ITEM: float = 0.10
const AGI_POR_ITEM: float = 0.10
const INT_POR_ITEM: float = 0.10
const DEF_POR_ITEM: float = 0.05
const HP_POR_ITEM: int    = 10




func _ready() -> void:

	current_health = max_health
	barra_vida.health_depleted.connect(_on_health_depleted)
	barra_vida.max_health = max_health
	barra_vida.current_health = current_health



func _physics_process(_delta: float) -> void:
	pass

# ------------------ ATAQUE ------------------

func atacar(objetivo: Node2D) -> void:
	if not is_instance_valid(objetivo):
		return

	var damage: int = int(fuerza * multi_danio)
	if objetivo.has_method("take_damage"):
		# Dirección hacia el objetivo
		var direccion := (objetivo.global_position - global_position).normalized()
		var pos_original := global_position
		var distancia_lunge := 25.0  # cuánto se lanza hacia adelante

		# --- Animación tipo Pokémon (lunge) ---
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)

		# 1. Lanzarse hacia adelante rápido
		tween.tween_property(self, "global_position",
			pos_original + direccion * distancia_lunge, 0.08).set_ease(Tween.EASE_OUT)

		# 2. Aplicar daño justo en el impacto
		tween.tween_callback(func():
			objetivo.take_damage(damage)
			print("mutante ataco")
		)

		# 3. Volver a la posición original
		tween.tween_property(self, "global_position",
			pos_original, 0.15).set_ease(Tween.EASE_IN)

func take_damage(damage: int) -> void:
	if is_dead:
		return
	var danio_final: int = int(round(damage * (1.0 - defensa)))
	danio_final = max(danio_final, 1)
	print("mutante recibió daño: ", danio_final, " (original: ", damage, ")")
	DamageNumbers.flash_sprite(self)
	DamageNumbers.display_numbers(danio_final, global_position)
	current_health -= danio_final
	if barra_vida:
		barra_vida.take_damage(danio_final)

func _on_health_depleted():
	if is_dead:
		return
	is_dead = true
	died.emit()
	barra_vida.hide()
	print("mutante murio")
	queue_free()







# ------------------ MEJORAS ------------------
func mejorar_fuerza(cantidad: float) -> void:
	multi_danio += cantidad

func mejorar_velocidad(cantidad: float) -> void:
	multi_velocidad += cantidad

func mejorar_defensa(cantidad: float) -> void:
	defensa = min(defensa + cantidad, DEFENSA_MAX)

func mejorar_vida(cantidad: int) -> void:
	max_health += cantidad
	current_health += cantidad
	if barra_vida:
		barra_vida.max_health = max_health
		barra_vida.current_health = current_health


# ------------------ APLICAR ITEM ------------------
func aplicar_item(item: ItemData) -> void:
	if item == null:
		push_warning("aplicar_item: item nulo")
		return

	match item.type:
		ItemData.ItemType.STR:
			mejorar_fuerza(STR_POR_ITEM)
		ItemData.ItemType.AGI:
			mejorar_velocidad(AGI_POR_ITEM)
		ItemData.ItemType.INT:
			pass
		ItemData.ItemType.DEF:
			mejorar_defensa(DEF_POR_ITEM)
		ItemData.ItemType.HP:
			mejorar_vida(HP_POR_ITEM)
		ItemData.ItemType.SP:
			pass
		_:
			push_warning("Tipo de item no manejado: %s" % item.type)
