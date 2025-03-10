extends Node2D
class_name gameScene
@onready var note_spawner : noteRoot = $staticRailCenter
@export var spawnHeight :int = 800
@export var isTestNoteSpawn : int = 1
@export var globalSpeed : float = 10
@export var currentMusic : String
@onready var noteID : int = 0
@onready var soundPlayer : AudioStreamPlayer = $AudioStreamPlayer
var noteArray = Array()
##test variable
@export var inFrame : int = 360
##
var frame : int
@onready var noteSpawnFrame : int = inFrame - (spawnHeight/(globalSpeed*200)*120)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frame = 0
	soundPlayer.stream = load(currentMusic)
	note_spawner.spawnheight = spawnHeight

func _physics_process(delta: float) -> void:
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
	
# TODO: 改成每生成一个note执行一次？
func setNoteEnable():
	if noteArray.size()>0:
			noteArray[0].isActivate = true

func _on_note_destroyed(noteID, acc):
	print("note destroyed")
	noteArray.remove_at(0)
	pass
	
func calculate_acc():
	pass
