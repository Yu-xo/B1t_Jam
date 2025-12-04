extends AudioStreamPlayer

@export_category("Menu")
@export var menu_music: AudioStream
@export var menu_start: float
@export var menu_end: float

@export_category("Inside")
@export var inside_music: AudioStream
@export var inside_start: float
@export var inside_end: float

@export_category("Battle")
@export var battle_music: AudioStream
@export var battle_start: float
@export var battle_end: float

func _ready() -> void:
	stream = menu_music
	play()

func _process(_delta: float) -> void:
	var duration = get_playback_position() + AudioServer.get_time_since_last_mix()
	if (stream.get_length() - duration < menu_start + (stream.get_length() - menu_end)):
		play()
	if (Input.is_action_just_pressed("down")):
		_change_music(menu_music)

func _change_music(_new_stream: AudioStream):
	self.create_tween().tween_property(self, "volume_linear", 0, 0.5).finished.connect(func():
		stop()
		stream = _new_stream
		play()
		self.create_tween().tween_property(self, "volume_linear", 1, 0.5)
	)
	
