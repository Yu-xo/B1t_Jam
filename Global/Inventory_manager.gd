extends Node

@onready var player = get_tree().get_first_node_in_group("player")

var inventory = []

signal inv_update


func _ready() -> void:
	inventory.resize(5)
	
	
func add_items():
	inv_update.emit()
	
	

	
