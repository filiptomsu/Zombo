extends Area3D

@export var demage := 1

signal body_part_hit(dam)

func hit():
	emit_signal("body_part_hit", demage)
