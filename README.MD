# Manager_Audio - is cross-platform audio addon for Godot 3.5

* This Addon is stable and ready to use
* This addon is maintained and developed(Rare but cool updates:))
* For context: Godot Engine audio on the web is terribly bad, this addon appeared to fix it

__My Telegram [@Alexey_Pe](https://t.me/Alexey_Pe)__

### Support platforms
Platform | Backend | Info
--- | --- | --- 
HTML5/Windows | Web Audio API | perfect
HTML5/Android | Web Audio API | perfect~<br>*1 On some phones there is a delay before playback, this is not fixable
HTML5/iOS | Web Audio API<br>+[unmute.js](https://github.com/swevans/unmute)| perfect<br>*1 Apple has a lot of problems, we shift the responsibility of solving them to unmute.js :)
Windows | Godot | is default Godot
Android | Godot | is default Godot
iOS | Godot | is default Godot

### Demo
1. You can find the demo in [addons/Manager_Audio/Demo](addons/Manager_Audio/Demo)
2. If you have python, you can test the demo locally - open cmd in the directory and type `py -m http.server`

### How Install
1. Install in AssetLib
2. Add `'Head Include'` in `Project > Export > HTML5 > Head Include`. Paste code bellow
```

<!-- Manager Audio -->
<script>try{window.AudioContext=window.AudioContext||window.webkitAudioContext}catch(o){console.log("Manager Audio, No Web Audio API support")}function decodeAudioDataArr(o,t,d,e){for(let i=0;i<d.length&&t.length;i++)o.decodeAudioData(t[i],(o=>{e(o,d[i])}))}</script>
<!-- Manager Audio - unmute.min.js -->
<script>"use strict";function unmute(i,e,n){var t;function d(n,i,e,t,d){for(var o=0;o<i.length;++o)n.addEventListener(i[o],e,{capture:t,passive:d})}function o(n,i,e,t,d){for(var o=0;o<i.length;++o)n.removeEventListener(i[o],e,{capture:t,passive:d})}function a(){}void 0===e&&(e=!1),void 0===n&&(n=!1),void 0!==document.hidden?t={hidden:"hidden",visibilitychange:"visibilitychange"}:void 0!==document.webkitHidden?t={hidden:"webkitHidden",visibilitychange:"webkitvisibilitychange"}:void 0!==document.mozHidden?t={hidden:"mozHidden",visibilitychange:"mozvisibilitychange"}:void 0!==document.msHidden&&(t={hidden:"msHidden",visibilitychange:"msvisibilitychange"});var c=navigator.userAgent.toLowerCase(),u=n||0<=c.indexOf("iphone")&&c.indexOf("like iphone")<0||0<=c.indexOf("ipad")&&c.indexOf("like ipad")<0||0<=c.indexOf("ipod")&&c.indexOf("like ipod")<0||0<=c.indexOf("mac os x")&&0<navigator.maxTouchPoints,A=!0;function s(){var n=!(!e&&(t&&document[t.hidden]||u&&!document.hasFocus()));n!==A&&(A=n,b(!1),h())}function l(){s()}function r(n){n&&n.target!==window||s()}function h(){var n;A?"running"!==i.state&&"closed"!==i.state&&k&&(n=i.resume(),n&&n.then(a,a).catch(a)):"running"===i.state&&(n=i.suspend(),n&&n.then(a,a).catch(a))}function v(n){n&&n.unmute_handled||(n.unmute_handled=!0,h())}t&&d(document,[t.visibilitychange],l,!0,!0),u&&d(window,["focus","blur"],r,!0,!0),d(i,["statechange"],v,!0,!0),i.onstatechange||(i.onstatechange=v);var g=null;function m(n,i){for(var e=i;1<n;n--)e+=i;return e}var f="data:audio/mpeg;base64,//uQx"+m(23,"A")+"WGluZwAAAA8AAAACAAACcQCA"+m(16,"gICA")+m(66,"/")+"8AAABhTEFNRTMuMTAwA8MAAAAAAAAAABQgJAUHQQAB9AAAAnGMHkkI"+m(320,"A")+"//sQxAADgnABGiAAQBCqgCRMAAgEAH"+m(15,"/")+"7+n/9FTuQsQH//////2NG0jWUGlio5gLQTOtIoeR2WX////X4s9Atb/JRVCbBUpeRUq"+m(18,"/")+"9RUi0f2jn/+xDECgPCjAEQAABN4AAANIAAAAQVTEFNRTMuMTAw"+m(97,"V")+"Q==";function b(n){var i;u&&(A?n&&(g||(i=document.createElement("div"),i.innerHTML="<audio x-webkit-airplay='deny'></audio>",g=i.children.item(0),g.controls=!1,g.disableRemotePlayback=!0,g.preload="auto",g.src=f,g.loop=!0,g.load()),g.paused&&(i=g.play(),i&&i.then(a,p).catch(p))):p())}function p(){g&&(g.src="about:blank",g.load(),g=null)}var w=["click","contextmenu","auxclick","dblclick","mousedown","mouseup","touchend","keydown","keyup"],k=!1;function y(){k=!0,b(!0),h()}return d(window,w,y,!0,!0),{dispose:function(){p(),t&&o(document,[t.visibilitychange],l,!0,!0),u&&o(window,["focus","blur"],r,!0,!0),o(window,w,y,!0,!0),o(i,["statechange"],v,!0,!0),i.onstatechange===v&&(i.onstatechange=null)}}}</script>

```
3. Perfect, the addon is installed!🎉

### How use
1. Manager_Audio.gd, AudioName add key
2. Manager_Audio.gd, _AudioName_to_audio_path, add key(AudioName) and value(path to audio)
3. For play audio use `Manager_Audio.audio_play(AudioName, volume)` and `Manager_Audio.all_pause()`/`Manager_Audio.all_continue()`
4. For the web: audio files are not needed next to index.html, everything works without it (not needed at all)

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