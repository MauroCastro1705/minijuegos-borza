class_name DinoEnemy extends Node2D

signal died

@onready var texture_rect: TextureRect = $TextureRect
@onready var life_bar: ProgressBar = $life_bar
@onready var life_value: Label = $life_value
@onready var hurt_particle: CPUParticles2D = $hurt_particle
@onready var attack_area: Area2D = $Area2D

@export_range(1, 100000, 1) var life_amount: int = 500
@export_range(1.0, 500.0, 1.0) var movement_speed: float = 28.0
@export_range(1.0, 500.0, 1.0) var knockback_speed: float = 300.0
@export_range(1.0, 500.0, 1.0) var knockback_distance: float = 100.0

var current_health: int
var _texture_base_modulate: Color
var _hurt_flash_tween: Tween
var _is_dead: bool = false
var _is_attacking_player: bool = false
var _movement_stopped: bool = false
var _knockback_remaining: float = 0.0


func _ready() -> void:
	current_health = life_amount
	life_bar.max_value = life_amount
	_texture_base_modulate = texture_rect.modulate
	_update_health_ui()


func _physics_process(delta: float) -> void:
	if _is_dead or _movement_stopped or _is_attacking_player:
		return

	if _knockback_remaining > 0.0:
		var knockback_step := minf(_knockback_remaining, knockback_speed * delta)
		global_position.x += knockback_step
		_knockback_remaining -= knockback_step
		return

	global_position.x -= movement_speed * delta


func take_damage(damage: int) -> void:
	if damage <= 0 or _is_dead:
		return

	_is_attacking_player = false
	current_health = maxi(current_health - damage, 0)
	_update_health_ui()
	hurt_particle.restart()
	_flash_when_hit()
	if current_health == 0:
		_die()
	else:
		_knockback_remaining = knockback_distance


func set_attacking_player(is_attacking: bool) -> void:
	_is_attacking_player = is_attacking
	if is_attacking:
		_knockback_remaining = 0.0


func stop_moving() -> void:
	_movement_stopped = true
	_is_attacking_player = false
	_knockback_remaining = 0.0


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
	stop_moving()
	attack_area.monitoring = false
	texture_rect.hide()
	life_bar.hide()
	life_value.hide()
	died.emit()
