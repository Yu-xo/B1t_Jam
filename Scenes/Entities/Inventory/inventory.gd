extends Control

# ====================================================================
# EXPORTS – UI ELEMENTS
# ====================================================================

@export var blood_count: RichTextLabel
@export var bone_count: RichTextLabel

@export var salt_name: RichTextLabel
@export var salt_amount: RichTextLabel
@export var salt_button: Button
@export var salt_bar: TextureProgressBar

@export var milk_name: RichTextLabel
@export var milk_amount: RichTextLabel
@export var milk_button: Button
@export var milk_bar: TextureProgressBar

@export var honey_name: RichTextLabel
@export var honey_amount: RichTextLabel
@export var honey_button: Button
@export var honey_bar: TextureProgressBar

@export var oats_name: RichTextLabel
@export var oats_amount: RichTextLabel
@export var oats_button: Button
@export var oats_bar: TextureProgressBar

@onready var move_to_cooking_game: Button = $Move_to_cooking_game
@onready var ritual_status_label: RichTextLabel = $RitualStatus 

@export var fill_duration := 0.3
@export var bounce_scale := Vector2(1.2, 1.2)
@export var bounce_duration := 0.12

@export var ingredient_requirements := {
	"salt": {"bones": 5, "blood": 3},
	"milk": {"bones": 4, "blood": 10},
	"honey": {"bones": 7, "blood": 7},
	"oats": {"bones": 7, "blood": 7},
}

# Quick alias to GameData arrays & maps
var blood_arr := GameData.blood_arr
var bone_arr := GameData.bone_arr
var completed := GameData.completed_ingredients
var progress := GameData.progress_values

# For convenience
var max_progress :float= GameData.max_progress


func _ready():
	visible = false                      # starts hidden, shown by Player when E is pressed
	add_to_group("inventory_ui")

	_setup_bars_from_gamedata()
	_setup_ingredient_text()
	_connect_buttons()
	update_inventory_ui()
	_check_all_completed()


func _process(delta: float) -> void:
	# Keep counts refreshed even if items picked while UI is open
	update_inventory_ui()


	if Input.is_action_just_pressed("open_inventory"):
		visible = true
	if Input.is_action_just_pressed("close_inventory"):
		visible = false


func _setup_bars_from_gamedata():
	# Set max values
	salt_bar.max_value = max_progress
	milk_bar.max_value = max_progress
	honey_bar.max_value = max_progress
	oats_bar.max_value = max_progress

	# Apply saved progress
	salt_bar.value = progress["salt"]
	milk_bar.value = progress["milk"]
	honey_bar.value = progress["honey"]
	oats_bar.value = progress["oats"]


func _setup_ingredient_text():
	_set_ingredient_ui("salt", salt_name, salt_amount)
	_set_ingredient_ui("milk", milk_name, milk_amount)
	_set_ingredient_ui("honey", honey_name, honey_amount)
	_set_ingredient_ui("oats", oats_name, oats_amount)


func _set_ingredient_ui(key: String, name_label: RichTextLabel, amount_label: RichTextLabel):
	name_label.text = key.capitalize()

	if completed[key]:
		amount_label.text = "[center][color=lime]Completed[/color][/center]"
	else:
		var req = ingredient_requirements[key]
		amount_label.text = "Needs %s Bones + %s Blood Drops" % [req.bones, req.blood]


func _connect_buttons():
	salt_button.pressed.connect(func(): _donate("salt", salt_amount, salt_button, salt_bar))
	milk_button.pressed.connect(func(): _donate("milk", milk_amount, milk_button, milk_bar))
	honey_button.pressed.connect(func(): _donate("honey", honey_amount, honey_button, honey_bar))
	oats_button.pressed.connect(func(): _donate("oats", oats_amount, oats_button, oats_bar))

	# Apply disabled state from GameData
	salt_button.disabled = completed["salt"]
	milk_button.disabled = completed["milk"]
	honey_button.disabled = completed["honey"]
	oats_button.disabled = completed["oats"]



# DONATION LOGIC + ANIMATIONS


func _donate(key: String, ui_label: RichTextLabel, button: Button, bar: TextureProgressBar):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("No player found.")
		return

	# Only allow donating in safe ritual zone
	if not player.in_safe_zone:
		print("You must be in the ritual zone to donate.")
		return

	if completed[key]:
		print("%s already completed." % key)
		return

	var req = ingredient_requirements[key]

	# Check resources from GameData arrays
	if bone_arr.size() < req.bones or blood_arr.size() < req.blood:
		print("Not enough resources for %s" % key)
		return

	# Deduct bones
	for i in range(req.bones):
		if bone_arr.is_empty(): break
		bone_arr.pop_back()

	# Deduct blood
	for i in range(req.blood):
		if blood_arr.is_empty(): break
		blood_arr.pop_back()

	# Update progress value and animate bar
	progress[key] = max_progress
	_animate_bar(bar, progress[key])
	_bounce_bar(bar)

	# Mark ingredient completed
	completed[key] = true
	ui_label.text = "[center][color=lime]Completed[/color][/center]"
	button.disabled = true

	update_inventory_ui()
	_check_all_completed()

	print("Donated for %s | Blood: %d, Bones: %d" % [key, blood_arr.size(), bone_arr.size()])


func _animate_bar(bar: TextureProgressBar, new_value: float):
	var t = create_tween()
	t.tween_property(bar, "value", new_value, fill_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _bounce_bar(bar: TextureProgressBar):
	pass



# INVENTORY COUNTS


func update_inventory_ui():
	blood_count.text = "Blood: [b]%s[/b]" % blood_arr.size()
	bone_count.text = "Bones: [b]%s[/b]" % bone_arr.size()



# RITUAL UNLOCK SYSTEM


func _check_all_completed():
	for key in completed.keys():
		if not completed[key]:
			move_to_cooking_game.disabled = true
			if is_instance_valid(ritual_status_label):
				ritual_status_label.text = "[center][color=red]Ritual Locked[/color][/center]"
			return

	move_to_cooking_game.disabled = false
	if is_instance_valid(ritual_status_label):
		ritual_status_label.text = "[center][color=lime]Ritual Unlocked![/color][/center]"


func _on_Move_to_cooking_game_pressed():
	if move_to_cooking_game.disabled:
		print("Finish all rituals first!")
		return

	get_tree().change_scene_to_file("res://CookingGame.tscn")
