extends Node2D

# === Node references ===
@onready var pointer: Sprite2D = $Path2D/PathFollow2D/Pointer
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D
@onready var bar: Sprite2D = $Bar
@onready var times_label: Label = $TimesLabel
@onready var timer: Timer = $Timer

@onready var perfect_rect: ColorRect = $Bar/PerfectRect
@onready var good_rect: ColorRect = $Bar/GoodRect
@onready var bad_rect: ColorRect = $Bar/BadRect

# === Configuration ===
const TOTAL_TIMES: int = 5
var current_time: int = 1

var move_speed: float = 1.4
var direction: int = 1

var score_ranges: Array = []


# === Utility function: return a 0~1 float with 2 decimal places ===
func rand2() -> float:
	return round(randf() * 100.0) / 100.0


func _ready() -> void:
	update_times_label()
	generate_random_ranges()
	timer.start()


func _process(delta: float) -> void:
	if timer.is_stopped():
		return

	path_follow.progress_ratio += direction * move_speed * delta

	if path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		direction = -1
	elif path_follow.progress_ratio <= 0.0:
		path_follow.progress_ratio = 0.0
		direction = 1


func _input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		timer.stop()

		var result: String = get_current_score()
		print("Attempt %d result: %s" % [current_time, result])

		if current_time >= TOTAL_TIMES:
			print("Mini-game finished!")
			return

		current_time += 1
		update_times_label()

		await get_tree().create_timer(0.5).timeout

		generate_random_ranges()
		timer.start()


func update_times_label() -> void:
	times_label.text = "%d / %d" % [current_time, TOTAL_TIMES]


# === Generate random ranges (fixed proportions, random order and offset) ===
func generate_random_ranges() -> void:
	score_ranges.clear()

	# Range lengths (fixed)
	var perfect_len: float = 0.20
	var good_len: float = 0.30
	var bad_len: float = 0.50

	# Random total offset to ensure total length does not exceed 1
	var max_offset: float = 1.0 - (perfect_len + good_len + bad_len)
	var offset: float = rand2() * max_offset

	# Random order of ranges
	var order = ["perfect", "good", "bad"]
	order.shuffle()

	var start: float = offset
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
		score_ranges.append({"name": name, "start": round(start * 100.0) / 100.0, "end": round(end * 100.0) / 100.0})

		start = end

	print("This round ranges (fixed proportions):", score_ranges)

	# Visualize ranges
	visualize_ranges()


# === Visualize ranges on the bar ===
func visualize_ranges() -> void:
	var bar_width: float = bar.texture.get_width()
	var bar_height: float = bar.texture.get_height()

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

		# Adjust position: subtract Sprite center
		rect.position = Vector2(start_x - bar_width / 2, -bar_height / 2)
		rect.size = Vector2(w, bar_height)
		rect.visible = true


# === Get current score based on pointer position ===
func get_current_score() -> String:
	var pos: float = path_follow.progress_ratio

	for r in score_ranges:
		if pos >= r.start and pos <= r.end:
			return r.name

	return "none"
