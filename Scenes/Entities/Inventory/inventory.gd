extends Control

# -------------------------
# UI EXPORTS
# -------------------------

@export var blood_count: RichTextLabel
@export var bone_count: RichTextLabel

@export var salt_name: RichTextLabel
@export var salt_amount: RichTextLabel
@export var salt_button: Button

@export var milk_name: RichTextLabel
@export var milk_amount: RichTextLabel
@export var milk_button: Button

@export var honey_name: RichTextLabel
@export var honey_amount: RichTextLabel
@export var honey_button: Button

@export var oats_name: RichTextLabel
@export var oats_amount: RichTextLabel
@export var oats_button: Button

# -------------------------
# Player inventory
# -------------------------
var blood_arr: Array = []
var bone_arr: Array = []

# Track which ingredient is completed
var completed_ingredients = {
	"salt": false,
	"oats": false,
	"milk": false,
	"honey": false,
}

# -------------------------
# Requirements
# -------------------------
var ingredient_requirements = {
	"salt": {"bones": 5, "blood": 3},
	"oats": {"bones": 7, "blood": 7},
	"milk": {"bones": 4, "blood": 10},
	"honey": {"bones": 7, "blood": 7},
}

func _ready():
	call_deferred("_connect_player_signal")
	_setup_ingredient_ui()
	_connect_buttons()
	update_inventory_ui()


# -------------------------
# PLAYER SIGNAL
# -------------------------
func _connect_player_signal():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.item_picked.connect(_on_player_item_picked)

func _on_player_item_picked(type):
	if type == "blood":
		blood_arr.append(1)
	elif type == "bone":
		bone_arr.append(1)

	update_inventory_ui()


# -------------------------
# UI SETUP
# -------------------------
func _setup_ingredient_ui():
	_set_ingredient_ui("salt", salt_name, salt_amount)
	_set_ingredient_ui("milk", milk_name, milk_amount)
	_set_ingredient_ui("honey", honey_name, honey_amount)
	_set_ingredient_ui("oats", oats_name, oats_amount)

func _set_ingredient_ui(key: String, name_label: RichTextLabel, amount_label: RichTextLabel):
	if completed_ingredients[key]:
		amount_label.text = "✔ Completed"
	else:
		var r = ingredient_requirements[key]
		amount_label.text = "Needs %s Bones + %s Blood Drops" % [r.bones, r.blood]


# -------------------------
# BUTTON SETUP
# -------------------------
func _connect_buttons():
	salt_button.pressed.connect(func(): _donate("salt", salt_amount, salt_button))
	milk_button.pressed.connect(func(): _donate("milk", milk_amount, milk_button))
	honey_button.pressed.connect(func(): _donate("honey", honey_amount, honey_button))
	oats_button.pressed.connect(func(): _donate("oats", oats_amount, oats_button))


# -------------------------
# DONATION LOGIC
# -------------------------
func _donate(key: String, ui_label: RichTextLabel, button: Button):
	var req = ingredient_requirements[key]

	# Check availability
	if bone_arr.size() < req.bones:
		print("Not enough bones for ", key)
		return
	if blood_arr.size() < req.blood:
		print("Not enough blood for ", key)
		return

	# Deduct bones
	for i in range(req.bones):
		bone_arr.pop_back()

	# Deduct blood
	for i in range(req.blood):
		blood_arr.pop_back()

	# Mark completed
	completed_ingredients[key] = true

	# Update UI text to "Completed ✔"
	ui_label.text = "✔ Completed"

	# Disable the button
	button.disabled = true

	print("Donated ingredients for: ", key)
	update_inventory_ui()


# -------------------------
# UPDATE INVENTORY UI
# -------------------------
func update_inventory_ui():
	blood_count.text = "Blood: %s" % blood_arr.size()
	bone_count.text =  "Bones: %s" % bone_arr.size()
