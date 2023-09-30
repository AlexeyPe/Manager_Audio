extends Control

func _ready():
	Manager_Audio.connect("on_ended_audio", self, "on_ended_audio")

func on_ended_audio(audio_id:int, audio_name:String, data:Dictionary):
	print("on_ended_audio(audio_id:%s, audio_name:%s, data:%s)"%[audio_id, audio_name, data])

func _on_Btn_Play_sound_1_pressed():
	print("_on_Btn_Play_sound_1_pressed")
	Manager_Audio.audio_play(Manager_Audio.AudioName.pip)
	pass # Replace with function body.


func _on_Slider_Howler_Global_Volume_drag_ended(value_changed):
	if value_changed:
		var slider:HSlider = get_node("CenterContainer/HBoxContainer/VBoxContainer3/HBoxContainer/Slider_Howler_Global_Volume")
		Manager_Audio.set_global_volume(slider.value)
