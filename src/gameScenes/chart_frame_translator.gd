extends Node
class_name ChartFrameTranslator

signal frame_state_updated(frame_data: Dictionary)
signal note_should_spawn(note_data: Dictionary)
signal note_should_destroy(note_id: int)

const TARGET_FPS: int = 120
const FRAME_DURATION_MS: float = 1000.0 / TARGET_FPS
const MISS_OFFSET_FRAME = 15

var chart_data: Dictionary = {}
var raw_notes: Array = []
var raw_events: Array = []

var frame_states: Array = []
var total_frames: int = 0

var current_frame: int = 0
var audio_start_time: int = 0
var is_playing: bool = false

var processed_notes: Array = []
var processed_events: Array = []

var audio_player: AudioStreamPlayer
var sync_tolerance_ms: float = 16.67

func _ready():
	set_physics_process(true)

func initialize(chart: Dictionary, notes: Array, events: Array, player: AudioStreamPlayer):
	chart_data = chart
	raw_notes = notes
	raw_events = events
	audio_player = player
	
	_preprocess_chart_data()
	_calculate_total_frames()
	_build_frame_states()
	
	print("[ChartFrameTranslator] initialized, total frame: %d" % total_frames)
	# print(frame_states)


func _preprocess_chart_data():
	processed_notes.clear()
	processed_events.clear()
	

	for note in raw_notes:
		var hit_time_ms = note[0]
		var note_type = note[1] 
		var speed_multiplier = note[2]
		var position = note[3] if note.size() > 3 else -1
		var extra_param = note[4] if note.size() > 4 else null
		
		var travel_time_ms = _calculate_travel_time(speed_multiplier)
		var spawn_time_ms = hit_time_ms - travel_time_ms
		
		var spawn_frame = _ms_to_frame(spawn_time_ms)
		var hit_frame = _ms_to_frame(hit_time_ms)
		var destroy_frame = hit_frame + MISS_OFFSET_FRAME  # 125 ms after hit is miss
		
		var hold_end_frame = hit_frame
		if extra_param != null and (int(note_type) % 10) == 2:  # Hold note
			var hold_duration_ms = extra_param
			hold_end_frame = _ms_to_frame(hit_time_ms + hold_duration_ms)
			destroy_frame = hold_end_frame + MISS_OFFSET_FRAME
		
		var processed_note = {
			"id": processed_notes.size(),
			"original_data": note,
			"spawn_frame": max(0, spawn_frame),
			"hit_frame": hit_frame,
			"destroy_frame": destroy_frame,
			"hold_end_frame": hold_end_frame,
			"note_type": note_type,
			"position": position,
			"speed_multiplier": speed_multiplier,
			"is_hold": (int(note_type) % 10) == 2
		}
		
		processed_notes.append(processed_note)
	
	for event in raw_events:
		var event_time_ms = event[1]
		var event_frame = _ms_to_frame(event_time_ms)
		
		var processed_event = {
			"frame": event_frame,
			"type": event[0],
			"params": event.slice(2) if event.size() > 2 else []
		}
		
		processed_events.append(processed_event)
	
	# sort
	processed_notes.sort_custom(_sort_by_spawn_frame)
	processed_events.sort_custom(_sort_by_frame)

func _calculate_total_frames():
	var max_time_ms = 0
	
	for note in processed_notes:
		max_time_ms = max(max_time_ms, _frame_to_ms(note.destroy_frame))
	
	for event in processed_events:
		max_time_ms = max(max_time_ms, _frame_to_ms(event.frame))
	
	max_time_ms += 5000
	total_frames = _ms_to_frame(max_time_ms)

