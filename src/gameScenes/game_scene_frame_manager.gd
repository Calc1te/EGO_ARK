extends Node
class_name GameSceneFrameManager


# 引用转译器
var frame_translator

# 现有的游戏组件
@onready var soundPlayer : AudioStreamPlayer = $AudioStreamPlayer
@onready var chartLoader : ChartLoader = $ChartLoader
@onready var frameTranslator : ChartFrameTranslator = $ChartFrameTranslator
# fixme: 
@onready var lineRailContainer : LinearRailContainer = $LinearRailContainer
@onready var sphereRailContainer : Node2D = $SphereRailContainer

@onready var comboDisplay : RichTextLabel = $combo
@onready var scoreDisplay : RichTextLabel = $score
@onready var judgement := GSJudge.new()
@onready var note_handler := GSNote.new()
@onready var event_handler := GSEvent.new()

# 帧状态管理
var active_notes_map: Dictionary = {}  # note_id -> note_instance
var frame_debug_enabled: bool = false

func _ready():
	# 加载转译器脚本
	var translator_script = load("res://src/gameScenes/chart_frame_translator.gd")
	frame_translator = translator_script.new()
	# 添加转译器到场景树
	add_child(frame_translator)
	
	# 连接信号
	frame_translator.note_should_spawn.connect(_on_note_should_spawn)
	frame_translator.note_should_destroy.connect(_on_note_should_destroy)
	frame_translator.frame_state_updated.connect(_on_frame_state_updated)
	
	# 连接chart loader
	if chartLoader:
		chartLoader.chart_loaded.connect(_on_chart_loaded_with_frame_system)
	chartLoader.load_chart("res://charts/dummy_chart.yaml")
	start_frame_based_game()


## 当chart加载完成时，初始化帧系统
func _on_chart_loaded_with_frame_system(data: Dictionary, events: Array, notes: Array):
	print("[GameSceneFrameManager] 开始初始化帧转译器...")
	
	# 初始化转译器
	frame_translator.initialize(data, notes, events, soundPlayer)
	
	# 设置游戏参数
	if note_handler:
		note_handler.ref_BPM = float(data.get("BPM", 120))
		note_handler.current_BPM = float(data.get("BPM", 120))
		note_handler.judgement = judgement
		note_handler.static_note_spawner = $SphereRailContainer/staticRailCenter
		note_handler.sphere_note_spawner = $SphereRailContainer/SphereRailCenter

	
	if judgement:
		judgement.score_init()
		judgement.total_notes = notes.size()
	
	print("[GameSceneFrameManager] 帧系统初始化完成，准备开始游戏")

## 开始基于帧的游戏循环
func start_frame_based_game():
	print("[GameSceneFrameManager] 启动基于帧的游戏系统")
	
	# 播放音频
	if soundPlayer:
		soundPlayer.play()
	
	# 启动帧转译器
	frame_translator.start_game()

## 停止游戏
func stop_frame_based_game():
	frame_translator.stop_game()
	
	if soundPlayer and soundPlayer.playing:
		soundPlayer.stop()

## 处理note生成信号
func _on_note_should_spawn(note_data: Dictionary):
	if not note_handler:
		return
		
	print("[FrameManager] 生成note: ID=%d, 类型=%d, 帧=%d" % [
		note_data.id, note_data.note_type, note_data.spawn_frame
	])
	
	# 使用现有的note生成逻辑
	var note_instance = note_handler._spawn_from_data(note_data.original_data)
	
	# 记录note实例
	active_notes_map[note_data.id] = {
		"instance": note_instance,
		"data": note_data,
		"spawn_time": Time.get_ticks_msec()
	}

## 处理note销毁信号
func _on_note_should_destroy(note_id: int):
	if note_id in active_notes_map:
		var note_info = active_notes_map[note_id]
		
		print("[FrameManager] 销毁note: ID=%d, 存活时间=%dms" % [
			note_id, Time.get_ticks_msec() - note_info.spawn_time
		])
		
		# 销毁note实例
		if note_info.instance and is_instance_valid(note_info.instance):
			note_info.instance.queue_free()
		
		# 从活跃map中移除
		active_notes_map.erase(note_id)

