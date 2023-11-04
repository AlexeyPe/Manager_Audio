# res://addons/Demo/Demo.gd
extends Control

# export AudioName example
export(preload("res://addons/Manager_Audio/Manager_Audio.gd").AudioName) var btn_sound
var current_audio_music:Manager_Audio.Audio

func _ready():
	Manager_Audio.connect("on_ended_audio", self, "on_ended_audio")

func on_ended_audio(audio:Manager_Audio.Audio):
	print("on_ended_audio")
	if audio.audio_name == Manager_Audio.AudioName.test_music: current_audio_music.play()

func _on_Btn_Play_sound_pressed():
	print("_on_Btn_Play_sound_pressed")
	Manager_Audio.audio_play(btn_sound, 1.0)

func _on_Btn_Play_music_pressed():
	if current_audio_music == null or current_audio_music.is_ended: 
		print("current_audio_music == null ", current_audio_music == null)
		if current_audio_music != null:
			print("current_audio_music.is_ended ", current_audio_music.is_ended)
		current_audio_music = Manager_Audio.audio_play(Manager_Audio.AudioName.test_music, 1.0)
	else: current_audio_music.continue_audio()
	$CenterContainer/HBoxContainer/VBoxContainer/Btn_Stop_music.disabled = false
	$CenterContainer/HBoxContainer/VBoxContainer/Btn_Play_music.disabled = true

func _on_Btn_Stop_music_pressed():
	current_audio_music.pause_audio()
	$CenterContainer/HBoxContainer/VBoxContainer/Btn_Stop_music.disabled = true
	$CenterContainer/HBoxContainer/VBoxContainer/Btn_Play_music.disabled = false

func _on_Btn_AllStop_pressed():
	Manager_Audio.all_pause()

func _on_Btn_AllContinue_pressed():
	Manager_Audio.all_continue()

func _on_HSlider_drag_ended(value_changed:bool):
	if value_changed and current_audio_music != null:
		var slider:HSlider = $CenterContainer/HBoxContainer/VBoxContainer4/HBoxContainer/HSlider
		current_audio_music.set_volume(slider.value)
