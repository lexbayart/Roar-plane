extends Node
## SpeechManager — Autoload
## Records microphone audio and checks for English "R" sound via Python vosk bridge.
## Emits R_sound_detected when words containing 'r' are recognized.

signal R_sound_detected(words: Array)
signal speech_result(text: String)
signal speech_error(message: String)

const MODEL_PATH = "res://vosk_models/vosk-model-small-en-us-0.15"
const RECORD_SECONDS = 0.5
const SAMPLE_RATE = 16000

var _recording: AudioEffectRecord
var _record_bus_idx: int
var _record_timer: float = 0.0
var _is_listening: bool = false
var _temp_wav_dir: String = "user://temp_audio"
var _last_text: String = ""


func _ready() -> void:
	# Setup audio record bus
	_record_bus_idx = AudioServer.get_bus_index("Record")
	if _record_bus_idx == -1:
		# Create Record bus dynamically if it doesn't exist
		AudioServer.add_bus()
		var new_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(new_idx, "Record")
		_record_bus_idx = new_idx
	
	# Add AudioEffectRecord if not present
	var effect = AudioEffectRecord.new()
	AudioServer.add_bus_effect(_record_bus_idx, effect, 0)
	_recording = AudioServer.get_bus_effect(_record_bus_idx, 0) as AudioEffectRecord
	
	if _recording == null:
		push_error("SpeechManager: Failed to create AudioEffectRecord")
		speech_error.emit("Failed to create AudioEffectRecord")
		return
	
	# Ensure temp directory exists
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_temp_wav_dir))
	print("SpeechManager initialized. Model path: ", MODEL_PATH)


func start_listening() -> void:
	if _is_listening:
		return
	if _recording == null:
		speech_error.emit("Recording not available")
		return
	
	_is_listening = true
	if not _recording.is_recording_active():
		_recording.set_recording_active(true)
	print("SpeechManager: Started listening")


func stop_listening() -> void:
	_is_listening = false
	if _recording != null and _recording.is_recording_active():
		_recording.set_recording_active(false)
	print("SpeechManager: Stopped listening")


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
	if recorded_audio == null or recorded_audio.get_length() < 0.1:
		return
	
	_save_and_analyze(recorded_audio)


func _save_and_analyze(audio: AudioStreamWAV) -> void:
	var timestamp = str(Time.get_ticks_msec())
	var wav_path = ProjectSettings.globalize_path(_temp_wav_dir.path_join("speech_" + timestamp + ".wav"))
	
	# Save as 16-bit mono WAV at 16kHz
	var success = _save_wav(audio, wav_path)
	if not success:
		return
	
	# Call Python bridge
	var model_abs = ProjectSettings.globalize_path(MODEL_PATH)
	var python_cmd = _find_python()
	if python_cmd.is_empty():
		speech_error.emit("Python not found. Install Python 3 and 'pip install vosk'")
		return
	
	var output = []
	var exit_code = OS.execute(python_cmd, [
		ProjectSettings.globalize_path("res://scripts/vosk_bridge.py"),
		wav_path,
		model_abs
	], output, true, true)
	
	if exit_code != 0:
		push_warning("VOSK bridge error: ", output)
		speech_error.emit("Bridge error: " + output[0] if output.size() > 0 else "unknown")
		return
	
	var json_str = output[0].strip_edges()
	var result = _parse_json(json_str)
	if result == null:
		return
	
	var text: String = result.get("text", "")
	if text == _last_text:
		return  # Skip duplicate results
	_last_text = text
	
	speech_result.emit(text)
	
	var has_r: bool = result.get("has_r_sound", false)
	if has_r:
		var r_words: Array = result.get("r_words", [])
		R_sound_detected.emit(r_words)


func _save_wav(audio: AudioStreamWAV, path: String) -> bool:
	var data = audio.get_data()
	var _format = audio.format
	var stereo = audio.stereo
	var mix_rate = audio.mix_rate
	
	# Convert to 16-bit mono 16kHz
	var final_data: PackedByteArray
	
	if stereo:
		final_data = _mix_to_mono(data)
	else:
		final_data = data
	
	# Downsample if needed
	if mix_rate != SAMPLE_RATE:
		final_data = _resample(final_data, mix_rate, SAMPLE_RATE)
	
	# Write WAV file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open WAV for writing: ", path)
		return false
	
	var data_size = final_data.size()
	var file_size = 36 + data_size
	
	# WAV header
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(file_size)
	file.store_buffer("WAVE".to_ascii_buffer())
	
	# fmt chunk
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)  # chunk size
	file.store_16(1)   # PCM
	file.store_16(1)   # mono
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)  # byte rate
	file.store_16(2)   # block align
	file.store_16(16)  # bits per sample
	
	# data chunk
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)
	file.store_buffer(final_data)
	
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
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("SpeechManager: JSON parse error: ", json.get_error_message())
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