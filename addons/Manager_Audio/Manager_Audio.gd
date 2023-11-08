extends Node

# audio:Audio
signal on_ended_audio(audio)
signal _on_decodeAudioData_all() # private signal, from load_all_audio()/js_decodeAudioData_callback()


# Variables for change //
var _print_debug:bool = true
const _print:String = "Addon:ManagerAudio"

# iOS hack - https://github.com/swevans/unmute/tree/master#usage
var allowBackgroundPlayback = false; # default false, recommended false
var forceIOSBehavior = false; # default false, recommended false

enum AudioName {
	pip, 
	test_music
}

# AudioName.keys()[int] => path to audio (String)
const _AudioName_to_audio_path:Dictionary = {
	"pip": "res://audio/pip.mp3",
	"test_music": "res://audio/test_music_cc0.ogg"
}
# End Variables for change //

# AudioName => js_AudioBuffer (https://developer.mozilla.org/ru/docs/Web/API/AudioBuffer)
var _js_AudioName_to_js_AudioBuffer:Dictionary = {}

# AudioName => [Audio] (Audio._js_audio != null and Audio._godot_audio == null)
var _js_audio_pool = {}
# id:int => Audio
var all_audio = []

var all_stop:bool = false

var js_audio_context
var js_audio_context_gainNode
var js_console:JavaScriptObject
var js_unmuteHandle:JavaScriptObject
var js_window:JavaScriptObject
var js_decodeAudioData_callback = JavaScript.create_callback(self, "js_decodeAudioData_callback")
var _current_js_decodeAudioData_count:int # private, not use
var _current_js_decodeAudioData_count_target:int # private, not use

class Audio:
	var is_ended:bool
	var is_playing:bool
	var is_pause:bool = false
	var pause_time:float = -1
	var audio_name:int
	var volume:float
	var is_js_audio:bool = false
	var _js_gainNode
	var _js_audio
	var _js_audio_ended_callback = JavaScript.create_callback(self, "_js_audio_ended_callback")
	var _godot_audio:AudioStreamPlayer
	func _js_audio_ended_callback(args:Array):
#		print("_js_audio_ended_callback")
		is_playing = false
		is_pause = false
		is_ended = true
		Manager_Audio.emit_signal("on_ended_audio", self)
	func _init(_audio_name:int, _volume:float, audio:Dictionary):
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
		if audio.get("_js_audio", false):
			is_js_audio = true
			print("_js_audio ", _js_audio)
			if _js_audio == null: 
				_js_audio = Manager_Audio.js_audio_context.createBufferSource() # source
				_js_gainNode = Manager_Audio.js_audio_context.createGain() # gain
				_js_audio.buffer = Manager_Audio._js_AudioName_to_js_AudioBuffer[Manager_Audio.AudioName.keys()[audio_name]]
				_js_audio.addEventListener("ended", _js_audio_ended_callback)
				_js_audio.connect(_js_gainNode) # source to gain
				_js_gainNode.connect(Manager_Audio.js_audio_context.destination) # gain to js_audio_context.destination 
			set_volume(_volume)
			_js_audio.start(0.0)
	func play():
		if is_playing: return
		is_playing = true
		is_ended = false
		is_pause = false
		if is_js_audio: 
#			print("play is_js_audio")
			_init(audio_name, volume, {"_js_audio":true})
		else:
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
	func set_volume(new:float):
		new = clamp(new, 0.0, 1.0)
		volume = new
		if _godot_audio != null:
			_godot_audio.volume_db = linear2db(volume)
		if _js_audio != null:
			_js_gainNode.gain.value = volume
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
	if _print_debug: print("%s _check_func_valid(function_name:%s, args:%s)"%[_print, function_name, args])
	return result

func _ready():
	if OS.has_feature("HTML5"):
		if _print_debug: print("%s _ready(), OS has_feature('HTML5') - the addon works, for audio the Web Audio API is used"%[_print])
		# Web Audio Api/AudioContext is designed to control and play all sounds
		js_audio_context = JavaScript.create_object("AudioContext")
		js_window = JavaScript.get_interface("window")
		js_console = JavaScript.get_interface("console")
		
		# iOS hack
		# https://github.com/swevans/unmute/tree/master#usage
		js_unmuteHandle = js_window.unmute(js_audio_context, allowBackgroundPlayback, forceIOSBehavior);
		
		# For each sound you need to create an AudioBuffer
		# AudioBuffer is created using AudioContext.decodeAudioData() or AudioContext.createBuffer()
		# Using AudioBufferSourceNode you can listen to data from AudioBuffer
		load_all_audio()
	else:
		if _print_debug: print("%s _ready(), OS !has_feature('HTML5') - the addon works, Godot is used for audio"%[_print])

