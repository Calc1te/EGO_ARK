extends Resource
class_name SaveData

@export var global_speed : float
@export var global_offset : int # ms
const SAVE_PATH = "user://save"
const SAVE_FILE_PATH = SAVE_PATH + "/save.tres"

func save():
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_absolute(SAVE_PATH)
	var result = ResourceSaver.save(self,SAVE_FILE_PATH)
	if result != OK:
		OS.alert("Failed to save save data! \n %s" %error_string(result), "Error")
