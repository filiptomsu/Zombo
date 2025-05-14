extends Node3D

func _ready():
	$AnimationPlayer.play("Death")
	await $AnimationPlayer.animation_finished
	queue_free()
