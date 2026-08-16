extends Area2D

@export var orbit_radius: float = 200.0  # Radio de la órbita
@export var orbit_speed: float = 1.0    # Velocidad de rotación (radianes/segundo)
@export var start_angle: float = 0.0    # Ángulo inicial

var center: Vector2 = Vector2.ZERO      # Centro de la órbita
var current_angle: float = 0.0

func _ready() -> void:
	# Establecer el centro en la posición actual
	center = position
	current_angle = start_angle
	
	# Actualizar posición inicial
	update_position()

func _process(delta: float) -> void:
	# Incrementar el ángulo
	current_angle += orbit_speed * delta
	
	# Actualizar posición en la órbita
	update_position()

func update_position() -> void:
	# Calcular posición en el círculo
	var x = center.x + cos(current_angle) * orbit_radius
	var y = center.y + sin(current_angle) * orbit_radius
	position = Vector2(x, y)
	
	# Rotar el sprite para que mire en la dirección del movimiento
	rotation = current_angle + PI / 2

# Función para cambiar el centro de órbita
func set_center(new_center: Vector2) -> void:
	center = new_center

# Función para cambiar el radio
func set_orbit_radius(new_radius: float) -> void:
	orbit_radius = new_radius
