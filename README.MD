# Manager_Audio - is cross-platform audio addon for Godot 3.5
[![Godot](https://img.shields.io/badge/Godot%20Engine-3.5.2-blue.svg)](https://github.com/godotengine/godot/)
![GitHub License](https://img.shields.io/github/license/AlexeyPe/Manager_Audio)
![GitHub Repo stars](https://img.shields.io/github/stars/AlexeyPe/Manager_Audio)

__If you have ideas for improvement, write me to [telegram](https://t.me/Alexey_Pe) / Issues / pull, I’ll read everything__

__My Telegram [@Alexey_Pe](https://t.me/Alexey_Pe)__

* This Addon is stable and ready to use. Work on the addon continues (rare, but cool updates :))
* Currently, only 1d sound is supported, 2d/3d sound support is planned for the distant future.

### Support platforms
Platform | Backend | Info
--- | --- | --- 
HTML5/Windows | Web Audio API | perfect
HTML5/Android | Web Audio API | perfect~<br>*1 On some phones there is a delay before playback, this is not fixable
HTML5/iOS | Godot | is default Godot
Windows | Godot | is default Godot
Android | Godot | is default Godot
iOS | Godot | is default Godot

* Previously there were unsuccessful attempts to use the Web Audio API on iOS - the main problems were:
    1. There is no sound in silent mode, the correction was used unmute.js
    2. iOS uses the Safari engine for all browsers, it has 0% support .ogg
    3. To convert the .ogg buffer to .wav I used the [audiobuffer-to-wav](https://github.com/Experience-Monks/audiobuffer-to-wav/tree/2272eb09bd46a05e50a6d684d908aa6f13c58f63), you can look at the previous commits, in the end I decided that it was easier to leave the implementation from Godot

### Demo
1. You can find the demo in [addons/Manager_Audio/Demo](addons/Manager_Audio/Demo)
2. If you have python, you can test the demo locally - open cmd in the directory and type `py -m http.server`

![img2](https://i.imgur.com/MAeeYwx.png)

### How Install
1. Install in AssetLib
2. Add `'Head Include'` in `Project > Export > HTML5 > Head Include`. Paste code bellow
```

<!-- Manager Audio -->
<script>function iOS(){return["iPad Simulator","iPhone Simulator","iPod Simulator","iPad","iPhone","iPod"].includes(navigator.platform)||navigator.userAgent.includes("Mac")&&"ontouchend"in document}try{window.AudioContext=window.AudioContext||window.webkitAudioContext}catch(o){console.log("Manager Audio, No Web Audio API support")}function decodeAudioDataArr(o,t,d,e){for(let i=0;i<d.length&&i<t.length;i++)o.decodeAudioData(t[i],(o=>{e(o,d[i])}))}
</script>

```
3. Perfect, the addon is installed!🎉

### How use
1. Manager_Audio.gd, AudioName add key
2. Manager_Audio.gd, _AudioName_to_audio_path, add key(AudioName) and value(path to audio)
3. For play audio use `Manager_Audio.audio_play(AudioName, volume)` and `Manager_Audio.all_pause()`/`Manager_Audio.all_continue()`
4. For the web: audio files are not needed next to index.html, everything works without it (not needed at all)

![img1](https://i.imgur.com/cLKU0Q0.png)

#### Manager_Audio base functions
```gdscript
# return Manager_Audio.Audio, signal - on_audio_ended(Manager_Audio.Audio)
Manager_Audio.audio_play(AudioName, volume)

# These functions are useful when calling ad viewing functions when you need to stop all sounds and then return everything after the ad.
Manager_Audio.all_pause()
Manager_Audio.all_continue()
```
#### Manager_Audio.Audio
* It is assumed that you get this class using `Manager_Audio.audio_play(AudioName, volume)`
```gdscript
# Manager_Audio.Audio emit signal when audio finishes playing
Manager_Audio.on_ended_audio(Manager_Audio.Audio)
# volume = clamp(new, 0.0, 1.0)
Manager_Audio.Audio.set_volume(new)
# It is implied that you can write the Audio class, and when it is "ended" you can play()
Manager_Audio.Audio.play(AudioName, volume)
# Don't use the functions below (It will work later)
Manager_Audio.Audio.pause_audio()
Manager_Audio.Audio.continue_audio()
```

#### Source
Manager_Audio Original JS
```js
function iOS() {
  return [
    'iPad Simulator',
    'iPhone Simulator',
    'iPod Simulator',
    'iPad',
    'iPhone',
    'iPod'
  ].includes(navigator.platform)
  // iPad on iOS 13 detection
  || (navigator.userAgent.includes("Mac") && "ontouchend" in document)
}
try {
    window.AudioContext = window.AudioContext || window.webkitAudioContext;
} catch (o) {
    console.log("Manager Audio, No Web Audio API support");
}
function decodeAudioDataArr(js_audio_context, _js_array_buffers, _js_array_keys, js_decodeAudioData_callback) {
    for (let i = 0; i < _js_array_keys.length && i < _js_array_buffers.length; i++)
        js_audio_context.decodeAudioData(_js_array_buffers[i], (audio_buffer) => {
            js_decodeAudioData_callback(audio_buffer, _js_array_keys[i]);
        });
}
```
Minify JS (for head include)
```js
function iOS(){return["iPad Simulator","iPhone Simulator","iPod Simulator","iPad","iPhone","iPod"].includes(navigator.platform)||navigator.userAgent.includes("Mac")&&"ontouchend"in document}try{window.AudioContext=window.AudioContext||window.webkitAudioContext}catch(o){console.log("Manager Audio, No Web Audio API support")}function decodeAudioDataArr(o,t,d,e){for(let i=0;i<d.length&&i<t.length;i++)o.decodeAudioData(t[i],(o=>{e(o,d[i])}))}
```