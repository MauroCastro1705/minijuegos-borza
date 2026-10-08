extends Node2D
#preso coleccionable
#Global.comida += 1
@onready var effect_2: CPUParticles2D = $effect2
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var effect: CPUParticles2D = $effect3


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.comida += 1
		Global.pick_up.emit()
		animated_sprite_2d.hide()
		audio_stream_player_2d.play()
		collision_shape_2d.call_deferred("set_disabled", true)
		effect.emitting = true
		await effect.finished
		queue_free()
