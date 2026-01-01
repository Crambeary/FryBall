extends Node2D

@export var duration := 0.55

func play(pixel_radius: float, dir: Vector2) -> void:
    var sprite := $Sprite2D as Sprite2D
    if sprite and sprite.texture:
        var base_size := pixel_radius * 2.0
        sprite.scale = Vector2.ONE * base_size

    var mat := sprite.material as ShaderMaterial
    if mat:
        mat.set_shader_parameter("impact_dir", dir.normalized())
        mat.set_shader_parameter("t", 0.0)

    modulate.a = 1.0

    var tw := create_tween()
    if mat:
        tw.tween_method(func(v): mat.set_shader_parameter("t", v), 0.0, 1.0, duration)
    tw.parallel().tween_property(self, "modulate:a", 0.0, duration)
    tw.tween_callback(queue_free)
