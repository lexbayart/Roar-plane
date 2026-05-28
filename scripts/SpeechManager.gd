extends Node
## SpeechManager — Autoload
## Records microphone audio and checks for English "R" sound via Python vosk bridge.
## Emits R_sound_detected when words containing 'r' are recognized.

signal R_sound_detected(words: Array)
signal speech_result(text: String)
signal speech_error(message: String)
signal mic_volume_updated(volume: float)

const MODEL_PATH = "res://vosk_models/vosk-model-small-ru-0.22"
const RECORD_SECONDS = 0.1
const SAMPLE_RATE = 16000
const ROLLING_WINDOW_SIZE = 22400 # 700ms at 16kHz 16-bit mono

var _recording: AudioEffectRecord
var _record_bus_idx: int
var _record_timer: float = 0.0
var _is_listening: bool = false
var _temp_wav_dir: String = "user://temp_audio"
var _last_text: String = ""
var _mic_player: AudioStreamPlayer  # Routes mic into Record bus
var _daemon_pid: int = -1
var _rolling_raw_data: PackedByteArray = PackedByteArray()
var _is_analyzing: bool = false


func _ready() -> void:
	# Включаем аудиовход (микрофон) на уровне движка
	AudioServer.set_enable_tagging_used_audio_streams(true)

	# Setup audio record bus
	_record_bus_idx = AudioServer.get_bus_index("Record")
	if _record_bus_idx == -1:
		AudioServer.add_bus()
		var new_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(new_idx, "Record")
		_record_bus_idx = new_idx

	# Отключаем вывод шины Record в динамики (чтобы не было эха)
	AudioServer.set_bus_send(_record_bus_idx, "")
	AudioServer.set_bus_volume_db(_record_bus_idx, -80.0)

	# Add AudioEffectRecord
	var effect = AudioEffectRecord.new()
	AudioServer.add_bus_effect(_record_bus_idx, effect, 0)
	_recording = AudioServer.get_bus_effect(_record_bus_idx, 0) as AudioEffectRecord

	if _recording == null:
		push_error("SpeechManager: Failed to create AudioEffectRecord")
		speech_error.emit("Failed to create AudioEffectRecord")
		return

	# КРИТИЧНО: AudioStreamMicrophone роутит вход микрофона в шину Record.
	# Без этого AudioEffectRecord пишет тишину (rms=0).
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = "Record"
	_mic_player.autoplay = false
	add_child(_mic_player)

	# Ensure temp directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_temp_wav_dir))
	print("SpeechManager initialized. Mic player ready.")


func start_listening() -> void:
	if _is_listening:
		return
	if _recording == null:
		speech_error.emit("Recording not available")
		return

	# Start VOSK Daemon if not running
	if _daemon_pid == -1:
		var python_cmd = _find_python()
		if not python_cmd.is_empty():
			var daemon_script = ProjectSettings.globalize_path("res://scripts/vosk_daemon.py")
			_daemon_pid = OS.create_process(python_cmd, [daemon_script])
			print("SpeechManager: Started VOSK Daemon with PID ", _daemon_pid)
			OS.delay_msec(600)  # Give VOSK time to load and open the TCP port
		else:
			push_error("SpeechManager: Python3 not found, cannot start speech recognition")

	_is_listening = true
	# Запускаем микрофон — без этого AudioEffectRecord пишет тишину
	if _mic_player and not _mic_player.playing:
		_mic_player.play()
	if not _recording.is_recording_active():
		_recording.set_recording_active(true)
	print("SpeechManager: Started listening")


func stop_listening() -> void:
	_is_listening = false
	if _recording != null and _recording.is_recording_active():
		_recording.set_recording_active(false)
	if _mic_player and _mic_player.playing:
		_mic_player.stop()
	print("SpeechManager: Stopped listening")


func _calculate_volume(pcm_data: PackedByteArray) -> float:
	if pcm_data.is_empty():
		return 0.0
		
	var sample_count = pcm_data.size() / 2
	var sum = 0.0
	for i in range(sample_count):
		var sample = pcm_data.decode_s16(i * 2)
		sum += abs(sample)
		
	return sum / sample_count


func _process(delta: float) -> void:
	if not _is_listening or _recording == null:
		return
	
	_record_timer += delta
	if _record_timer < RECORD_SECONDS:
		return
	_record_timer = 0.0
	
	if not _recording.is_recording_active():
		return
	
	var recorded_audio: AudioStreamWAV = _recording.get_recording()
	_recording.set_recording_active(false)
	_recording.set_recording_active(true)

	if recorded_audio == null:
		return
	
	var clean_chunk = _get_clean_bytes(recorded_audio)
	if clean_chunk.is_empty():
		return
		
	var vol = _calculate_volume(clean_chunk)
	mic_volume_updated.emit(vol)
		
	_rolling_raw_data.append_array(clean_chunk)
	if _rolling_raw_data.size() > ROLLING_WINDOW_SIZE:
		var excess = _rolling_raw_data.size() - ROLLING_WINDOW_SIZE
		_rolling_raw_data = _rolling_raw_data.slice(excess)
		
	_save_and_analyze_rolling()


var _analysis_thread: Thread

