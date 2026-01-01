extends Node2D

@export var duration := 0.14
@export var start_scale := 0.85
@export var end_scale := 1.15

func play(pixel_radius: float) -> void:
    var sprite := $Sprite2D as Sprite2D
    if sprite and sprite.texture:
        var base_size := pixel_radius * 2.0
        sprite.scale = Vector2.ONE * base_size

    scale = Vector2.ONE * start_scale
    modulate.a = 1.0

    var t := create_tween()
    t.tween_property(self, "scale", Vector2.ONE * end_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.parallel().tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    t.tween_callback(queue_free)
