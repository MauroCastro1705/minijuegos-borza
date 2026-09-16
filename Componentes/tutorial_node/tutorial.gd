extends Control

signal tutorial_finished

@onready var next_tutorial_button: Button = $next_tutorial_button
@onready var info: Label = %info
@onready var panel: Panel = $Panel


# Textos del tutorial (se pueden setear desde afuera)
var mensajes: Array[String] = []
var indice_actual: int = 0



func _ready() -> void:
	# Si no se cargaron mensajes desde afuera, mostramos uno por defecto
	if mensajes.is_empty():
		mensajes = ["Tutorial..."]
	
	_mostrar_mensaje_actual()


func _mostrar_mensaje_actual() -> void:
	info.text = mensajes[indice_actual]
	
	# Cambiamos el texto del botón en el último mensaje
	if indice_actual == mensajes.size() - 1:
		next_tutorial_button.text = "Cerrar"
	else:
		next_tutorial_button.text = "Continuar"


func _on_next_tutorial_button_pressed() -> void:
	indice_actual += 1
	
	if indice_actual >= mensajes.size():
		_cerrar_tutorial()
	else:
		_mostrar_mensaje_actual()


func _cerrar_tutorial() -> void:	
	tutorial_finished.emit()
	queue_free()


# Método estático para crear el tutorial fácilmente
static func crear(mensajes_tutorial: Array[String], parent: Node) -> Control:
	var escena = preload("res://Componentes/tutorial_node/tutorial.tscn")
	var instancia := escena.instantiate()
	instancia.mensajes = mensajes_tutorial
	parent.add_child(instancia)
	return instancia
