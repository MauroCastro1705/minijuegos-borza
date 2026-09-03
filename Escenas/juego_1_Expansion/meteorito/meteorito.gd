extends Area2D
#meteorito


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@export var speed: float = 200.0  # Velocidad del meteorito
var direction: Vector2 = Vector2.ZERO  # Dirección de movimiento
@onready var explosion: CPUParticles2D = $explosion
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Generar dirección aleatoria
	var angle = randf_range(0, TAU)  # TAU = 2 * PI
	direction = Vector2(cos(angle), sin(angle))
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
		call_deferred("disable_coll")
		DamageNumbers.display_text("+1", self.position, Color.YELLOW, 25)
		Global.materia += 1
		Global.emit_signal("update")
		Global.emit_signal("hit")
		explosion.emitting = true
		audio_stream_player.play()
		sprite_2d.hide()
		speed = 0
		await explosion.finished
		queue_free()
		
func disable_coll():
	collision_shape_2d.disabled = true

# Función para establecer dirección manualmente (opcional)
func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()

# Función para establecer velocidad (opcional)
func set_speed(new_speed: float) -> void:
	speed = new_speed
