extends Node2D
class_name gameScene

@onready var note_spawner : noteRoot = $staticRailCenter
@onready var noteID : int = 0
@onready var soundPlayer : AudioStreamPlayer = $AudioStreamPlayer

@export var mainMenu : PackedScene
@export var spawnHeight :int = 800
@export var isTestNoteSpawn : int = 0
@export var currentMusic : String
@export var isDemoPlay : bool
@export var referenceOffset : float = 0

###### Game-Related Constants DO NOT MODIFY ######
const FRAME_RATE = 120
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

###### Customized Options loaded before game start #####
@export var playerOffset : float = 0
@export var globalSpeed : float = 10

var noteArray = Array()

###### test variable
@export var inFrame : int = 360
######
var frame : int
# 计算noteSpawnFrame的误差可能导致打击帧数前后偏移一帧
@onready var noteSpawnFrame : int = inFrame - (spawnHeight/(globalSpeed*SPEED_COEFFICIENT)*FRAME_RATE)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("current offset: ", referenceOffset)
	frame = 0
	soundPlayer.stream = load(currentMusic)
	note_spawner.spawnheight = spawnHeight
	referenceOffset = spawnHeight*10/(globalSpeed*2)
	

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("spawn_note"):
		spawnNote()
	if frame == noteSpawnFrame && isTestNoteSpawn:
		spawnNote() 
	#print("size",noteArray.size(),"index",noteArray)
	setNoteEnable()
	frame+=1
	#print(frame)

	

func spawnNote():
	var note = note_spawner.spawnNote(Note.NoteType.HoldStart, globalSpeed, noteID, inFrame)
	note.connect("noteDestroyed",_on_note_destroyed)
	noteArray.append(note)
	#print(noteArray)
	#setNoteEnable() 
	noteID+=1
	
func setNoteEnable():
	if noteArray.size()>0:
			noteArray[0].isActivate = true

func _on_note_destroyed(acc, posY):
	#print("note destroyed: ",acc)
	noteArray.remove_at(0) 
	calculate_acc(acc)
	if isDemoPlay:
		drawDemoHit(posY)
	
	
func updateSpeed():
	referenceOffset = spawnHeight*10/(globalSpeed*2)
	print("speed Updated, new reference offset: ",referenceOffset)
	
	
func drawDemoHit(pos: int):
	
	var viewport_width = get_viewport().get_visible_rect().size.x
	
	var line_color = Color(1, 0, 0)  # 红色
	var line_width = 2.0
	
	# 绘制一条从左侧到右侧的直线，位置在 posY
	draw_line(Vector2(0, pos), Vector2(viewport_width, pos), line_color, line_width)
	
func calculate_acc(acc : int):
	#acc是按照毫秒计算不是帧数计算
	var hitError : int = abs(acc - referenceOffset + playerOffset)
	if hitError > DT_BAD:
		print("miss")
	elif hitError < DT_BAD && hitError > DT_GOOD:
		print("bad")
	elif hitError < DT_GOOD && hitError > DT_PERFECT:
		print("good")
	elif hitError < DT_PERFECT && hitError > DT_CRIT_PERFECT:
		print("perfect")
	elif hitError < DT_CRIT_PERFECT:
		print("crit perfect")
	pass
