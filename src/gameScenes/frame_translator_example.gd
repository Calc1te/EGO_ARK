extends Node
# 简单的使用示例：如何使用ChartFrameTranslator

func example_usage():
	# 1. 创建转译器实例
	var translator_script = load("res://src/gameScenes/chart_frame_translator.gd")
	var frame_translator = translator_script.new()
	add_child(frame_translator)
	
	# 2. 连接信号
	frame_translator.note_should_spawn.connect(_on_note_spawn)
	frame_translator.note_should_destroy.connect(_on_note_destroy)
	
	# 3. 准备数据（示例数据）
	var chart_data = {"BPM": 120, "Title": "Test Song"}
	var notes = [
		[3000, 11, 1, -1, null],    # 3秒处的tap note
		[4000, 12, 1, -1, 500],     # 4秒处的hold note，持续500ms
		[5000, 13, 1, -1, 2]        # 5秒处的flick note
	]
	var events = [
		[0, 1500, 200],             # 1.5秒处BPM变更为200
		[1, 2000, ["rail1", 0, 0, 180]]  # 2秒处初始化轨道
	]
	
	# 4. 假设有音频播放器
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# 5. 初始化转译器
	frame_translator.initialize(chart_data, notes, events, audio_player)
	
	# 6. 开始游戏
	audio_player.play()
	frame_translator.start_game()
	
	print("帧转译器已启动，总帧数: %d" % frame_translator.total_frames)

func _on_note_spawn(note_data: Dictionary):
	print("生成note: ID=%d, 类型=%d, 时间=%.1fms" % [
		note_data.id, 
		note_data.note_type, 
		note_data.get("original_data", [0])[0]
	])

func _on_note_destroy(note_id: int):
	print("销毁note: ID=%d" % note_id)
