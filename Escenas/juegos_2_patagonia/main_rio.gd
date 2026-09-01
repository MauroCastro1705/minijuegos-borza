extends Node2D

@onready var hit_counter: Label = $CanvasLayer/hit_counter
var hits:int = 0
@onready var spawner: Area2D = $spawner

@onready var efecto_agua: CPUParticles2D = $efecto_agua
var agua_velocity:Vector2
@onready var orilla: Parallax2D = $Parallax2D
var orilla_velocity:Vector2
var score:int = 0
#combo
@onready var combo_label: Label = $CanvasLayer/combo_Label
@onready var combo_progress: ProgressBar = $CanvasLayer/combo_progress
@onready var score_label: Label = $CanvasLayer/score

# Sistema de combo
var combo_count: int = 0
var max_combo: int = 0
var combo_timer: Timer
var combo_timeout: float = 2.0  # Tiempo para mantener el combo (en segundos)
var combo_multiplier: float = 1.0  # Multiplicador actual
var last_pickup_time: float = 0.0


# Límites para la gravedad
const GRAVEDAD_MINIMA: float = 180.0
const GRAVEDAD_MAXIMA: float = 980.0
const REDUCCION_GRAVEDAD: float = 100.0

const ORILLA_MINIMA: float = 100.0
const ORILLA_MAXIMA: float = 355.0
const REDUCCION_ORILLA: float = 55.0

# Configuración de combo
const COMBO_MAXIMO: int = 20  # Combo máximo
const TIEMPO_COMBO_BASE: float = 2.0  # Tiempo base para mantener combo
const BONUS_POR_COMBO: float = 0.1  # Bonus de multiplicador por cada combo
const MULTIPLICADOR_MAXIMO: float = 3.0  # Multiplicador máximo

func _ready() -> void:
	Global.hit.connect(_on_hit)
	Global.pick_up.connect(_on_pickup)
	agua_velocity = Vector2(0, GRAVEDAD_MAXIMA)
	efecto_agua.gravity = agua_velocity
	
	orilla_velocity = Vector2(0, ORILLA_MAXIMA)
	orilla.autoscroll = orilla_velocity
	_set_up_combo()

func _set_up_combo():
	# Configurar timer para el combo
	combo_timer = Timer.new()
	combo_timer.wait_time = combo_timeout
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timeout)
	add_child(combo_timer)
	
	# Inicializar UI
	actualizar_ui_combo()
	calcular_puntaje()

func _on_hit():
	hits += 1
	reducir_velocidad()
	hit_counter.text = "hits: " + str(hits) + " velocity: " + str(agua_velocity.y)

func _on_pickup():
	# Logica de combo
	aumentar_combo()
	calcular_puntaje()
	
	# Reiniciar el timer del combo
	combo_timer.start()
	
	# Actualizar UI
	actualizar_ui_combo()

func aumentar_combo():
	# Incrementar combo
	combo_count += 1
	
	# Actualizar máximo combo
	if combo_count > max_combo:
		max_combo = combo_count
	
	# Calcular multiplicador basado en combo
	combo_multiplier = 1.0 + (combo_count - 1) * BONUS_POR_COMBO
	combo_multiplier = min(combo_multiplier, MULTIPLICADOR_MAXIMO)
	
	# Efecto visual de combo (opcional)
	mostrar_efecto_combo()

func calcular_puntaje():
	# Puntaje base + bonus por combo
	var puntos_base = 10
	var puntos_combo = int(puntos_base * combo_multiplier)
	score += puntos_combo
	score_label.text = "Score: " + str(score)
	
	print("Pickup! Combo: ", combo_count, " | Multiplicador: x", combo_multiplier, " | Puntos: ", puntos_combo)

func _on_combo_timeout():
	# El combo se ha perdido
	if combo_count > 0:
		print("Combo perdido! Combo: ", combo_count)
		
		# Resetear combo
		combo_count = 0
		combo_multiplier = 1.0
		actualizar_ui_combo()
		
		# Efecto visual de combo perdido (opcional)
		mostrar_efecto_combo_perdido()

