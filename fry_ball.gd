extends Node2D

@export var radius_px := 80.0

var _ring_scene: PackedScene = preload("res://absorb_ring.tscn")
var _impact_scene: PackedScene = preload("res://absorb_impact.tscn")

func play_absorb(angle_rad: float) -> void:
    var dir := Vector2(cos(angle_rad), sin(angle_rad))

    var impact := _impact_scene.instantiate() as Node2D
    $AbsorbFX.add_child(impact)
    impact.position = Vector2.ZERO
    if impact.has_method("play"):
        impact.call("play", radius_px, dir)

    var ring := _ring_scene.instantiate() as Node2D
    $AbsorbFX.add_child(ring)
    ring.position = dir * radius_px
    ring.rotation = angle_rad + PI * 0.5

    if ring.has_method("play"):
        ring.call("play", radius_px)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var angle := (get_global_mouse_position() - global_position).angle()
        play_absorb(angle)
