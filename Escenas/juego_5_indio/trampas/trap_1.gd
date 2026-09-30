extends Node2D
@export var trap_dmg:int = 15
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var timer: Timer = $Timer

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(trap_dmg)
		collision_shape_2d.set_deferred("disabled", true)
		timer.start()


func _on_timer_timeout() -> void:
	collision_shape_2d.disabled = false
