extends AudioStreamPlayer

@export_category("Menu")
@export var menu_music: AudioStream
@export_range(0, 1.2, 0.1) var menu_volume: float
@export var menu_start: float
@export var menu_end: float

@export_category("Inside")
@export var inside_music: AudioStream
@export_range(0, 1.2, 0.1) var inside_volume: float
@export var inside_start: float
@export var inside_end: float

@export_category("Battle")
@export var battle_music: AudioStream
@export_range(0, 1.2, 0.1) var battle_volume: float
@export var battle_start: float
@export var battle_end: float

func _ready() -> void:
	stream = menu_music
	volume_linear = menu_volume
	play()

func _process(_delta: float) -> void:
	var duration = get_playback_position() + AudioServer.get_time_since_last_mix()
	var start = menu_start if stream == menu_music else (inside_start if stream == inside_music else battle_start)
	var end = menu_end if stream == menu_music else (inside_end if stream == inside_music else battle_end)
	if (stream.get_length() - duration < start + (stream.get_length() - end)):
		play()

func _change_music(_new_stream: AudioStream):
	self.create_tween().tween_property(self, "volume_linear", 0, 0.5).finished.connect(func():
		stop()
		stream = _new_stream
		volume_linear = menu_volume if stream == menu_music else (inside_volume if stream == inside_music else battle_volume)
		play()
		self.create_tween().tween_property(self, "volume_linear", 1, 0.5)
	)

## Shorthand for starting menu music
func play_menu():
	_change_music(menu_music)

## Shorthand for starting inside music
func play_inside():
	_change_music(inside_music)
	
## Shorthand for starting battle music
func play_battle():
	_change_music(battle_music)
