"""
集成说明：如何在现有的game_scene.gd中使用帧转译系统

这个文件展示了如何将帧转译系统集成到现有项目中的步骤和方法。

=== 核心实现思路 ===

节奏游戏的铺面转译主要包含以下几个步骤：

1. **数据预处理阶段**：
   - 将基于毫秒时间的note数据转换为基于帧的数据
   - 计算每个note的生成帧、判定帧、销毁帧
   - 预处理所有events的触发帧

2. **帧状态构建阶段**：
   - 为每一帧构建状态数据结构
   - 包含该帧需要生成/销毁的notes
   - 包含该帧需要触发的events
   - 包含该帧活跃的所有notes列表

3. **实时轮询阶段**：
   - 每物理帧根据音频时间计算目标帧
   - 处理从上次帧到目标帧之间的所有帧状态
   - 发送相应的生成/销毁信号

4. **音频同步机制**：
   - 使用AudioServer获取精确的音频播放时间
   - 考虑音频延迟和系统延迟
   - 支持帧追赶机制防止掉帧

=== 集成步骤 ===

## 步骤1: 在game_scene.gd中添加帧转译器

```gdscript
# 在现有变量声明区域添加
var frame_translator

# 在_ready()函数中初始化
func _ready() -> void:
    # ...现有代码...
    
    # 初始化帧转译系统
    var translator_script = load("res://src/gameScenes/chart_frame_translator.gd")
    frame_translator = translator_script.new()
    add_child(frame_translator)
    
    # 连接信号
    frame_translator.note_should_spawn.connect(_on_frame_note_spawn)
    frame_translator.note_should_destroy.connect(_on_frame_note_destroy)
    frame_translator.frame_state_updated.connect(_on_frame_state_updated)
```

## 步骤2: 修改chart加载逻辑

```gdscript
func _on_chart_loaded(data: Dictionary, events: Array, notes: Array) -> void:
    # ...现有的BPM设置等代码...
    
    # 初始化帧转译器（替代原有的_build_note_array调用）
    frame_translator.initialize(data, notes, events, soundPlayer)
    
    # ...其他设置...
    
    # 启动游戏
    soundPlayer.play()
    frame_translator.start_game()  # 替代原有的时间记录
```

## 步骤3: 简化_physics_process

```gdscript
func _physics_process(_delta: float) -> void:
    frame += 1
    
    # 帧转译器会自动处理note的生成和销毁
    # 这里只需要处理UI更新和游戏状态检查
    note_handler.setNoteEnable()
    event_handler._process_event(_delta)
    check_game_end()
    update_displays()
```

## 步骤4: 添加信号处理函数

```gdscript
func _on_frame_note_spawn(note_data: Dictionary):
    # 使用现有的note生成逻辑
    note_handler._spawn_from_data(note_data.original_data)

func _on_frame_note_destroy(note_id: int):
    # 可选：处理note销毁逻辑
    # 例如：从活跃note列表中移除
    pass

func _on_frame_state_updated(frame_data: Dictionary):
    # 处理frame events
    for event in frame_data.events:
        match event.type:
            0:  # BPM change
                if event.params.size() > 0:
                    note_handler.current_BPM = event.params[0]
            1:  # 轨道初始化
                # 调用现有的轨道初始化逻辑
                pass
            # ... 其他event类型
```

=== 系统优势对比 ===

**传统基于时间的系统**：
- 依赖实时时间计算
- 需要维护note队列和索引
- 容易出现时间漂移
- 难以实现精确的帧同步

**新的帧转译系统**：
- 预计算所有帧状态，性能更好
- 精确的帧级别控制
- 易于实现暂停、快进、回放等功能
- 更好的调试支持
- 支持复杂的时间特效

=== 调试和分析功能 ===

```gdscript
# 查看指定帧的详细状态
var frame_state = frame_translator.get_frame_state(1200)
print("帧1200: 生成%d个note, 销毁%d个note" % [
    frame_state.spawn_notes.size(),
    frame_state.destroy_notes.size()
])

# 分析指定时间段的note分布
var analysis = frame_translator.analyze_time_range(30000, 35000)
print("30-35秒区间: 总共%d个note, 类型分布: %s" % [
    analysis.total_notes,
    str(analysis.note_types)
])

# 调试输出帧范围信息
frame_translator.debug_print_frame_range(1000, 1200)
```

=== 性能优化建议 ===

1. **内存优化**：
   - 对于很长的歌曲，可以考虑分段加载帧状态
   - 使用对象池管理note实例

2. **计算优化**：
   - 预计算阶段可以在后台线程进行
   - 缓存常用的计算结果

3. **精度平衡**：
   - 120FPS提供了很好的精度，但可以根据需要调整
   - 可以为不同类型的note使用不同的精度要求

=== 扩展功能建议 ===

1. **时间控制**：
   - 实现暂停/继续功能
   - 支持倍速播放
   - 支持跳转到指定时间点

2. **可视化调试**：
   - 生成铺面的时间轴图表
   - 实时显示当前帧状态
   - note密度分析图

3. **自动化测试**：
   - 基于帧状态的自动播放
   - 铺面难度分析
   - 性能基准测试
"""