func _build_frame_states():
	frame_states.clear()
	frame_states.resize(total_frames)
	
	# init frame status
	for i in range(total_frames):
		frame_states[i] = {
			"frame": i,
			"time_ms": _frame_to_ms(i),
			"active_notes": [],      
			"spawn_notes": [],       
			"hit_notes": [],
			"destroy_notes": [],
			"events": []
		}
	
	for note in processed_notes:
		if note.spawn_frame < total_frames:
			frame_states[note.spawn_frame].spawn_notes.append(note)
		
		if note.hit_frame < total_frames:
			frame_states[note.hit_frame].hit_notes.append(note)
		
		if note.destroy_frame < total_frames:
			frame_states[note.destroy_frame].destroy_notes.append(note)
		
		var start_frame = max(0, note.spawn_frame)
		var end_frame = min(total_frames - 1, note.destroy_frame)
		
		for frame_idx in range(start_frame, end_frame + 1):
			frame_states[frame_idx].active_notes.append(note)
	
	for event in processed_events:
		if event.frame < total_frames:
			frame_states[event.frame].events.append(event)

func start_game():
	current_frame = 0
	is_playing = true
	

func stop_game():
	pass

func _physics_process(_delta):
	if not is_playing:
		print("[ChartFrameTranslator] halting")
		return
	
	var audio_time_ms = _get_audio_time_ms()
	var target_frame = _ms_to_frame(audio_time_ms)
	
	while current_frame <= target_frame and current_frame < total_frames:
		_process_frame(current_frame)
		print("[ChartFrameTranslator] now at frame count {current_frame}",current_frame)
		current_frame += 1
	
	if current_frame >= total_frames:
		stop_game()
		print("[ChartFrameTranslator] End")

func _process_frame(frame_idx: int):
	if frame_idx >= frame_states.size():
		return
	
	var frame_data = frame_states[frame_idx]
	
	for note in frame_data.spawn_notes:
		note_should_spawn.emit(note)
	
	for note in frame_data.destroy_notes:
		note_should_destroy.emit(note.id)
	
	for event in frame_data.events:
		_process_event(event)
	
	frame_state_updated.emit(frame_data)

func _process_event(event: Dictionary):
	match event.type:
		0:  
			print("[Event] BPM Change: %s" % str(event.params))
		1:  
			print("[Event] Rail Init: %s" % str(event.params))
		2:    
			print("[Event] Rail Relocate: %s" % str(event.params))
		_:
			print("[Event] Error: %d: %s" % [event.type, str(event.params)])

func _get_audio_time_ms() -> float:
	if not audio_player or not audio_player.playing:
		return Time.get_ticks_msec() - audio_start_time
	
	var playback_pos = audio_player.get_playback_position()
	var time_since_last_mix = AudioServer.get_time_since_last_mix()
	var output_latency = AudioServer.get_output_latency()
	
	return (playback_pos + time_since_last_mix - output_latency) * 1000.0

func _calculate_travel_time(speed_multiplier: float) -> float:
	var spawn_height = 800
	var speed_coefficient = 200
	var global_speed = 1.0
	
	return spawn_height / (global_speed * speed_coefficient * speed_multiplier) * 1000.0

func _ms_to_frame(time_ms: float) -> int:
	return int(time_ms / FRAME_DURATION_MS)

func _frame_to_ms(frame: int) -> float:
	return frame * FRAME_DURATION_MS

func _sort_by_spawn_frame(a, b) -> bool:
	return a.spawn_frame < b.spawn_frame

func _sort_by_frame(a, b) -> bool:
	return a.frame < b.frame

func get_frame_state(frame_idx: int) -> Dictionary:
	if frame_idx < 0 or frame_idx >= frame_states.size():
		return {}
	return frame_states[frame_idx]

func get_current_frame() -> int:
	return current_frame

func get_active_notes_at_frame(frame_idx: int) -> Array:
	var state = get_frame_state(frame_idx)
	return state.get("active_notes", [])

func debug_print_frame_range(start_frame: int, end_frame: int):
	for i in range(start_frame, min(end_frame + 1, frame_states.size())):
		var state = frame_states[i]
		if state.spawn_notes.size() > 0 or state.events.size() > 0:
			print("Frame %d (%.1fms): Spawn%d note, %d event" % [
				i, _frame_to_ms(i), state.spawn_notes.size(), state.events.size()
			])
