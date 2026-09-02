extends Node2D
class_name CustomTimer

# Señales
signal timer_completed()
signal timer_updated(time_left)

# Variables exportadas
@export var timer_duration: float = 60.0
@export var count_down: bool = true
@export var auto_start: bool = false

# Nodos
@onready var timer_label: Label = %timer_label
@onready var timer: Timer = Timer.new()

# Variables internas
var current_time: float = 0.0
var is_running: bool = false

func _ready() -> void:
	timer.wait_time = 0.1
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	reset()
	if auto_start:
		start()

func _on_timer_timeout() -> void:
	if not is_running:
		return
	
	if count_down:
		current_time -= 0.1
		if current_time <= 0:
			current_time = 0
			stop()
			timer_completed.emit()
	else:
		current_time += 0.1
		if current_time >= timer_duration:
			current_time = timer_duration
			stop()
			timer_completed.emit()
	
	actualizar_label()
	timer_updated.emit(current_time)

func actualizar_label() -> void:
	if timer_label == null:
		return
	
	var seconds = int(current_time)
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	var remaining_seconds = seconds % 60
	
	# Formato simple MM:SS
	timer_label.text = "%02d:%02d" % [minutes, remaining_seconds]

func start() -> void:
	if not is_running:
		is_running = true
		timer.start()

func stop() -> void:
	is_running = false
	timer.stop()

func reset() -> void:
	stop()
	if count_down:
		current_time = timer_duration
	else:
		current_time = 0.0
	actualizar_label()

func restart() -> void:
	reset()
	start()

func is_timer_running() -> bool:
	return is_running
