extends Camera2D

@export var shake_intensity: float = 5.0
@export var shake_duration: float = 0.3

var shake_timer: float = 0.0
var shake_intensity_current: float = 0.0
var original_pos: Vector2
var offsets: Vector2 = Vector2.ZERO

func _ready():
	original_pos = position

func shake(intensity: float = -1.0, duration: float = -1.0):
	if intensity > 0:
		shake_intensity_current = intensity
	else:
		shake_intensity_current = shake_intensity
	
	if duration > 0:
		shake_timer = duration
	else:
		shake_timer = shake_duration

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		var progress = 1.0 - (shake_timer / shake_duration)
		var current_intensity = shake_intensity_current * (1.0 - progress)
		
		# Movimiento aleatorio pero suave
		offset.x = randf_range(-1, 1) * current_intensity
		offset.y = randf_range(-1, 1) * current_intensity
		
		# Limitar el offset para no salir de la pantalla
		position = original_pos + offsets
	else:
		position = original_pos
		offsets = Vector2.ZERO
