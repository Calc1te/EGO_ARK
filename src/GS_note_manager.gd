extends Node
class_name GSNote

var note_spawner : noteRoot  # Will be set by parent
var noteArray = Array()
signal pass_destroy_to_GS(acc, posY, holdDuration)
var noteID : int = 0

func initialize(spawner: noteRoot):
	note_spawner = spawner

func spawnNote(note_type, speed, note_id, _parameter):
	var note = note_spawner.spawnNote(note_type, speed, note_id, Time.get_ticks_msec(), -1)
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