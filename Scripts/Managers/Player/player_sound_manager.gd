extends Node
class_name PlayerSoundManager

@export var music_audio_source: AudioStreamPlayer

func play_sound(sound: AudioStream, volume: float = 0.0):
	if not sound:
		return
	
	# Create a new AudioStreamPlayer instance
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Configure and play the sound
	audio_player.stream = sound
	audio_player.volume_db = volume
	audio_player.bus = "SFX"
	audio_player.play()
	
	# Clean up when finished
	audio_player.finished.connect(func(): audio_player.queue_free())

func play_sound_at_audio_source(audio_source: AudioStreamPlayer, sound: AudioStream, volume: float = 0.0):
	if not audio_source or not sound:
		return
	
	audio_source.stream = sound
	audio_source.volume_db = volume
	audio_source.play()

func play_music_track(music: AudioStream, volume: float = -10.0, fade_in: bool = false):
	if not music_audio_source or not music:
		return
	
	if fade_in:
		music_audio_source.volume_db = -80.0
		music_audio_source.stream = music
		music_audio_source.play()
		
		var tween = create_tween()
		tween.tween_property(music_audio_source, "volume_db", volume, 1.0)
	else:
		music_audio_source.stream = music
		music_audio_source.volume_db = volume
		music_audio_source.play()

func play_music(music_name: String, volume: float = -10.0, fade_in: bool = false):
	var music_path = SoundLibrary.Music.get(music_name)
	if music_path:
		var music = load(music_path)
		play_music_track(music, volume, fade_in)
	else:
		print("Music not found: ", music_name)

func stop_music(fade_out: bool = false):
	if not music_audio_source:
		return
	
	if fade_out:
		var tween = create_tween()
		tween.tween_property(music_audio_source, "volume_db", -80.0, 1.0)
		tween.tween_callback(music_audio_source.stop)
	else:
		music_audio_source.stop()

func set_music_volume(volume: float):
	if music_audio_source:
		music_audio_source.volume_db = volume

func set_sfx_volume(volume: float):
	# Set SFX bus volume instead
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, volume)
