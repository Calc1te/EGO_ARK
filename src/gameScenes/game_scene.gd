extends Node2D
class_name gameScene

@onready var note_spawner : NoteRoot
@onready var noteID : int = 0

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

@export var mainMenu : PackedScene
@export var spawnHeight : int = 800
@export var isTestNoteSpawn : int = 0
@export var currentMusic : String
@export var isAutoPlay : bool
@export var isCalibration : bool

###### debug
@onready var new_rail_button : Button = $Button

###### Game-Related Constants ######
const FRAME_RATE = 120 # Change this might break the whole judgement system
const SPEED_COEFFICIENT = 200

###### In-game variables ######
var noteArray = Array()
var singleNoteScore : float
var frame : int
var upcoming_notes : Array = []
var next_note_idx : int = 0
var song_start_time : int
var entry # the fuck is entry

###### Game State Variables ######
var is_game_started : bool = false
var is_game_ended : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chartLoader.connect("chart_loaded", _on_chart_loaded)
	chartLoader.load_chart("res://charts/dummy_chart.yaml")
	print("current offset: ", judgement.referenceOffset_static)
	frame = 0
	soundPlayer.stream = load(currentMusic)
	# fixme: thi should be changed since the logic is different now
	note_spawner = $"SphereRailContainer/staticRailCenter"	
	# if u write 
	# note_spawner = $SphereRailContainer/SphereRailCenter/staticRailCenter
	# instead, then this shi won't work somehow
	note_spawner.spawnHeight = spawnHeight
	judgement.updateSpeed(spawnHeight)
	
	note_handler.initialize(note_spawner, judgement)
	note_handler.connect("gameplay_BPM_change",note_handler._on_BPM_change)

	event_handler.connect("linear_rail_init", lineRailContainer.on_linear_rail_init)
	event_handler.connect("linear_rail_destroy", lineRailContainer.on_linear_rail_destroy)
	event_handler.connect("rail_registered", lineRailContainer.on_linear_rail_init)
	event_handler.connect("lrail_destroyed", lineRailContainer.on_linear_rail_destroy)

	soundPlayer.play()
	
	if isCalibration:
		note_handler.connect("calibration",drawDemoHit)
	# Start the game
	Global.state = Global.StateMachine.playing
	
	

func _physics_process(_delta: float) -> void:
	frame+=1
	var now_rel := Time.get_ticks_msec() - song_start_time
	while next_note_idx < upcoming_notes.size() && upcoming_notes[next_note_idx].spawn_time <= now_rel:
		entry = upcoming_notes[next_note_idx]
		note_handler._spawn_from_data(entry.data)
		next_note_idx += 1
	note_handler.setNoteEnable()
	event_handler._process_event(_delta)

func check_game_end():
	if is_game_started and not is_game_ended:
		# Game ends when all notes are processed and no more notes are spawning
		if next_note_idx >= upcoming_notes.size() and note_handler.noteArray.size() == 0:
			is_game_ended = true
			# send a signal to the stage clear node with judgement data
			print("Game ended!")
			var acc : float = judgement.get_accuracy()
			# TODO : move to clear screen
	
func drawDemoHit(_acc,posY,_holdDuration):
	
	var viewport_width = get_viewport().get_visible_rect().size.x
	
	var line_color = Color(1, 0, 0)  # 红色
	var line_width = 2.0
	
	# 绘制一条从左侧到右侧的直线，位置在 posY
	draw_line(Vector2(0, posY), Vector2(viewport_width, posY), line_color, line_width)


func update_displays():
	if scoreDisplay:
		scoreDisplay.text = str(judgement.current_score)
	if comboDisplay:
		comboDisplay.text = str(judgement.current_combo)


func _on_chart_loaded(data: Dictionary, events: Array, notes: Array) -> void:
	print("chart_loaded")
	frameTranslator.initialize(data, notes, events, soundPlayer)





func _on_button_button_down() -> void:
	lineRailContainer.on_linear_rail_init("test", Vector2(128,128), 0)


func soundPlayback() -> float:
	var time = soundPlayer.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return time
