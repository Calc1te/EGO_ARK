extends Node2D
class_name gameScene

@onready var note_spawner : noteRoot = $staticRailCenter
@onready var noteID : int = 0
@onready var soundPlayer : AudioStreamPlayer = $AudioStreamPlayer
@onready var chartLoader : ChartLoader = $ChartLoader
@onready var comboDisplay : RichTextLabel = $combo
@onready var scoreDisplay : RichTextLabel = $score

@export var mainMenu : PackedScene
@export var spawnHeight :int = 800
@export var isTestNoteSpawn : int = 0
@export var currentMusic : String
@export var isDemoPlay : bool
@export var referenceOffset : float = 0

###### Game-Related Constants ######
const FRAME_RATE = 120 # Change this might break the whole judgement system
const SPEED_COEFFICIENT = 200

##### Judgement Constants ##### DT for central track #####
const DT_CRIT_PERFECT = 26
const DT_PERFECT = 40
const DT_GOOD = 60
const DT_BAD = 125
##### SD for semisphere tracks #####
const SD_CRIT_PERFECT = 26
const SD_PERFECT = 40
const SD_GOOD = 60
const SD_BAD = 125
##### hold and flick factor #####
const HOLD_SCALING = 0.5
const FLICK_SCALING = 0.9


###### Customized Options loaded before game start #####
@export var playerOffset : float = 0
@export var globalSpeed : float = 10
###### In-game variables ######
var noteArray = Array()
var singleNoteScore : float
var frame : int
var upcoming_notes : Array = []
var next_note_idx : int = 0
var current_BPM : int
var song_start_time : int
var entry

###### Game State Variables ######
var is_game_started : bool = false
var is_game_ended : bool = false

###### Score and Accuracy Variables ######
var current_score : int = 0
var max_combo : int = 0
var current_combo : int = 0
var total_notes : int = 0
var notes_hit : int = 0
var crit_perfect_count : int = 0
var perfect_count : int = 0
var good_count : int = 0
var bad_count : int = 0
var miss_count : int = 0
# 计算noteSpawnFrame的误差可能导致打击帧数前后偏移一帧

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chartLoader.connect("chart_loaded", _on_chart_loaded)
	chartLoader.load_chart(Global.current_song_select.chart_path)
	print("current offset: ", referenceOffset)
	frame = 0
	soundPlayer.stream = load(currentMusic)
	note_spawner.spawnHeight = spawnHeight
	referenceOffset = spawnHeight*10/(globalSpeed*2)
		
	# Start the game
	Global.state = Global.StateMachine.playing
	
	

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("spawn_note"):
		spawnNote() # this is a test function
	frame+=1
	var now_rel := Time.get_ticks_msec() - song_start_time
	while next_note_idx < upcoming_notes.size() && upcoming_notes[next_note_idx].spawn_time <= now_rel:
		entry = upcoming_notes[next_note_idx]
		_spawn_from_data(entry.data)
		next_note_idx += 1
	setNoteEnable()

		

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
		var note = note_spawner.spawnNote(note_type, spd*globalSpeed, next_note_idx, time, parameter if parameter else -1)
		note.connect("noteDestroyed",_on_note_destroyed)
		noteArray.append(note)

	else: pass # TODO: add hemisphere note



func spawnNote():
	var note = note_spawner.spawnNote(StatNote.NoteType.Slide, globalSpeed, noteID, Time.get_ticks_msec(), -1)
	note.connect("noteDestroyed",_on_note_destroyed)
	noteArray.append(note)
	#print(noteArray)
	#setNoteEnable() 
	noteID+=1
	
func setNoteEnable():
	noteArray = noteArray.filter(func(note): return is_instance_valid(note))
	if noteArray.size()>0:
			noteArray[0].isActivate = true


func _on_note_destroyed(acc, posY, holdDuration):
	#print("note destroyed: ",acc)
	noteArray.remove_at(0) 
	calculate_acc(acc, holdDuration)
	if isDemoPlay:
		drawDemoHit(posY)
	
	# Check if game should end
	check_game_end()


func check_game_end():
	if is_game_started and not is_game_ended:
		# Game ends when all notes are processed and no more notes are spawning
		if next_note_idx >= upcoming_notes.size() and noteArray.size() == 0:
			is_game_ended = true
			# send a signal to the stage clear node with judgement data
			print("Game ended!")
			var acc : float = get_accuracy()
			# TODO : move to clear screen


