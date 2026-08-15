extends Area2D


@export var speed: float = 200.0  # Velocidad del meteorito
var direction: Vector2 = Vector2.ZERO  # Dirección de movimiento

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Generar dirección aleatoria
	var angle = randf_range(0, TAU)  # TAU = 2 * PI
	direction = Vector2(cos(angle), sin(angle))
	
	# Opcional: rotar el sprite para que apunte en la dirección de movimiento
	rotation = angle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += direction * speed * delta
	
	# Eliminar si está muy lejos de la pantalla
	var viewport_size = get_viewport().size
	if abs(position.x) > viewport_size.x + 100 or abs(position.y) > viewport_size.y + 100:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		DamageNumbers.display_text("+1", self.position, Color.YELLOW, 25)
		Global.materia += 1
		Global.emit_signal("update")
		queue_free()

# Función para establecer dirección manualmente (opcional)
func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()

# Función para establecer velocidad (opcional)
func set_speed(new_speed: float) -> void:
	speed = new_speed
