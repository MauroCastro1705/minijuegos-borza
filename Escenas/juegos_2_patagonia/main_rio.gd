extends Node2D
@onready var hit_counter: Label = $CanvasLayer/hit_counter
var hits:int = 0

func _ready() -> void:
	Global.hit.connect(_on_hit)
	
	
func _on_hit():
	hits += 1
	hit_counter.text = "hits:" + str(hits)
