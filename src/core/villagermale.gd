extends Unit
class_name Villager
  
func _physics_process(delta):
  if state == NORMAL:
	if target != null:
	  match typeof(target):
		# Unit was just told to move
		TYPE_VECTOR2:
		  if goto(target):
			target = null
		# Something else as target. ATTACK!
		TYPE_OBJECT:
		  goto(target.position)
		  if is_within_range(target.position, attack_range):
			play_animation("attack")
			velocity = Vector2.ZERO
			state = ATTACKING     
  ._physics_process(delta)
      
func get_actions():
  return ["Destroy"]

func perform_action(action, _world):
  if action == "Destroy":
    emit_signal("died")
    queue_free()
