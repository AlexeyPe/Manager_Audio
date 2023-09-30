extends Node

# audio_id:int, audio_name:String
# if OS.has_feature("HTML5") -> data:Dictionary = {"howler_id":int}
signal on_ended_audio(audio_id, audio_name, data)

enum AudioName {
	pip, 
}

# AudioName.keys()[x] (String) => path to audio (String)
const _AudioName_to_audio_path = {
	"pip": "pip.mp3",
}

# AudioName key (String) => JavaScriptObject (Howl)
var _AudioName_to_howler_var = {}

# howl id (int) => AudioName (int)
var _howlid_to_AudioName = {}

var _js_howl_ended_callback = JavaScript.create_callback(self, "on_howl_ended")

func _ready():
	if !OS.has_feature("HTML5"): return
#	print("_ready")
	for _audio_name_key_id in _AudioName_to_audio_path.keys().size():
		var _audio_name_key = _AudioName_to_audio_path.keys()[_audio_name_key_id]
		var _audio_path = _AudioName_to_audio_path[_audio_name_key]
#		print("_ready _audio_name_key:%s, _audio_path:%s"%[_audio_name_key, _audio_path])
		var console = JavaScript.get_interface("console")
		var _js_howl_arg = JavaScript.create_object("Object")
		_js_howl_arg.src = _audio_path
		var _js_howl = JavaScript.create_object("Howl", _js_howl_arg)
		_js_howl.on('end', _js_howl_ended_callback)
		_AudioName_to_howler_var[_audio_name_key] = _js_howl
#		print("_AudioName_to_howler_var[_audio_name_key] = ", _js_howl)
#		console.log(_js_howl)

# return howl_id:int (audio player)
func audio_play(audio:int) -> int:
	if !OS.has_feature("HTML5"): return -900
#	print("audio_play")
	var howl_return = _AudioName_to_howler_var[AudioName.keys()[audio]].play()
	_howlid_to_AudioName[howl_return] = audio
	return howl_return

func set_global_volume(new:float):
	if !OS.has_feature("HTML5"): return
	new = clamp(new, 0.0, 1.0)
#	print("set_global_volume new ", new)
	var Howler = JavaScript.get_interface("Howler")
	Howler.volume(new)

func on_howl_ended(args:Array):
#	print("on_howl_ended args ", args)
	var howler_id:int = args[0]
	var audio_id:int = _howlid_to_AudioName[args[0]]
	var audio_name:String = AudioName.keys()[_howlid_to_AudioName[args[0]]]
	emit_signal("on_ended_audio", audio_id, audio_name, {"howler_id": howler_id})
