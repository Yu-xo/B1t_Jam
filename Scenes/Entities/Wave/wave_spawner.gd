extends Node2D

# ======================================================
# EXPORT VARIABLES
# ======================================================

@export var Basic_Nisse: PackedScene
@export var Range_Wiz: PackedScene
@export var Self_Dest_Wiz: PackedScene

@export var player: Node2D
@export var spawn_radius: float = 300.0
@export var min_spawn_radius: float = 100.0

@export var safe_scene_path: String = "res://Scenes/Game_Scenes/safe_zone.tscn"


# ======================================================
# ENEMY TYPE REGISTRY
# ======================================================

var enemy_info := {
	"Basic_Nisse": {"type": null, "number": 0},
	"Range_Wiz": {"type": null, "number": 0},
	"Self_Dest_Wiz": {"type": null, "number": 0}
}


# ======================================================
# WAVES
# ======================================================

@export var waves := [
	{ "Basic_Nisse": 3, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 4, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 6, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },
	{ "Basic_Nisse": 8, "Range_Wiz": 0, "Self_Dest_Wiz": 0 },  # <-- FIXED
	{ "Basic_Nisse": 10, "Range_Wiz": 0, "Self_Dest_Wiz": 0 }
]


var current_wave := 0
var total_to_spawn := 0
var total_dead := 0

var final_sent := false  # prevents duplicate teleport


# ======================================================
# READY
# ======================================================

func _ready():
	enemy_info["Basic_Nisse"].type = Basic_Nisse
	enemy_info["Range_Wiz"].type = Range_Wiz
	enemy_info["Self_Dest_Wiz"].type = Self_Dest_Wiz

	GameData.all_waves_cleared = false
	final_sent = false

	print("Starting wave progression...")
	start_next_wave()


# ======================================================
# START NEXT WAVE
# ======================================================

func start_next_wave():
	# All waves done → teleport
	if current_wave >= waves.size():
		_handle_all_waves_completed()
		return

	print("\n=== STARTING WAVE: %d ===" % (current_wave + 1))

	_setup_wave(enemy_info, waves[current_wave])
	_spawn_all_enemies()

	current_wave += 1






func _handle_all_waves_completed():
	if final_sent:
		return  # avoids double teleport

	final_sent = true
	GameData.all_waves_cleared = true

	print("\n=== ALL WAVES COMPLETED ===")
	print("Teleporting player to Safe Zone...")

	get_tree().paused = false

	# Disable ALL drops after waves end
	GameData.prevent_drops = true

	get_tree().change_scene_to_file(safe_scene_path)




func _setup_wave(dict, wave_data):
	for key in wave_data.keys():
		dict[key].number = wave_data[key]
		print("Wave setup:", key, "=", wave_data[key])



# SPAWNING


func _spawn_all_enemies():
	total_dead = 0
	total_to_spawn = 0

	for key in enemy_info:
		total_to_spawn += enemy_info[key].number

	print("Total enemies to spawn:", total_to_spawn)

	for key in enemy_info:
		var info = enemy_info[key]
		if info.type != null and info.number > 0:
			_spawn_enemy_type(info.type, info.number)


func _spawn_enemy_type(scene: PackedScene, count: int):
	for i in range(count):
		var enemy = scene.instantiate()
		add_child(enemy)

		if enemy.has_signal("is_dead"):
			enemy.is_dead.connect(_enemy_died)

		enemy.global_position = spawn_position_around_player()
		print("Spawned enemy at:", enemy.global_position)


func spawn_position_around_player() -> Vector2:
	var angle = randf() * TAU
	var radius = randf_range(min_spawn_radius, spawn_radius)
	return player.global_position + Vector2(cos(angle), sin(angle)) * radius



# ENEMY DEATH


func _enemy_died():
	total_dead += 1
	print("Enemy died: %d/%d" % [total_dead, total_to_spawn])

	# Wave complete → start next or teleport
	if total_dead >= total_to_spawn:
		print("Wave cleared!")
		start_next_wave()