# Web Audio API - decodeAudioData, audio is loaded asynchronously
# _on_decodeAudioData_all - emitted when all audio is loaded
func load_all_audio():
	if !_check_func_valid("load_all_audio", []): return
	var _js_array_buffers:JavaScriptObject = JavaScript.create_object("Array")
	var _js_array_keys:JavaScriptObject = JavaScript.create_object("Array")
	_current_js_decodeAudioData_count = 0
	_current_js_decodeAudioData_count_target = _AudioName_to_audio_path.keys().size()
	
	for key_name in _AudioName_to_audio_path.keys():
		var audio_file_data:PoolByteArray = load(_AudioName_to_audio_path[key_name]).data
		var js_array_buffer:JavaScriptObject = JavaScript.create_object("ArrayBuffer", audio_file_data.size())
		var js_Uint8Array:JavaScriptObject = JavaScript.create_object("Uint8Array", js_array_buffer)
		
		for byte_id in audio_file_data.size(): 
#			Need convert audio_file_data(gdscript PoolByteArray) to ArrayBuffer(js PoolByteArray)
			js_Uint8Array[byte_id] = audio_file_data[byte_id]
		
		_js_array_keys.push(key_name)
		_js_array_buffers.push(js_array_buffer)
	
	js_window.decodeAudioDataArr(js_audio_context, _js_array_buffers, _js_array_keys, js_decodeAudioData_callback)


func js_decodeAudioData_callback(args:Array):
	_js_AudioName_to_js_AudioBuffer[args[1]] = args[0]
	_current_js_decodeAudioData_count += 1
	if _current_js_decodeAudioData_count == _current_js_decodeAudioData_count_target:
		emit_signal("_on_decodeAudioData_all")

func on_audio_ended(audio:Audio):
	emit_signal("on_ended_audio", audio)

# audio_name:AudioName, volume:float(0..1)
func audio_play(audio_name:int, volume:float = 1.0) -> Audio:
	if all_stop: return null
	var audio_path:String = _AudioName_to_audio_path[AudioName.keys()[audio_name]]
	var result:Audio
	if (OS.has_feature("Android") or OS.has_feature("Windows") or OS.has_feature("iOS")) and !OS.has_feature("HTML5"):
		var _audio:AudioStreamPlayer = AudioStreamPlayer.new()
		_audio.stream = load(audio_path)
		_audio.volume_db = linear2db(volume)
		add_child(_audio)
		var _audio_class = Audio.new(audio_name, volume, {"_godot_audio": _audio})
		_audio.play()
		result = _audio_class
		all_audio.append(result)
	elif OS.has_feature("HTML5"):
		var _audio:Audio = Audio.new(audio_name, volume, {"_js_audio": true})
		result = _audio
		all_audio.append(result)
	return result

func all_pause():
	if OS.has_feature("HTML5"): 
		if js_unmuteHandle != null:
			js_unmuteHandle.dispose()
			js_unmuteHandle = null
		if js_audio_context == null: 
			print("all_continue() js_audio_context == null")
			return
		js_audio_context.suspend()
	else:
		for audio in all_audio:
			if audio is Audio:
				audio.pause_audio()
	all_stop = true

func all_continue():
	if OS.has_feature("HTML5"): 
		if js_unmuteHandle == null:
			if js_window == null: 
				print("all_continue() js_window == null")
				return
			js_unmuteHandle = js_window.unmute(js_audio_context, allowBackgroundPlayback, forceIOSBehavior)
		if js_audio_context == null: 
			print("all_continue() js_audio_context == null")
			return
		js_audio_context.resume()
	else:
		for audio in all_audio:
			if audio is Audio:
				if audio.is_pause:
					audio.continue_audio()
	all_stop = false
