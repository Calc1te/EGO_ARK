extends Node2D
class_name gameScene

@onready var note_spawner : noteRoot = $staticRailsContainer/staticRailCenter
@onready var noteID : int = 0
@onready var soundPlayer : AudioStreamPlayer = $AudioStreamPlayer
@onready var chartLoader : ChartLoader = $ChartLoader
@onready var comboDisplay : RichTextLabel = $combo
@onready var scoreDisplay : RichTextLabel = $score
@onready var judgement := GSJudge.new()
@onready var note_handler := GSNote.new()

@export var mainMenu : PackedScene
@export var spawnHeight : int = 800
@export var isTestNoteSpawn : int = 0
@export var currentMusic : String
@export var isDemoPlay : bool

###### Game-Related Constants ######
const FRAME_RATE = 120 # Change this might break the whole judgement system
const SPEED_COEFFICIENT = 200
###### In-game variables ######
var noteArray = Array()
var singleNoteScore : float
var frame : int
var upcoming_notes : Array = []
var next_note_idx : int = 0
var current_BPM : int
var song_start_time : int
var entry # the fuck is entry

###### Game State Variables ######
var is_game_started : bool = false
var is_game_ended : bool = false

# 计算noteSpawnFrame的误差可能导致打击帧数前后偏移一帧

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chartLoader.connect("chart_loaded", _on_chart_loaded)
	chartLoader.load_chart("res://charts/dummy_chart.yaml")
	print("current offset: ", judgement.referenceOffset)
	frame = 0
	soundPlayer.stream = load(currentMusic)
	var note_spawner = $staticRailsContainer/staticRailCenter
	note_spawner.spawnHeight = spawnHeight
	note_handler.initialize(note_spawner)
	judgement.referenceOffset = spawnHeight*10/(judgement.globalSpeed*2)
	note_handler.connect("pass_destroy_to_GS",_on_receive_hit)
	# Start the game
	Global.state = Global.StateMachine.playing
	
	

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("spawn_note"):
		note_handler.spawnNote(StatNote.NoteType.Tap, judgement.globalSpeed, frame, -1) # this is a test function
	frame+=1
	var now_rel := Time.get_ticks_msec() - song_start_time
	while next_note_idx < upcoming_notes.size() && upcoming_notes[next_note_idx].spawn_time <= now_rel:
		entry = upcoming_notes[next_note_idx]
		_spawn_from_data(entry.data)
		next_note_idx += 1
	note_handler.setNoteEnable()

		

func _spawn_from_data(note_data : Array):
	var time = note_data[0]
	var note_type
	match int(note_data[1]):
		11:
			note_type = StatNote.NoteType.Tap
		12:
			note_type = StatNote.NoteType.HoldStart
		13:
			note_type = StatNote.NoteType.Flick
		14:
			note_type = StatNote.NoteType.Slide
		
	var spd = note_data[2]
	var angle = note_data[3]
	var parameter = note_data[4]
	
	if note_data[1] < 20:
		var note = note_handler.note_spawner.spawnNote(note_type, spd*judgement.globalSpeed, next_note_idx, time, parameter if parameter else -1)
		note.connect("noteDestroyed",note_handler._on_note_destroyed)
		note_handler.noteArray.append(note)

	else: pass # TODO: add hemisphere note






func _on_receive_hit(acc, posY, holdDuration):
	judgement.calculate_acc(acc, holdDuration)
	if isDemoPlay:
		drawDemoHit(posY)
	
	# Check if game should end
	check_game_end()

func check_game_end():
	if is_game_started and not is_game_ended:
		# Game ends when all notes are processed and no more notes are spawning
		if next_note_idx >= upcoming_notes.size() and note_handler.noteArray.size() == 0:
			is_game_ended = true
			# send a signal to the stage clear node with judgement data
			print("Game ended!")
			var acc : float = judgement.get_accuracy()
			# TODO : move to clear screen




func updateSpeed():
	judgement.referenceOffset = spawnHeight*10/(judgement.globalSpeed*2)
	print("speed Updated, new reference offset: ",judgement.referenceOffset)
	
	
func drawDemoHit(pos: int):
	
	var viewport_width = get_viewport().get_visible_rect().size.x
	
	var line_color = Color(1, 0, 0)  # 红色
	var line_width = 2.0
	
	# 绘制一条从左侧到右侧的直线，位置在 posY
	draw_line(Vector2(0, pos), Vector2(viewport_width, pos), line_color, line_width)


func update_displays():
	if scoreDisplay:
		scoreDisplay.text = str(judgement.current_score)
	if comboDisplay:
		comboDisplay.text = str(judgement.current_combo)


func _on_chart_loaded(data: Dictionary, events: Array, notes: Array) -> void:
	# TODO implement event array
	print("chart_loaded")
	#currentMusic = data["AudioFilePath"]
	#current_BPM = data["BPM"]
	var travel_ms = _compute_travel_time_ms()

	for note_data in notes:
		var hit_time = note_data[0]
		var spawn_time = hit_time - travel_ms/note_data[2]
		upcoming_notes.append({
			"spawn_time": int(spawn_time),
			"data": note_data
		})
	upcoming_notes.sort_custom(_sort_by_spawn_time)
	song_start_time = Time.get_ticks_msec()
	judgement.total_notes = notes.size()
	judgement.score_init()
	

func _compute_travel_time_ms() -> float:
	return spawnHeight / (judgement.globalSpeed * SPEED_COEFFICIENT) * 1000.0

func _sort_by_spawn_time(a, b) -> bool:
	return a["spawn_time"] < b["spawn_time"]
