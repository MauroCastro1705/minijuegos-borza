extends Node2D

@onready var mesh: MeshInstance2D = $MeshInstance2D

@export var marker: Marker2D
@onready var particle: CPUParticles2D = $CPUParticles2D
@onready var explosion: CPUParticles2D = $explosion
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var color_1: Color = Color.DARK_RED
var color_2: Color = Color.BLUE_VIOLET
var color_3: Color = Color.DARK_GREEN
var color_4: Color = Color.DARK_GOLDENROD
@onready var cara_1: TextureRect = $cara_enojo
@onready var cara_2: TextureRect = $cara_alegria
@onready var cara_3: TextureRect = $cara_3
@onready var cara_4: TextureRect = $cara_4

var emociones: Array = []
var faces:Array = []
@export var SPEED: float = 50


var emocion_1 = {
	COLOR = color_1,
	GRUPO = "alegria",
}
var emocion_2 = {
	COLOR = color_2,
	GRUPO = "tristeza",
}
var emocion_3 = {
	COLOR = color_3,
	GRUPO = "calma",
}
var emocion_4 = {
	COLOR = color_4,
	GRUPO = "enojo",
}
var actual_face 
# Opcional: guardar la emoción elegida para consultarla luego
var emocion_actual: Dictionary
var choque:bool = false
func _ready() -> void:
	particle.emitting = true
	emociones = [emocion_1, emocion_2, emocion_3, emocion_4]
	faces = [cara_1,cara_2,cara_3,cara_4]
	actual_face = faces.pick_random()
	actual_face.show()
	emocion_actual = emociones.pick_random()

	# Color + grupo según la misma emoción elegida
	mesh.self_modulate = emocion_actual.COLOR
	particle.self_modulate = emocion_actual.COLOR
	explosion.self_modulate = emocion_actual.COLOR
	add_to_group(emocion_actual.GRUPO)

func _process(delta: float) -> void:
	if marker == null:
		return

	var to_marker: Vector2 = marker.global_position - global_position
	var dist: float = to_marker.length()
	if not choque:
		if dist <= SPEED * delta:
			global_position = marker.global_position
			set_process(false)
			return

		global_position += to_marker.normalized() * SPEED * delta
	
func efecto_colision():
	# Forma correcta: set_deferred en la propiedad
	collision_shape_2d.set_deferred("disabled", true)
	print("efecto")
	choque = true
	explosion.emitting = true
	particle.emitting = false
	mesh.hide()
	actual_face.hide()
	
	await explosion.finished
	queue_free()
