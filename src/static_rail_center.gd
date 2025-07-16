extends Node2D
class_name noteRoot

@export var autoPlay: bool = false
@export var noteScene : PackedScene

@onready var touchJudgementArea : TouchScreenButton = $TouchScreenButton

var active_notes = []
# 旋转直接修改当前轨道的rotation 弧度制
var spawnHeight : int
var horizontalOffset : float # pixels
const SPEED_COEFFICIENT : int = 200

func _ready() -> void:
	touchJudgementArea.connect("pressed", _touch_pressed)
	touchJudgementArea.connect("released", _touch_released)



func spawnNote(note_type : StatNote.NoteType, speed : float, noteID : int, inTime : int, holdDuration : int):
	speed = SPEED_COEFFICIENT * speed
	var instance = noteScene.instantiate()
	instance.position.y = -spawnHeight
	instance.position.x = 0
	instance.thisNoteType = note_type
	instance.speed = speed
	instance.noteID = noteID
	instance.inTime = inTime               # 传入真正的判定时间
	instance.durationTime = holdDuration   # 对 Hold 有效
	add_child(instance)
	active_notes.append(instance)
	instance.connect("tree_exiting", Callable(self, "_remove_note_from_active").bind(instance))
	instance.connect("judgementEnabled", Callable(self, "_on_judge_enabled"))
	return instance

func _remove_note_from_active(note):
	active_notes.erase(note)

func _touch_pressed():
	# print("nR Pressed")
	for note in active_notes:
		if typeof(note) != TYPE_NIL:
			match note.thisNoteType:
				StatNote.NoteType.Tap:
					note._tap_hit()
				StatNote.NoteType.HoldStart:
					note._hold_start()
			
			

func _touch_released():
	# print("nR released")
	for note in active_notes:
		match note.thisNoteType:
			StatNote.NoteType.HoldStart:
				note._hold_end()


func _on_judge_enabled(node: Node2D) -> void:
	if not autoPlay:
		return

	node.isAutoPlay = true
	if node.thisNoteType in [StatNote.NoteType.Tap, StatNote.NoteType.Slide, StatNote.NoteType.Flick]:
		var delay : float = (522.0-400) / node.speed
		print(delay)
		await get_tree().create_timer(delay).timeout
		node._tap_hit()    
		return

	if node.thisNoteType == StatNote.NoteType.HoldStart:
		var start_delay : float = (522.0-400) / node.speed
		await get_tree().create_timer(start_delay).timeout
		node._start_hold()


		var end_delay : float = start_delay + node.durationTime 
		await get_tree().create_timer(end_delay).timeout
		node._end_hold()
