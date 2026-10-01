extends Node2D

@onready var effect: CPUParticles2D = $effect
@onready var texture_rect: TextureRect = $TextureRect
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var effect_2: CPUParticles2D = $effect2



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.pick_up.emit()
		texture_rect.hide()
		audio_stream_player_2d.play()
		collision_shape_2d.call_deferred("set_disabled", true)
		effect.emitting = true
		await effect.finished
		queue_free()
