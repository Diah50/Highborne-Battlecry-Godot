extends Unit
class_name SwordMan

func play_animation(anim_name):
  .play_animation(anim_name)
  $SwordShieldAnimator.play(anim_name)

func _physics_process(delta):
  if state == NORMAL:
    if target != null:
      match typeof(target):
        # Unit was just told to move
        TYPE_VECTOR2:
          if goto(target, 10):
            target = null
        # Something else as target. ATTACK!
        TYPE_OBJECT:
          goto(target.position)
          if is_within_range(target.position, attack_range):
            velocity = Vector2.ZERO
            state = ATTACKING
            play_animation("attack_down")

      
  ._physics_process(delta)
      
func get_actions():
  return ["Destroy"]

func perform_action(action, _world):
  if action == "Destroy":
    emit_signal("died")
    queue_free()
