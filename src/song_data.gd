class_name SongData
extends Resource

enum ChartDifficulty {EZ,NM,HD,EX,MA,OT} # OT is saved for charts like april fools song
@export var chart_path : String
@export var difficulty : ChartDifficulty
@export var high_score : int
