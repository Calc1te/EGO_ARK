class_name ChartData
extends Resource

enum DiffCategory {EZ,NM,HD,EX,MA,OT}

@export var chartID : int
@export var chart_path : String
@export var chart_creator : String
@export var display_difficulty : int
@export var chart_difficulty : float
@export var difficulty_category : DiffCategory
@export var beatmapID : int
@export var enable_bpm_sv : bool
@export var high_score : int