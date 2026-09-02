extends Node2D
@export var SPEED:float = 200
@onready var effect: CPUParticles2D = $effect
@onready var texture_rect: TextureRect = $TextureRect
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

func _process(delta: float) -> void:
	position.y += delta * SPEED

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.pick_up.emit()
		texture_rect.hide()
		
		# Deshabilitar el collision shape de forma segura con call_deferred
		collision_shape_2d.call_deferred("set_disabled", true)
		
		effect.emitting = true
		await effect.finished
		queue_free()
