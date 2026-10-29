class_name DinoEnemy extends Node2D

signal died

@onready var texture_rect: TextureRect = $TextureRect
@onready var life_bar: ProgressBar = $life_bar
@onready var life_value: Label = $life_value
@onready var hurt_particle: CPUParticles2D = $hurt_particle

@export_range(1, 100000, 1) var life_amount: int = 500

var current_health: int
var _texture_base_modulate: Color
var _hurt_flash_tween: Tween
var _is_dead: bool = false


func _ready() -> void:
	current_health = life_amount
	life_bar.max_value = life_amount
	_texture_base_modulate = texture_rect.modulate
	_update_health_ui()


func take_damage(damage: int) -> void:
	if damage <= 0 or _is_dead:
		return

	current_health = maxi(current_health - damage, 0)
	_update_health_ui()
	hurt_particle.restart()
	_flash_when_hit()
	if current_health == 0:
		_die()


func _update_health_ui() -> void:
	life_bar.value = current_health
	life_value.text = "%d/%d" % [current_health, life_amount]


func _flash_when_hit() -> void:
	if _hurt_flash_tween != null and _hurt_flash_tween.is_running():
		_hurt_flash_tween.kill()

	texture_rect.modulate = _texture_base_modulate
	_hurt_flash_tween = create_tween()
	_hurt_flash_tween.tween_property(
		texture_rect, "modulate", Color(1.0, 0.35, 0.35, _texture_base_modulate.a), 0.04
	)
	_hurt_flash_tween.tween_property(
		texture_rect, "modulate", _texture_base_modulate, 0.12
	)


func _die() -> void:
	_is_dead = true
	texture_rect.hide()
	life_bar.hide()
	life_value.hide()
	died.emit()
