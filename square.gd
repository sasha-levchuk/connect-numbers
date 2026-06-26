class_name Square extends Area2D

@export var outline: Sprite2D
@export var highlight: Sprite2D
@export var connection: Line2D
@export var label: Label
@export var number_color_fill: Polygon2D

var value: int


func _mouse_enter() -> void:
	Event.square_hovered.emit(self)
	%Hover.show()


func _mouse_exit() -> void:
	Event.square_unhovered.emit(self)
	%Hover.hide()


func connect_to(square: Square):
	var local_pos := square.position - position
	connection.set_point_position(1, local_pos)
	prints('connecting to', local_pos)
	connection.show()

