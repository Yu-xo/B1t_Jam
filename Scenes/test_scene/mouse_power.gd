extends Area2D

signal hit_target(body)
@onready var player: CharacterBody2D = $"../Player"

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		return
		
	if !body.die(): return
	emit_signal("hit_target", body)
	body.die()