func _save_and_analyze_rolling() -> void:
	# Avoid overlapping threads using a robust boolean flag
	if _is_analyzing:
		return

	var timestamp = str(Time.get_ticks_msec())
	var wav_path = ProjectSettings.globalize_path(_temp_wav_dir.path_join("speech_" + timestamp + ".wav"))
	
	# Save rolling buffer as 16-bit mono WAV at 16kHz
	var success = _save_wav_from_bytes(_rolling_raw_data, wav_path)
	if not success:
		return
	
	_is_analyzing = true
	_analysis_thread = Thread.new()
	_analysis_thread.start(_run_python_bridge_async.bind(wav_path))


func _run_python_bridge_async(wav_path: String) -> void:
	var tcp = StreamPeerTCP.new()
	var err = tcp.connect_to_host("127.0.0.1", 9999)
	if err != OK:
		call_deferred("_on_analysis_done", "{\"error\": \"Failed to connect to daemon\"}")
		return
		
	# Wait for connection to establish (non-blocking in thread)
	var timeout = 100
	while tcp.get_status() == StreamPeerTCP.STATUS_CONNECTING and timeout > 0:
		OS.delay_msec(5)
		tcp.poll()
		timeout -= 1
		
	if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		call_deferred("_on_analysis_done", "{\"error\": \"Connection timeout\"}")
		return
		
	# Send WAV path
	var msg = wav_path + "\n"
	tcp.put_data(msg.to_utf8_buffer())
	
	# Wait for response line
	var response = ""
	var start_time = Time.get_ticks_msec()
	var timeout_ms = 1000
	
	while response.find("\n") == -1 and (Time.get_ticks_msec() - start_time) < timeout_ms:
		tcp.poll()
		if tcp.get_available_bytes() > 0:
			var chunk = tcp.get_utf8_string(tcp.get_available_bytes())
			response += chunk
		else:
			OS.delay_msec(2)
			
	tcp.disconnect_from_host()
	
	var json_str = response.strip_edges()
	call_deferred("_on_analysis_done", json_str)


func _on_analysis_done(json_str: String) -> void:
	if _analysis_thread:
		_analysis_thread.wait_to_finish()
		_analysis_thread = null
	
	_is_analyzing = false

	var result = _parse_json(json_str)
	if typeof(result) != TYPE_DICTIONARY or result.is_empty() or result.has("error"):
		return
	
	var text: String = result.get("text", "")
	if text != _last_text:
		_last_text = text
		speech_result.emit(text)
		
		var has_r: bool = result.get("has_r_sound", false) or result.get("has_r_trill", false)
		if has_r and text != "":
			var intensity: float = float(result.get("r_intensity", 1.0))
			R_sound_detected.emit([intensity])


func _get_clean_bytes(audio: AudioStreamWAV) -> PackedByteArray:
	var data = audio.get_data()
	var stereo = audio.stereo
	var mix_rate = audio.mix_rate
	
	var final_data: PackedByteArray
	if stereo:
		final_data = _mix_to_mono(data)
	else:
		final_data = data
		
	if mix_rate != SAMPLE_RATE:
		final_data = _resample(final_data, mix_rate, SAMPLE_RATE)
		
	return final_data


func _save_wav_from_bytes(raw_bytes: PackedByteArray, path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open WAV for writing: ", path)
		return false
	
	var data_size = raw_bytes.size()
	var file_size = 36 + data_size
	
	# WAV header
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(file_size)
	file.store_buffer("WAVE".to_ascii_buffer())
	
	# fmt chunk
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)   # PCM
	file.store_16(1)   # mono
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)
	file.store_16(2)
	file.store_16(16)
	
	# data chunk
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)
	file.store_buffer(raw_bytes)
	
	file.close()
	return true


func _mix_to_mono(stereo_data: PackedByteArray) -> PackedByteArray:
	var sample_count = stereo_data.size() / 4.0
	var mono = PackedByteArray()
	mono.resize(sample_count * 2)
	
	for i in range(sample_count):
		var left = stereo_data.decode_s16(i * 4)
		var right = stereo_data.decode_s16(i * 4 + 2)
		var mixed = clampi(int((left + right) / 2.0), -32768, 32767)
		mono.encode_s16(i * 2, mixed)
	
	return mono


func _resample(data: PackedByteArray, from_rate: int, to_rate: int) -> PackedByteArray:
	if from_rate == to_rate:
		return data
	var ratio = float(to_rate) / float(from_rate)
	var new_size = int(data.size() * ratio / 2.0) * 2  # ensure even
	var resampled = PackedByteArray()
	resampled.resize(new_size)
	
	for i in range(floori(new_size / 2.0)):
		var src_idx = int(float(i) / ratio) * 2
		if src_idx + 1 < data.size():
			resampled.encode_s16(i * 2, data.decode_s16(src_idx))
	
	return resampled


func _parse_json(text: String) -> Dictionary:
	var start_idx = text.find("{")
	var end_idx = text.rfind("}")
	if start_idx == -1 or end_idx == -1 or end_idx < start_idx:
		return {}
	var json_str = text.substr(start_idx, end_idx - start_idx + 1)

	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		return {}
	return json.data as Dictionary


func _find_python() -> String:
	var candidates = ["python3", "python"]
	for cmd in candidates:
		var result = OS.execute(cmd, ["--version"], [], true)
		if result == 0:
			return cmd
	return ""


func _exit_tree() -> void:
	stop_listening()
	if _daemon_pid != -1:
		OS.kill(_daemon_pid)
		_daemon_pid = -1
		print("SpeechManager: Stopped and killed VOSK Daemon on exit.")