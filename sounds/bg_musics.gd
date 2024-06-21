extends Node2D

@onready var bg_music_1: AudioStreamPlayer = $BgMusic1
@onready var bg_music_2: AudioStreamPlayer = $BgMusic2
@onready var bg_music_3: AudioStreamPlayer = $BgMusic3

var playing_music: bool = false

func _process(delta):
	if not playing_music:
		play_musics()

func play_musics():
	playing_music = true
	bg_music_1.play()
	await bg_music_1.finished
	bg_music_2.play()
	await bg_music_2.finished
	bg_music_3.play()
	await bg_music_3.finished
	playing_music = false
