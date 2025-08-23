extends Node
class_name GSNote

var current_BPM : float
var ref_BPM : float
var sv_BPM_coefficient : float

var note_spawner : noteRoot  # Will be set by parent
var noteArray = Array()
var linear_rails = {}


signal pass_destroy_to_GS(acc, posY, holdDuration)
var noteID : int = 0

func initialize(spawner: noteRoot):
	note_spawner = spawner
	sv_BPM_coefficient = current_BPM/ref_BPM

	
func _on_BPM_change(BPM : float):
	current_BPM = BPM
	sv_BPM_coefficient = current_BPM/ref_BPM

func _on_linear_rail_registered(rail : Node2D):
	linear_rails[rail.name] = rail

func _on_linear_rail_destroyed(rail_name : String):
	linear_rails.erase(rail_name)

func spawnNote(note_type, speed, note_id, _parameter):
	var note = note_spawner.spawnNote(note_type, speed*sv_BPM_coefficient, note_id, Time.get_ticks_msec(), -1)
	note.connect("noteDestroyed",Callable(self, "_on_note_destroyed"))
	noteArray.append(note)

func setNoteEnable():
	noteArray = noteArray.filter(func(note): return is_instance_valid(note))
	if noteArray.size()>0:
			noteArray[0].isActivate = true

func _on_note_destroyed(acc, posY, holdDuration):
	#print("note destroyed: ",acc)
	noteArray.remove_at(0) 
	emit_signal('pass_destroy_to_GS', acc, posY, holdDuration)