"""
集成示例：如何在现有的game_scene.gd中使用帧转译系统

这个文件展示了两种使用方式：
1. 完全替换现有的基于时间的系统
2. 与现有系统并行运行进行对比测试
"""

# 在现有的game_scene.gd中添加以下代码：

extends Node2D
class_name gameSceneNew

# 现有代码保持不变...

# 新增：帧转译系统
var frame_translator
var use_frame_system: bool = false  # 开关：是否使用新的帧系统

func _ready() -> void:
	# 现有的初始化代码...
	chartLoader.connect("chart_loaded", _on_chart_loaded)
	
	# 新增：初始化帧转译系统
	_initialize_frame_system()
	
	# 其他现有代码...

## 新增：初始化帧转译系统
func _initialize_frame_system():
	var translator_script = load("res://src/gameScenes/chart_frame_translator.gd")
	frame_translator = translator_script.new()
	add_child(frame_translator)
	
	# 连接信号
	frame_translator.note_should_spawn.connect(_on_frame_note_spawn)
	frame_translator.note_should_destroy.connect(_on_frame_note_destroy)
	frame_translator.frame_state_updated.connect(_on_frame_state_updated)

## 修改：chart加载完成时的处理
func _on_chart_loaded(data: Dictionary, events: Array, notes: Array) -> void:
	print("chart_loaded")
	
	# 现有逻辑
	note_handler.ref_BPM = float(data["BPM"])
	note_handler.current_BPM = float(data["BPM"])
	event_handler._parse_raw_events(events)
	judgement.score_init()
	
	if use_frame_system:
		# 新系统：使用帧转译器
		frame_translator.initialize(data, notes, events, soundPlayer)
		print("[GameScene] 使用帧转译系统")
	else:
		# 现有系统
		_build_note_array(notes)
		print("[GameScene] 使用传统时间系统")
	
	# 启动游戏
	soundPlayer.play()
	if use_frame_system:
		frame_translator.start_game()
	else:
		song_start_time = Time.get_ticks_msec()
	
	Global.state = Global.StateMachine.playing

## 修改：物理帧处理
func _physics_process(_delta: float) -> void:
	frame+=1
	
	if use_frame_system:
		# 新系统：帧转译器自动处理
		# 这里只需要处理UI更新和游戏状态检查
		check_game_end()
		update_displays()
	else:
		# 现有系统逻辑
		var now_rel := Time.get_ticks_msec() - song_start_time
		while next_note_idx < upcoming_notes.size() && upcoming_notes[next_note_idx].spawn_time <= now_rel:
			entry = upcoming_notes[next_note_idx]
			note_handler._spawn_from_data(entry.data)
			next_note_idx += 1
		note_handler.setNoteEnable()
		event_handler._process_event(_delta)

## 新增：帧系统的note生成处理
func _on_frame_note_spawn(note_data: Dictionary):
	print("[FrameSystem] 生成note: ID=%d, 类型=%d" % [note_data.id, note_data.note_type])
	note_handler._spawn_from_data(note_data.original_data)

## 新增：帧系统的note销毁处理  
func _on_frame_note_destroy(note_id: int):
	print("[FrameSystem] 销毁note: ID=%d" % note_id)
	# 可以在这里添加note销毁逻辑

## 新增：帧状态更新处理
func _on_frame_state_updated(frame_data: Dictionary):
	# 处理events
	for event in frame_data.events:
		_process_frame_event(event)
	
	# 更新UI
	update_displays()

## 新增：处理帧事件
func _process_frame_event(event: Dictionary):
	match event.type:
		0:  # BPM change
			var new_bpm = event.params[0] if event.params.size() > 0 else 120
			note_handler.current_BPM = new_bpm
			print("[FrameEvent] BPM变更: %d" % new_bpm)
		
		1:  # 轨道初始化
			if event.params.size() >= 4:
				var rail_params = event.params[0]
				event_handler.emit_signal("linear_rail_init", rail_params[0], Vector2(rail_params[1], rail_params[2]), rail_params[3])
		
		2:  # 轨道重定位
			# 处理轨道重定位逻辑
			pass
		
		3:  # 轨道销毁
			if event.params.size() > 0:
				event_handler.emit_signal("linear_rail_destroy", event.params[0])

## 新增：系统切换函数（用于调试对比）
func toggle_frame_system():
	use_frame_system = !use_frame_system
	print("[GameScene] 切换到 %s 系统" % ("帧转译" if use_frame_system else "传统时间"))
	
	# 重新加载当前chart进行测试
	if chartLoader:
		chartLoader.load_chart("res://charts/dummy_chart.yaml")

## 新增：性能对比函数
func compare_systems():
	print("=== 系统性能对比 ===")
	
	# 传统系统信息
	print("传统系统:")
	print("  - upcoming_notes数量: %d" % upcoming_notes.size())
	print("  - 当前处理索引: %d" % next_note_idx)
	print("  - 剩余notes: %d" % (upcoming_notes.size() - next_note_idx))
	
	# 帧系统信息
	if frame_translator:
		print("帧转译系统:")
		print("  - 总帧数: %d" % frame_translator.total_frames)
		print("  - 当前帧: %d" % frame_translator.get_current_frame())
		print("  - 处理进度: %.1f%%" % (float(frame_translator.get_current_frame()) / frame_translator.total_frames * 100))

## 新增：调试信息输出
func debug_current_state():
	print("=== 当前游戏状态 ===")
	print("使用帧系统: %s" % use_frame_system)
	print("当前帧号: %d" % frame)
	print("音频时间: %.3fs" % soundPlayback())
	
	if use_frame_system and frame_translator:
		var current_frame_idx = frame_translator.get_current_frame()
		var frame_state = frame_translator.get_frame_state(current_frame_idx)
		print("帧转译器状态:")
		print("  - 当前帧: %d" % current_frame_idx)
		print("  - 活跃notes: %d" % frame_state.get("active_notes", []).size())
		print("  - 即将生成: %d" % frame_state.get("spawn_notes", []).size())
