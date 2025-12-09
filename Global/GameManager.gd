extends Node

var blood_arr: Array = []
var bone_arr: Array = []
var max_progress: int = 10
var all_waves_cleared := false

var prevent_drops: bool = false

var completed_ingredients := {
	"salt": false,
	"oats": false,
	"milk": false,
	"honey": false,
}

var progress_values := {
	"salt": 0,
	"oats": 0,
	"milk": 0,
	"honey": 0,
}


var wave_paused: bool = false

func reset_all():
	blood_arr.clear()
	bone_arr.clear()

	for k in completed_ingredients:
		completed_ingredients[k] = false

	for k in progress_values:
		progress_values[k] = 0

	wave_paused = false  # reset wave pause state
