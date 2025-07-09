extends Node
class_name GameState
enum StateMachine { playing, previewing, clearing, songSelect, others }

var state = StateMachine.others # should be set to others when game just started
var current_song_select : SongData = null

var activate_song_library : Array[SongData] = []

func load_song_library(chpt : int):
	push_error("function not implemented")

func set_current(song : SongData):
	current_song_select = song

func get_current_song() -> SongData:
	return current_song_select
