extends Node2D
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var tuto: Control = $CanvasLayer/tuto
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $Player/AudioStreamPlayer2D
var show_tuto:bool = true
@onready var player: Player = $Player
@onready var vhs_efecto: ColorRect = $CanvasLayer/vhs_efecto

@onready var game_over_screen: Node2D = $CanvasLayer/game_over

var tutorial_mensajes:Array[String] = [
		"Estas en la carcel del Dios prision Barbazul",
		"Tenes que rescatar a otros prisioneros como vos",
		"Encontra tu Strato roja para ayudarte en el camino y cuidado con las trampas",
		"Las manzanas firmes te guiaran en el camino, usa WASD para moverte y Espacio para saltar",
		"Ya lo intentaste varias veces, pero esta vez, por fin, la prision te va a gustar"
	]

func _ready() -> void:
	canvas_layer.show()
	vhs_efecto.show()
	set_tutorial_text()
	game_over_screen.hide()
	player.is_dead = false
	show_tuto = Global.show_tuto
	if show_tuto:
		tuto.show()
		tuto.connect("tutorial_finished", _tutorial_termino)
	else:
		tuto.hide()


func set_tutorial_text():
	tuto.set_mensajes(tutorial_mensajes)
	
func _tutorial_termino():
	show_tuto = false
	Global.show_tuto = false


func _on_audio_stream_player_2d_finished() -> void:
	audio_stream_player_2d.play()


func _on_restart_pressed() -> void:
	Global.materia = 0
	get_tree().reload_current_scene()


func _on_death_fall_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player.is_dead = true
		game_over_screen.show()
