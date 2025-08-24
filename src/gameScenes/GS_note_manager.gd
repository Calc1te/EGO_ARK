extends Node
class_name GSNote

var current_BPM : float
var ref_BPM : float
var sv_BPM_coefficient : float

var static_note_spawner : NoteRoot  # Will be set by parent
var sphere_note_spawner : SphereRailCenter 
var judgement : GSJudge

var noteArray = Array()
var linear_rails = {}

enum GenericNoteType  {Tap, Hold, Flick, Slide}

var next_note_idx : int = 0

signal calibration(acc, posY, holdDuration)
var noteID : int = 0

func initialize(spawner: NoteRoot, judge_util :GSJudge):
	self.note_spawner = spawner
	judgement = judge_util
	sv_BPM_coefficient = current_BPM/ref_BPM

	
func _on_BPM_change(BPM : float):
	current_BPM = BPM
	sv_BPM_coefficient = current_BPM/ref_BPM

func _on_linear_rail_registered(rail : Node2D):
	linear_rails[rail.name] = rail

func _on_linear_rail_destroyed(rail_name : String):
	linear_rails.erase(rail_name)

func setNoteEnable():
	noteArray = noteArray.filter(func(note): return is_instance_valid(note))
	if noteArray.size()>0:
			noteArray[0].isActivate = true

func _on_note_destroyed(acc, posY, holdDuration):
	#print("note destroyed: ",acc)
	noteArray.remove_at(0) 
	judgement.calculate_acc(acc, holdDuration)
	emit_signal("calibration",acc, posY, holdDuration)
	

func _spawn_from_data(note_data : Array):
	var time = note_data[0]
	var note_type = note_data[1]%10
	var spd = note_data[2]
	var angle = note_data[3]
	var parameter = note_data[4]
	
	if note_data[1] < 20:
		var note = static_note_spawner.spawnNote(note_type, spd*judgement.globalSpeed, next_note_idx, time, parameter if parameter else -1)
		note.connect("noteDestroyed",_on_note_destroyed)
		noteArray.append(note)

	elif note_data[1]<30:
		var note = sphere_note_spawner

	
