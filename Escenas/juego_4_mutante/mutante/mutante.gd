extends CharacterBody2D
# Mutante Auto Battler
@onready var barra_vida: HealthBar3 = $BarraVida_mutante

@onready var detection_area: Area2D = $detection_area
@onready var sprite: Sprite2D = $Sprite2D  # opcional, para voltear el sprite
signal died
var is_dead:bool = false
var max_health:float = 50
var current_health: float
# --- Stats base ---
var fuerza: int = 15          # daño base del ataque
var atk_speed: float = 1     #
var velocidad: float = 150.0  # velocidad de movimiento

# --- Stats derivados / runtime ---
var rango_ataque: float = 40.0   # distancia a la que puede golpear
var objetivo_actual: Node2D = null
var puede_atacar: bool = true
var en_batalla: bool = false

# Multiplicadores de mejora (se irán incrementando durante la partida)
var multi_danio: float = 1.0
var multi_velocidad: float = 1.0
var multi_atk_speed: float = 1.0
var bonus_vida: int = 0

# Temporizador interno para el cooldown de ataque
var _cooldown_ataque: float = 0.0


func _ready() -> void:
	# Conectar señales del Area2D para detectar enemigos
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	current_health = max_health
	barra_vida.health_depleted.connect(_on_health_depleted)
	barra_vida.max_health = max_health
	barra_vida.current_health = current_health


func _physics_process(delta: float) -> void:
	# Reducir cooldown de ataque
	if _cooldown_ataque > 0.0:
		_cooldown_ataque -= delta
	else:
		puede_atacar = true

	if not en_batalla:
		return

	# Si no hay objetivo o el objetivo murió, buscar uno nuevo
	if not is_instance_valid(objetivo_actual):
		objetivo_actual = _buscar_enemigo_mas_cercano()
		if objetivo_actual == null:
			velocity = Vector2.ZERO
			move_and_slide()
			return

	# Lógica de combate
	var distancia := global_position.distance_to(objetivo_actual.global_position)

	if distancia <= rango_ataque:
		# Estamos en rango: detenerse y atacar
		velocity = Vector2.ZERO
		move_and_slide()
		_intentar_atacar()
	else:
		# Movernos hacia el enemigo
		var direccion := (objetivo_actual.global_position - global_position).normalized()
		velocity = direccion * velocidad * multi_velocidad
		move_and_slide()
		_voltear_sprite(direccion.x)


# ------------------ ATAQUE ------------------
func _intentar_atacar() -> void:
	if not puede_atacar or not is_instance_valid(objetivo_actual):
		return
	puede_atacar = false
	# Intervalo entre ataques (atk_speed = ataques por segundo efectivos)
	_cooldown_ataque = 1.0 / max(atk_speed * multi_atk_speed, 0.01)
	_atacar(objetivo_actual)


func _atacar(objetivo: Node2D) -> void:
	var damage: int = int(fuerza * multi_danio)
	if objetivo.has_method("take_damage"):
		objetivo.take_damage(damage)

func take_damage(damage: int) -> void:
	if is_dead:
		return
	print("mutante recibió daño: ", damage)
	current_health -= damage
	if barra_vida:
		barra_vida.take_damage(damage)

# ------------------ DETECCIÓN ------------------
func _buscar_enemigo_mas_cercano() -> Node2D:
	var enemigos := get_tree().get_nodes_in_group("enemigo")
	var mas_cercano: Node2D = null
	var dist_min: float = INF
	for e in enemigos:
		if not is_instance_valid(e):
			continue
		var d := global_position.distance_to(e.global_position)
		if d < dist_min:
			dist_min = d
			mas_cercano = e
	return mas_cercano


func _on_detection_body_entered(body: Node2D) -> void:
	# Si entra un enemigo y no tenemos objetivo, lo tomamos
	if body.is_in_group("enemigo") and not is_instance_valid(objetivo_actual):
		objetivo_actual = body


func _on_detection_body_exited(body: Node2D) -> void:
	if body == objetivo_actual:
		objetivo_actual = null

func _on_health_depleted():
	if is_dead:
		return
	is_dead = true
	died.emit()
	barra_vida.hide()
	print("mutante murio")
	queue_free()



# ------------------ CONTROL DE BATALLA ------------------
func iniciar_batalla() -> void:
	en_batalla = true
	objetivo_actual = _buscar_enemigo_mas_cercano()

func detener_batalla() -> void:
	en_batalla = false
	objetivo_actual = null
	velocity = Vector2.ZERO


# ------------------ UTILIDADES ------------------
func _voltear_sprite(dir_x: float) -> void:
	if sprite and dir_x != 0:
		sprite.flip_h = dir_x < 0
		

# ------------------ MEJORAS ------------------
func mejorar_fuerza(cantidad: float) -> void:
	multi_danio += cantidad

func mejorar_velocidad(cantidad: float) -> void:
	multi_velocidad += cantidad

func mejorar_atk_speed(cantidad: float) -> void:
	multi_atk_speed += cantidad
