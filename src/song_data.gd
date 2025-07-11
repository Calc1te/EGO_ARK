class_name SongData
extends Resource

# song data + play data = current play song


@export var songID : int
@export var song_name : String
@export var artist : String
@export var cover : Texture
@export var wav_path : String
@export var preview_start : int
@export var preview_end   : int
@export var chart_id_array : Array[int]
@export var charts : Array[ChartData] = []
