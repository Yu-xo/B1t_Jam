extends Node2D

# === Node references ===
@onready var pointer: Sprite2D = $Path2D/PathFollow2D/Pointer
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D
@onready var bar: Sprite2D = $Bar
@onready var times_label: Label = $TimesLabel
@onready var timer: Timer = $Timer
@onready var time_limit_label: Label = $TimeLimitLabel
@onready var cooking_name_label: Label = $CookingNameLabel

@onready var perfect_rect: ColorRect = $Bar/PerfectRect
@onready var good_rect: ColorRect = $Bar/GoodRect
@onready var bad_rect: ColorRect = $Bar/BadRect

# === Configuration ===
const TOTAL_TIMES: int = 5
var current_time: int = 1

var move_speed: float = 1.4
var direction: int = 1

var score_ranges: Array = []
var time_left: float = 0.0

# === Cooking Titles (editable in Inspector) ===
@export var cooking_names: Array[String] = [
	"Ingredient Phase – Add in Order",
	"Mixing Phase – Stir Precisely",
	"Heat Phase – Control the Temperature",
	"Timing Phase – Avoid Overcooking",
	"Completion Phase – Judge the Quality"
]

# === Final score tracking ===
var score_list: Array[int] = []   # Store each round score (20/10/0)


# === Returns float 0~1 with two decimals ===
func rand2() -> float:
	return round(randf() * 100.0) / 100.0


func _ready() -> void:
	update_times_label()
	generate_random_ranges()

	time_left = timer.wait_time
	update_time_limit_label()
	update_cooking_name()

	timer.start()


func _process(delta: float) -> void:
	if timer.is_stopped():
		return

	# Pointer movement
	path_follow.progress_ratio += direction * move_speed * delta

	if path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		direction = -1
	elif path_follow.progress_ratio <= 0.0:
		path_follow.progress_ratio = 0.0
		direction = 1

	# Timer update
	time_left -= delta
	update_time_limit_label()

	if time_left <= 0.0:
		handle_time_up()


func _input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click()


# === Handles click scoring ===
func handle_click() -> void:
	timer.stop()

	var result: String = get_current_score()
	print("Cooking %d result: %s" % [current_time, result])

	# Save score
	score_list.append(score_name_to_value(result))

	if current_time >= TOTAL_TIMES:
		calc_final_score()
		return

	current_time += 1

	await get_tree().create_timer(0.1).timeout

	generate_random_ranges()

	time_left = timer.wait_time
	update_cooking_name()
	update_time_limit_label()

	timer.start()


# === Handles timeout score ===
func handle_time_up() -> void:
	timer.stop()

	time_left = 0.0
	update_time_limit_label()

	var result: String = get_current_score()
	print("Cooking %d result (time up): %s" % [current_time, result])

	# Save score
	score_list.append(score_name_to_value(result))

	if current_time >= TOTAL_TIMES:
		calc_final_score()
		return

	current_time += 1
	update_cooking_name()
	update_time_limit_label()

	generate_random_ranges()

	time_left = timer.wait_time
	timer.start()


func update_times_label() -> void:
	times_label.text = "%d / %d" % [current_time, TOTAL_TIMES]


func update_time_limit_label() -> void:
	time_limit_label.text = "%d" % int(ceil(time_left))


# === Update cooking phase title ===
func update_cooking_name() -> void:
	if current_time - 1 < cooking_names.size():
		cooking_name_label.text = cooking_names[current_time - 1]
	else:
		cooking_name_label.text = ""


# === Generate random ranges (fixed size, shuffled order) ===
func generate_random_ranges() -> void:
	score_ranges.clear()

	var perfect_len: float = 0.20
	var good_len: float = 0.30
	var bad_len: float = 0.50

	var max_offset: float = 1.0 - (perfect_len + good_len + bad_len)
	var offset: float = rand2() * max_offset

	var order = ["perfect", "good", "bad"]
	order.shuffle()

	var start: float = offset
	@warning_ignore("shadowed_variable_base_class")
	for name in order:
		var length: float
		match name:
			"perfect":
				length = perfect_len
			"good":
				length = good_len
			"bad":
				length = bad_len

		var end: float = start + length
		score_ranges.append({
			"name": name,
			"start": round(start * 100.0) / 100.0,
			"end": round(end * 100.0) / 100.0
		})

		start = end

	visualize_ranges()
	update_times_label()


# === Draws the colored score regions ===
func visualize_ranges() -> void:
	var bar_width: float = bar.texture.get_width()
	var bar_height: float = bar.texture.get_height()

	# Hide all first
	for rect in [perfect_rect, good_rect, bad_rect]:
		rect.visible = false

	for r in score_ranges:
		var start_x: float = r.start * bar_width
		var w: float = (r.end - r.start) * bar_width

		var rect: ColorRect
		match r.name:
			"perfect":
				rect = perfect_rect
			"good":
				rect = good_rect
			"bad":
				rect = bad_rect

		rect.position = Vector2(start_x - bar_width / 2, -bar_height / 2)
		rect.size = Vector2(w, bar_height)
		rect.visible = true


# === Returns name of score zone based on pointer ===
func get_current_score() -> String:
	var pos: float = path_follow.progress_ratio

	for r in score_ranges:
		if pos >= r.start and pos <= r.end:
			return r.name

	return "none"


# === Convert score name to numeric value ===
@warning_ignore("shadowed_variable_base_class")
func score_name_to_value(name: String) -> int:
	match name:
		"perfect":
			return 20
		"good":
			return 10
		"bad":
			return 0
	return 0


# === Final score calculation ===
func calc_final_score() -> void:
	var total := 0
	for s in score_list:
		total += s

	var average := float(total) / TOTAL_TIMES

	var final_quality: String
	if average >= 15:
		final_quality = "Excellent"
	elif average >= 8:
		final_quality = "Normal"
	else:
		final_quality = "Poor"

	print("==========================")
	print(" Final Cooking Score")
	print("==========================")
	print("Total Score: %d / %d" % [total, TOTAL_TIMES * 20])
	print("Average: %.1f" % average)
	print("Final Quality: %s" % final_quality)
	print("==========================")