## 处理帧状态更新
func _on_frame_state_updated(frame_data: Dictionary):
	if frame_debug_enabled:
		_debug_frame_state(frame_data)
	
	# 更新UI显示
	_update_game_displays(frame_data)
	
	# 处理游戏逻辑
	_process_game_logic(frame_data)

## 处理游戏逻辑
func _process_game_logic(frame_data: Dictionary):
	# 检查判定
	for note_data in frame_data.hit_notes:
		_check_note_judgement(note_data)
	
	# 处理hold note持续判定
	for note_data in frame_data.active_notes:
		if note_data.is_hold:
			_process_hold_note(note_data, frame_data.frame)

## 检查note判定
func _check_note_judgement(note_data: Dictionary):
	if not judgement:
		return
		
	# 这里可以集成现有的判定系统
	# 例如检查用户输入，计算命中精度等
	print("[FrameManager] 判定窗口: Note ID=%d, 帧=%d" % [note_data.id, note_data.hit_frame])

## 处理hold note
func _process_hold_note(note_data: Dictionary, current_frame: int):
	if current_frame >= note_data.hit_frame and current_frame <= note_data.hold_end_frame:
		# hold note持续期间的处理逻辑
		pass

## 更新游戏显示
func _update_game_displays(_frame_data: Dictionary):
	# 更新combo、分数等显示
	# 可以集成到现有的UI更新逻辑中
	pass

## 调试帧状态
func _debug_frame_state(frame_data: Dictionary):
	if frame_data.spawn_notes.size() > 0 or frame_data.events.size() > 0:
		print("[Debug] 帧 %d (%.1fms): %d个生成, %d个判定, %d个销毁, %d个事件, %d个活跃" % [
			frame_data.frame,
			frame_data.time_ms,
			frame_data.spawn_notes.size(),
			frame_data.hit_notes.size(), 
			frame_data.destroy_notes.size(),
			frame_data.events.size(),
			frame_data.active_notes.size()
		])

## 获取当前游戏状态
func get_game_state() -> Dictionary:
	return {
		"current_frame": frame_translator.get_current_frame(),
		"active_notes_count": active_notes_map.size(),
		"total_frames": frame_translator.total_frames,
		"is_playing": frame_translator.is_playing
	}

## 设置调试模式
func set_debug_mode(enabled: bool):
	frame_debug_enabled = enabled

## 手动跳转到指定帧（用于调试）
func debug_jump_to_frame(target_frame: int):
	# 清理当前状态
	for note_id in active_notes_map.keys():
		_on_note_should_destroy(note_id)
	
	# 重新初始化到目标帧
	frame_translator.current_frame = target_frame
	
	# 重新生成所有应该存在的notes
	var frame_state = frame_translator.get_frame_state(target_frame)
	for note_data in frame_state.active_notes:
		if note_data.spawn_frame <= target_frame:
			_on_note_should_spawn(note_data)

## 获取指定时间的帧状态（用于分析）
func analyze_time_range(start_ms: float, end_ms: float) -> Dictionary:
	var start_frame = frame_translator._ms_to_frame(start_ms)
	var end_frame = frame_translator._ms_to_frame(end_ms)
	
	var analysis = {
		"total_notes": 0,
		"events_count": 0,
		"note_types": {},
		"frame_range": [start_frame, end_frame]
	}
	
	for frame_idx in range(start_frame, end_frame + 1):
		var frame_state = frame_translator.get_frame_state(frame_idx)
		
		analysis.total_notes += frame_state.spawn_notes.size()
		analysis.events_count += frame_state.events.size()
		
		for note in frame_state.spawn_notes:
			var note_type = note.note_type
			if note_type in analysis.note_types:
				analysis.note_types[note_type] += 1
			else:
				analysis.note_types[note_type] = 1
	
	return analysis
