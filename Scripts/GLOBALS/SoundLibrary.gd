extends Node

enum SFX {
	LEVELUP,
	XPGAIN
}

enum MusicType {
	# Add music types here
}

# Dictionary that maps enum values to preloads
var SFXDict: Dictionary = {
	SFX.LEVELUP: preload("res://Assets/Audio/SFX/level_up.mp3"),
	SFX.XPGAIN: preload("res://Assets/Audio/SFX/xp_gain.mp3")
}

var Music: Dictionary = {
	# Add music here
}

func get_sfx(sfx_type: SFX) -> AudioStream:
	return SFXDict.get(sfx_type)

func get_music(music_type: MusicType) -> AudioStream:
	return Music.get(music_type)
