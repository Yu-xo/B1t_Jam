extends Node2D

@export var safe_scene_path := "res://Scenes/UI/selection_scene.tscn"

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	if not GameData.all_waves_cleared:
		print("Cannot enter safe zone yet — waves remain.")
		return

	print("Entering Safe Zone...")
	get_tree().change_scene_to_file(safe_scene_path)
