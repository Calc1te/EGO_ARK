extends Node2D
class_name gameScene
@onready var note_spawner : noteRoot = $staticRailCenter
@export var spawnHeight :int = 800
@export var isTestNoteSpawn : int = 1
@export var globalSpeed : float = 5
@export var currentMusic : String
@onready var noteID : int = 0
@onready var soundPlayer : AudioStreamPlayer = $AudioStreamPlayer

const FRAME_RATE = 120
const SPEED_COEFFICIENT = 200

const DT_CRIT_PERFECT = 26
const DT_PERFECT = 40
const DT_GOOD = 60
const DT_BAD = 125

const SD_CRIT_PERFECT = 26
const SD_PERFECT = 40
const SD_GOOD = 60
const SD_BAD = 125


var referenceOffset
var noteArray = Array()
##test variable
@export var inFrame : int = 360
##
var frame : int
# 计算noteSpawnFrame的误差可能导致打击帧数前后偏移一帧
@onready var noteSpawnFrame : int = inFrame - (spawnHeight/(globalSpeed*SPEED_COEFFICIENT)*FRAME_RATE)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	var note = note_spawner.spawnNode(Note.NoteType.HoldStart, globalSpeed, noteID, inFrame)
	note.connect("noteDestroyed",_on_note_destroyed)
	noteArray.append(note)
	#print(noteArray)
	#setNoteEnable() 
	noteID+=1
	
func setNoteEnable():
	if noteArray.size()>0:
			noteArray[0].isActivate = true

func _on_note_destroyed(acc):
	print("note destroyed: ",acc)
	noteArray.remove_at(0)
	calculate_acc(acc)
	pass
	
func calculate_acc(acc : int):
	#acc是按照毫秒计算不是帧数计算
	var hitError : int = abs(acc - referenceOffset)
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
