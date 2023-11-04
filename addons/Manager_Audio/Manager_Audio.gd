extends Node

# audio:Audio
signal on_ended_audio(audio)
signal __js_decodeAudioData_callback() # private signal..

var _print_debug:bool = true
const _print:String = "Addon:ManagerAudio"

enum AudioName {
	pip, 
	test_music
}

# AudioName.keys()[x] (String) => path to audio (String)
const _AudioName_to_audio_path:Dictionary = {
	"pip": "res://audio/pip.mp3",
	"test_music": "res://audio/test_music_cc0.ogg"
}

# AudioName => js_AudioBuffer (https://developer.mozilla.org/ru/docs/Web/API/AudioBuffer)
var _js_AudioName_to_js_AudioBuffer:Dictionary = {}

# AudioName => [Audio] (Audio._js_audio != null and Audio._godot_audio == null)
var _js_audio_pool = {}
# id:int => Audio
var all_audio = []

var all_stop:bool = false

var js_audio_context
var js_console:JavaScriptObject
var js_decodeAudioData_callback = JavaScript.create_callback(self, "js_decodeAudioData_callback")
var _current_js_decodeAudioData_AudioBuffer:JavaScriptObject # not use

class Audio:
	var is_ended:bool
	var is_playing:bool
	var is_pause:bool = false
	var pause_time:float = -1
	var audio_name:int
	var volume:float
	var _js_audio:JavaScriptObject
	var _js_audio_ended_callback = JavaScript.create_callback(self, "_js_audio_ended_callback")
	var _godot_audio:AudioStreamPlayer
	func _js_audio_ended_callback(args:Array):
		print("_js_audio_ended_callback")
		is_playing = false
		is_pause = false
		is_ended = true
		Manager_Audio.emit_signal("on_ended_audio", self)
	func _init(_audio_name:int, audio:Dictionary):
		audio_name = _audio_name
		is_playing = true
		is_ended = false
		is_pause = false
		if audio.has("_godot_audio"):
			_godot_audio = audio["_godot_audio"]
			volume = db2linear(_godot_audio.volume_db)
			yield(_godot_audio,"finished")
			if is_pause == false:
				is_playing = false
				is_ended = true
				_godot_audio.queue_free()
				_godot_audio = null
				Manager_Audio.emit_signal("on_ended_audio", self)
		if audio.has("_js_audio"):
			_js_audio = audio["_js_audio"]
			volume = _js_audio.volume
			_js_audio.addEventListener("ended", _js_audio_ended_callback)
	func play():
		if is_playing: return
		is_playing = true
		is_ended = false
		is_pause = false
		if _js_audio == null:
			if _godot_audio != null:
				_godot_audio.queue_free()
			
			_godot_audio = AudioStreamPlayer.new()
			_godot_audio.stream = load(Manager_Audio._AudioName_to_audio_path[Manager_Audio.AudioName.keys()[audio_name]])
			_godot_audio.volume_db = linear2db(volume)
			Manager_Audio.add_child(_godot_audio)
			_godot_audio.play()
			yield(_godot_audio,"finished")
			if is_pause == false:
				is_playing = false
				is_ended = true
				Manager_Audio.emit_signal("on_ended_audio", self)
		else:
			_js_audio.play()
	func set_volume(new:float):
		new = clamp(new, 0.0, 1.0)
		volume = new
		if _godot_audio != null:
			_godot_audio.volume_db = linear2db(volume)
		if _js_audio != null:
			_js_audio.volume = volume
	func pause_audio():
		if is_ended or !is_playing: return
		is_pause = true
		if _godot_audio != null:
			pause_time = _godot_audio.get_playback_position()
			_godot_audio.stop()
		if _js_audio != null:
			pause_time = _js_audio.currentTime
			_js_audio.pause()
	func continue_audio():
		is_pause = false
		if _godot_audio != null:
			_godot_audio.play()
			_godot_audio.seek(pause_time)
			yield(_godot_audio,"finished")
			if is_pause == false:
				is_playing = false
				is_ended = true
				_godot_audio.queue_free()
				_godot_audio = null
				Manager_Audio.emit_signal("on_ended_audio", self)
				pause_time = -1
		if _js_audio != null: 
			_js_audio.play()
			pause_time = -1

func _check_func_valid(function_name:String, args:Array) -> bool:
	var result:bool = false
	result = OS.has_feature("HTML5")
	print("%s _check_func_valid(function_name:%s, args:%s)"%[_print, function_name, args])
	return result

