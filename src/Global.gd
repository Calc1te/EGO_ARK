extends Node
class_name GameState
enum StateMachine { playing, previewing, clearing, songSelect, others }

var state = StateMachine.others # should be set to others when game just started
var current_song_select : SongData = null
var current_chart_select : ChartData = null

var activate_song_library : Array[SongData] = []

# shouldn't put in global, but let's save it here anyway (temp)
func load_song_library(chpt : int):
	var path = "res://songs/chpt{chpt}"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != '':
			if file_name.contains('.yaml'):
				pass
	return activate_song_library

func set_current(song : SongData, chart : ChartData):
	current_song_select = song
	current_chart_select = chart


func get_current_song() -> SongData:
	return current_song_select

func get_current_chart() -> ChartData:
	return current_chart_select