func get_accuracy() -> float:
	if total_notes == 0:
		return 0.0
	return (1*crit_perfect_count+.9*perfect_count+.3*good_count)/total_notes


func updateSpeed():
	referenceOffset = spawnHeight*10/(globalSpeed*2)
	print("speed Updated, new reference offset: ",referenceOffset)
	
	
func drawDemoHit(pos: int):
	
	var viewport_width = get_viewport().get_visible_rect().size.x
	
	var line_color = Color(1, 0, 0)  # 红色
	var line_width = 2.0
	
	# 绘制一条从左侧到右侧的直线，位置在 posY
	draw_line(Vector2(0, pos), Vector2(viewport_width, pos), line_color, line_width)
	
func calculate_acc(acc : int, holdError : int):
	print(acc, ",", holdError)
	#acc是按照毫秒计算不是帧数计算
	if acc == 1000 && holdError == -1:
		print("slide Perfect")
		add_score_and_combo("perfect")
		return
	var hitError : int = abs(acc - referenceOffset + playerOffset)
	print(acc - referenceOffset + playerOffset)
	if holdError == -1:
		if hitError > DT_BAD:
			print("miss")
			add_score_and_combo("miss")
		elif hitError < DT_BAD && hitError > DT_GOOD:
			print("bad")
			add_score_and_combo("bad")
		elif hitError < DT_GOOD && hitError > DT_PERFECT:
			print("good")
			add_score_and_combo("good")
		elif hitError < DT_PERFECT && hitError > DT_CRIT_PERFECT:
			print("perfect")
			add_score_and_combo("perfect")
		elif hitError < DT_CRIT_PERFECT:
			print("crit perfect")
			add_score_and_combo("crit_perfect")

	else:
		hitError = int(hitError+holdError*HOLD_SCALING)
		print(hitError)
		if hitError > DT_BAD:
			print("miss")
			add_score_and_combo("miss")
		elif hitError < DT_BAD && hitError > DT_GOOD:
			print("bad")
			add_score_and_combo("bad")
		elif hitError < DT_GOOD && hitError > DT_PERFECT:
			print("good")
			add_score_and_combo("good")
		elif hitError < DT_PERFECT && hitError > DT_CRIT_PERFECT:
			print("perfect")
			add_score_and_combo("perfect")
		elif hitError < DT_CRIT_PERFECT:
			print("crit perfect")
			add_score_and_combo("crit_perfect")


func add_score_and_combo(judgement: String):
	if not is_game_started or is_game_ended:
		return
	
	match judgement:
		"crit_perfect":
			current_score += int(singleNoteScore * 1.0)
			current_combo += 1
			crit_perfect_count += 1
			notes_hit += 1
		"perfect":
			current_score += int(singleNoteScore * 1.0)
			current_combo += 1
			perfect_count += 1
			notes_hit += 1
		"good":
			current_score += int(singleNoteScore * 0.7)
			current_combo += 1
			good_count += 1
			notes_hit += 1
		"bad":
			current_score += int(singleNoteScore * 0.1)
			current_combo = 0
			bad_count += 1
			notes_hit += 1
		"miss":
			current_combo = 0
			miss_count += 1
	
	# Update max combo
	if current_combo > max_combo:
		max_combo = current_combo
	
	# Update displays
	update_displays()


func update_displays():
	if scoreDisplay:
		scoreDisplay.text = str(current_score)
	if comboDisplay:
		comboDisplay.text = str(current_combo)


func _on_chart_loaded(data: Dictionary, events: Array, notes: Array) -> void:
	# TODO implement event array
	print("chart_loaded")
	currentMusic = data["AudioFilePath"]
	current_BPM = data["BPM"]
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
	total_notes = notes.size()
	score_init(total_notes)
	

func _compute_travel_time_ms() -> float:
	return spawnHeight / (globalSpeed * SPEED_COEFFICIENT) * 1000.0

func _sort_by_spawn_time(a, b) -> bool:
	return a["spawn_time"] < b["spawn_time"]

func score_init(maxCombo : int) -> void:
	singleNoteScore = 100000.0/maxCombo
	pass