func _ready():
	if OS.has_feature("HTML5"):
		if _print_debug: print("%s _ready(), OS has_feature('HTML5') - the addon works, for audio the Web Audio API is used"%[_print])
		# Web Audio Api/AudioContext предназначен для управления и воспроизведения всех звуков
		js_audio_context = JavaScript.create_object("AudioContext")
		js_console = JavaScript.get_interface("console")
		
		# Для каждого звука нужно создать AudioBuffer, это загрузит аудио в память
		# AudioBuffer создаётся методами AudioContext.decodeAudioData() или AudioContext.createBuffer()
		# С помощью AudioBufferSourceNode можно послушать данные из AudioBuffer
		yield(load_all_audio(), "completed")
		for key in _js_AudioName_to_js_AudioBuffer:
			js_console.log(key, " ", _js_AudioName_to_js_AudioBuffer[key])
	else:
		if _print_debug: print("%s _ready(), OS !has_feature('HTML5') - the addon works, Godot is used for audio"%[_print])
		

func load_all_audio():
	if !_check_func_valid("load_all_audio", []): return
	var time_ms_start_total:int = OS.get_ticks_msec() # for _print_debug true
	var time_ms_start:int = 0 # for _print_debug true
	for key_name in _AudioName_to_audio_path.keys():
		if _print_debug: time_ms_start = OS.get_ticks_msec()
		
		var audio_file_data:PoolByteArray = load(_AudioName_to_audio_path[key_name]).data
		var js_array_buffer:JavaScriptObject = JavaScript.create_object("ArrayBuffer", audio_file_data.size())
		var js_Uint8Array:JavaScriptObject = JavaScript.create_object("Uint8Array", js_array_buffer)
		
		for byte_id in audio_file_data.size(): 
#			Need convert audio_file_data(gdscript PoolByteArray) to ArrayBuffer(js PoolByteArray)
			js_Uint8Array[byte_id] = audio_file_data[byte_id]
		
		js_audio_context.decodeAudioData(js_array_buffer).then(js_decodeAudioData_callback)
		yield(self, "__js_decodeAudioData_callback")
		var res = _current_js_decodeAudioData_AudioBuffer
		_js_AudioName_to_js_AudioBuffer[key_name] = res
		
		if _print_debug: print("%s loaded in %sms"%[key_name, OS.get_ticks_msec() - time_ms_start])
	if _print_debug: print("all loaded in %sms"%[OS.get_ticks_msec() - time_ms_start_total])

func js_decodeAudioData_callback(args:Array):
	_current_js_decodeAudioData_AudioBuffer = args[0]
	emit_signal("__js_decodeAudioData_callback")

func test():
	print("test")

func on_audio_ended(audio:Audio):
	emit_signal("on_ended_audio", audio)

# audio_name:AudioName, volume:float(0..1)
func audio_play(audio_name:int, volume:float = 1.0) -> Audio:
	if all_stop: return null
	var audio_path:String = _AudioName_to_audio_path[AudioName.keys()[audio_name]]
	var result:Audio
	if (OS.has_feature("Android") or OS.has_feature("Windows")) and !OS.has_feature("HTML5"):
		var _audio:AudioStreamPlayer = AudioStreamPlayer.new()
		_audio.stream = load(audio_path)
		_audio.volume_db = linear2db(volume)
		add_child(_audio)
		var _audio_class = Audio.new(audio_name, {"_godot_audio": _audio})
		_audio.play()
		result = _audio_class
		all_audio.append(result)
	elif OS.has_feature("HTML5"):
		audio_path.erase(0, 6) # earse "res://"
		var _js_audio:JavaScriptObject
		if !_js_audio_pool.has(audio_name):
			_js_audio = JavaScript.create_object("Audio", audio_path)
			
			var _audio = Audio.new(audio_name, {"_js_audio":_js_audio})
			_js_audio_pool[audio_name] = []
			_js_audio_pool[audio_name].append(_audio)
			_js_audio.volume = volume
			_js_audio.play()
			result = _audio
			print("create")
			all_audio.append(result)
		else:
			var need_create:bool = true
			for audio in _js_audio_pool[audio_name]:
				if audio is Audio:
					if audio._js_audio != null and !audio.is_playing:
						audio.is_playing = true
						audio._js_audio.play()
						audio._js_audio.volume = volume
						need_create = false
						break
			if need_create:
				_js_audio = JavaScript.create_object("Audio", audio_path)
				var _audio = Audio.new(audio_name, {"_js_audio":_js_audio})
				_js_audio_pool[audio_name].append(_audio)
				_js_audio.play()
				_js_audio.volume = volume
				result = _audio
#				print("create")
				all_audio.append(result)
	print('_js_audio_pool ', _js_audio_pool)
	return result

func all_pause():
	for audio in all_audio:
		if audio is Audio:
			audio.pause_audio()
	all_stop = true

func all_continue():
	for audio in all_audio:
		if audio is Audio:
			if audio.is_pause:
				audio.continue_audio()
	all_stop = false