func actualizar_ui_combo():
	# Actualizar label de combo
	combo_label.text = "Combo: x" + str(combo_multiplier).pad_decimals(1) + " (" + str(combo_count) + ")"
	
	# Actualizar barra de progreso del combo
	if combo_progress:
		combo_progress.max_value = COMBO_MAXIMO
		combo_progress.value = combo_count
		
		# Cambiar color según el nivel de combo
		if combo_count >= COMBO_MAXIMO:
			combo_progress.modulate = Color(1, 0.8, 0)  # Dorado
		elif combo_count >= COMBO_MAXIMO * 0.7:
			combo_progress.modulate = Color(1, 0.5, 0)  # Naranja
		elif combo_count >= COMBO_MAXIMO * 0.4:
			combo_progress.modulate = Color(0, 0.8, 0.2)  # Verde
		else:
			combo_progress.modulate = Color(0.3, 0.6, 1)  # Azul

func mostrar_efecto_combo():
	# Efecto visual cuando se obtiene combo
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Escalar el label de combo
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Cambiar color según combo
	var color = Color(1, 1, 1)
	if combo_count >= COMBO_MAXIMO:
		color = Color(1, 0.8, 0)  # Dorado
	elif combo_count >= COMBO_MAXIMO * 0.7:
		color = Color(1, 0.5, 0)  # Naranja
	elif combo_count >= COMBO_MAXIMO * 0.4:
		color = Color(0, 0.8, 0.2)  # Verde
	else:
		color = Color(0.3, 0.6, 1)  # Azul
	
	tween.tween_property(combo_label, "modulate", color, 0.1)

func mostrar_efecto_combo_perdido():
	# Efecto visual cuando se pierde el combo
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_IN)
	
	combo_label.modulate = Color(1, 0, 0)  # Rojo
	tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(combo_label, "modulate", Color(1, 1, 1), 0.3)

# Funciones adicionales útiles

func reiniciar_combo():
	combo_count = 0
	combo_multiplier = 1.0
	max_combo = 0
	combo_timer.stop()
	actualizar_ui_combo()
	print("Combo reiniciado")

func obtener_estado_combo() -> Dictionary:
	return {
		"combo_actual": combo_count,
		"max_combo": max_combo,
		"multiplicador": combo_multiplier,
		"tiempo_restante": combo_timer.time_left if combo_timer.is_stopped() == false else 0.0
	}


func reducir_velocidad():
	print("se redujo velocidad")
	reducir_velocidad_hielo()
	# Reducir gravedad con límite mínimo
	var nueva_gravedad_y = max(
		GRAVEDAD_MINIMA, 
		agua_velocity.y - REDUCCION_GRAVEDAD
	)
	agua_velocity = Vector2(0, nueva_gravedad_y)
	efecto_agua.gravity = agua_velocity
	
	# Reducir velocidad de orilla con límite mínimo
	var nueva_orilla_y = max(
		ORILLA_MINIMA, 
		orilla_velocity.y - REDUCCION_ORILLA
	)
	orilla_velocity = Vector2(0, nueva_orilla_y)
	orilla.autoscroll = orilla_velocity
	print("orilla:", orilla.autoscroll)
	print("particulas:", efecto_agua.gravity)

func aumentar_velocidad():
	print("se aumentó velocidad")
	
	# Aumentar gravedad con límite máximo
	var nueva_gravedad_y = min(
		GRAVEDAD_MAXIMA, 
		agua_velocity.y + REDUCCION_GRAVEDAD
	)
	agua_velocity = Vector2(0, nueva_gravedad_y)
	efecto_agua.gravity = agua_velocity
	
	# Aumentar velocidad de orilla con límite máximo
	var nueva_orilla_y = min(
		ORILLA_MAXIMA, 
		orilla_velocity.y + REDUCCION_ORILLA
	)
	orilla_velocity = Vector2(0, nueva_orilla_y)
	orilla.autoscroll = orilla_velocity
	
	print("orilla:", orilla.autoscroll)
	print("particulas:", efecto_agua.gravity)

func reducir_velocidad_hielo():
	# Reducir velocidad con límite mínimo de 0.5
	Global.hielo_speed = max(0.3, Global.hielo_speed - 0.1)
	print("hielo: ", Global.hielo_speed)
	
func aumentar_velocidad_hielo():
	# Aumentar velocidad con límite máximo de 1.0
	Global.hielo_speed = min(1.1, Global.hielo_speed + 0.1)
	print("hielo: ", Global.hielo_speed)
