extends Node2D

@onready var hit_counter: Label = $CanvasLayer/hit_counter
var hits:int = 0
@onready var spawner: Area2D = $spawner

@onready var efecto_agua: CPUParticles2D = $efecto_agua
var agua_velocity:Vector2
@onready var orilla: Parallax2D = $Parallax2D
var orilla_velocity:Vector2

# Límites para la gravedad
const GRAVEDAD_MINIMA: float = 180.0
const GRAVEDAD_MAXIMA: float = 980.0
const REDUCCION_GRAVEDAD: float = 100.0

const ORILLA_MINIMA: float = 100.0
const ORILLA_MAXIMA: float = 355.0
const REDUCCION_ORILLA: float = 55.0

func _ready() -> void:
	Global.hit.connect(_on_hit)
	agua_velocity = Vector2(0, GRAVEDAD_MAXIMA)
	efecto_agua.gravity = agua_velocity
	
	orilla_velocity = Vector2(0, ORILLA_MAXIMA)
	orilla.autoscroll = orilla_velocity

func _on_hit():
	hits += 1
	reducir_velocidad()
	hit_counter.text = "hits: " + str(hits) + " velocity: " + str(agua_velocity.y)



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
