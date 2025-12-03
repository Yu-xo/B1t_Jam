extends Node2D

@export var Basic_Nisse: PackedScene
@export var Range_Wiz: PackedScene
@export var Self_Dest_Wiz: PackedScene

@export var player: Node2D
@export var spawn_radius: float = 300.0
@export var min_spawn_radius: float = 100.0

var enemy_info := {
	"Basic_Nisse":     {"type": null, "number": 0},
	"Range_Wiz":     {"type": null, "number": 0},
	"Self_Dest_Wiz": {"type": null, "number": 0}
}

@export var waves := [
	{ "Basic_Nisse": 3, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 4, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 4, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 6, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 8, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 10, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 12, "Range_Wiz": 0, "Self_Dest_Wiz": 0 }
]

var current_wave := 0
var working: bool = false
var wave_working: bool = true
var total_to_spawn := 0
var total_dead := 0

func _ready():
	enemy_info["Basic_Nisse"].type = Basic_Nisse
	enemy_info["Range_Wiz"].type = Range_Wiz
	enemy_info["Self_Dest_Wiz"].type = Self_Dest_Wiz
	print("Starting first wave.")
	start_next_wave()

func _process(_delta):
	if not wave_working and Input.is_action_just_pressed("ui_accept"):  # Space by default in Godot
		resume_wave()

func start_next_wave():
	if current_wave >= waves.size():
		print("All waves finished!")
		return

	if not wave_working:
		print("Wave is paused. Waiting for player to resume...")
		return

	print("\n=== STARTING WAVE:", current_wave + 1, "===")
	_setup_wave(enemy_info, waves[current_wave])
	_spawn_all_enemies()
	current_wave += 1

func resume_wave():
	if current_wave >= waves.size():
		print("All waves finished!")
		return
	print("Player resumed the wave.")
	wave_working = true
	start_next_wave()

func _setup_wave(dict, wave_data):
	for key in wave_data.keys():
		dict[key].number = wave_data[key]
		print("Wave setup:", key, "Number:", wave_data[key])

func _spawn_all_enemies():
	total_to_spawn = 0
	total_dead = 0
	working = true

	for key in enemy_info.keys():
		total_to_spawn += enemy_info[key].number

	print("Total enemies to spawn:", total_to_spawn)

	for key in enemy_info.keys():
		var data = enemy_info[key]
		if data.type != null and data.number > 0:
			print("Spawning", data.number, key)
			_spawn_enemy_type(data.type, data.number)

func _spawn_enemy_type(scene: PackedScene, count: int):
	for i in range(count):
		var e = scene.instantiate()
		add_child(e)
		if e.has_signal("is_dead"):
			e.is_dead.connect(_enemy_died)
		else:
			push_warning("Enemy scene does not have 'is_dead' signal!")
		e.global_position = spawn_position_around_player()
		print("Spawned enemy at:", e.global_position)

func spawn_position_around_player() -> Vector2:
	if player == null:
		push_warning("Spawner: player is not assigned!")
		return Vector2.ZERO

	var min_distance_between_enemies = 50
	var max_attempts = 1000
	var pos: Vector2

	for attempt in range(max_attempts):
		var angle = randf() * TAU
		var radius = randf_range(min_spawn_radius, spawn_radius)
		pos = player.global_position + Vector2(cos(angle), sin(angle)) * radius

		var safe = true
		for child in get_children():
			if child == player:
				continue
			if "CharacterBody2D" in child.get_class():
				if child.global_position.distance_to(pos) < min_distance_between_enemies:
					safe = false
					break
		if safe:
			return pos
	return pos

func _enemy_died():
	total_dead += 1
	print("Enemy died. Total dead:", total_dead, "/", total_to_spawn)

	if total_dead >= total_to_spawn:
		working = false
		wave_working = false  # Pause wave after clearing
		print("Wave cleared! Press Space to continue...")
