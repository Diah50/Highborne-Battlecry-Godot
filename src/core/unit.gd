extends KinematicBody2D
class_name Unit
# Base unit class. This should be extended by every other unit

# Unit state enum
enum {NORMAL = 0, ATTACKING, HURT, DEAD}

# Can be used to update the displayed unit health on a bar/gui panel
signal update_max_health(max_health)
signal update_current_health(current_health)

# Used to inform observers (e.g. attackers) that the unit is no longer alive
signal died(unit)

# Base statistic of a unit
export var speed = 3
export var attack = 3
export var max_health = 30
export var defense = 1
export var attack_range = 30

export var team = Globals.TEAM1


var velocity = Vector2.ZERO
var target = null
var health = 3
var state = NORMAL
var type_name = "Unit"
onready var animated_body : BodyWithAnimation = $BodyWithAnimation
onready var selection_area : Area2D = $UnitSelectionArea

func reset():
  health = max_health
  emit_signal("update_max_health", max_health)
  emit_signal("update_current_health", health)
  state = NORMAL
  target = null
  velocity = Vector2.ZERO

# Set collision based on team: Unit exits on its team collision layer,
# and collides with every other layer
func set_team(team_no):
  set_collision_layer(0x0)
  set_collision_layer_bit(team_no, true)
  set_collision_mask(0xff)
  selection_area.set_collision_layer(0x0)
  selection_area.set_collision_layer_bit(team_no, true)
  selection_area.set_collision_mask(0xff)
  $BodyWithAnimation.set_team_colors(team_no)

func _ready():
  reset()

  # Connect this unit ot its animation node
  var anim_body : BodyWithAnimation = $BodyWithAnimation
# warning-ignore:return_value_discarded
  anim_body.connect("hit", self, "handle_hit")
# warning-ignore:return_value_discarded
  anim_body.connect("attack_finished", self, "handle_attack_finished")
# warning-ignore:return_value_discarded
  anim_body.connect("death", self, "handle_death")
  set_team(team)


# set velocity to move the unit to specified position
func goto(position, tolerance = 2):
  var diff : Vector2 = position - transform.origin
  if diff.length() > tolerance:
	velocity = diff.normalized() * speed
	return false
  else:
	velocity = Vector2.ZERO
	return true

func _physics_process(_delta):
  velocity = move_and_slide(velocity, Vector2.UP)
  update_animation()

# set a new target, either a position or another unit
func set_target(new_target):
  if typeof(target) == TYPE_OBJECT:
	target.disconnect("died", self, "target_killed")
  if state == ATTACKING:
	interrupt_attack()
  target = new_target
  if typeof(target) == TYPE_OBJECT:
	target.connect("died", self, "target_killed")

# check if unit is within distance of point
func is_within_range(point : Vector2, distance):
  return (position - point).length_squared() < (distance * distance)

# Deal damage to this unit
func take_damage(val):
  health -= max((val - defense), 1)
  emit_signal("update_current_health", health)
  if health <= 0:
	interrupt_attack()
	emit_signal("died", self)
	state = DEAD
	velocity = Vector2.ZERO
	$CollisionShape2D.set_disabled(true)
	$UnitSelectionArea/CollisionShape2D.set_disabled(true)
	play_animation("death")

# deal damage to current target
func deal_damage_to_target():
  if typeof(target) == TYPE_OBJECT:
	target.take_damage(attack)

# interrupt attack
func interrupt_attack():
  state = NORMAL
  if target != null and typeof(target) == TYPE_OBJECT:
	target.disconnect("died", self, "target_killed")
	target = null
  stop_all_animation()

# triggered by target if it dies to stop this unit from attacking
func target_killed(_unit):
  if state == ATTACKING:
	interrupt_attack()
  else:
	target = null
	velocity = Vector2.ZERO

# triggerd via animation node when the weapon swing happens to deal
# damage to target
func handle_hit():
  deal_damage_to_target()

# triggered by animation node when attack is finished. Changes state
# back to normal to allow control of the unit
func handle_attack_finished():
  if state == ATTACKING:
	state = NORMAL

# triggered by animation node when the death animation finishes
func handle_death():
  queue_free()

# plays an animation. See BodyWithAnimation for details
func play_animation(anim_name):
  $BodyWithAnimation.set_direction(velocity.normalized())
  if "attack" in anim_name:
	$BodyWithAnimation.set_animation("attack")
  elif "walk" in anim_name:
	$BodyWithAnimation.set_animation("walk")
  elif "death" == anim_name:
	$BodyWithAnimation.set_animation("death")

func stop_all_animation():
  $BodyWithAnimation.stop()

# Update animation. Called at the end of _physics_process
func update_animation():
  if state == NORMAL:
	if velocity.length() < 10:
	  return
	if abs(velocity.x) > abs(velocity.y):
	  if velocity.x > 0.1:
		play_animation("walk_right")
	  elif velocity.x < -0.1:
		play_animation("walk_left")
	else:
	  if velocity.y > 0.1:
		play_animation("walk_down")
	  elif velocity.y < -0.1:
		play_animation("walk_up")


func set_selected(is_selected : bool) -> void:
  animated_body.set_selected(is_selected)

<<<<<<< Updated upstream

func get_actions():
  return ["Destroy"]

func perform_action(action, _world):
  if action == "Destroy":
    velocity = Vector2.ZERO
    state = DEAD
    emit_signal("died", self)
    play_animation("death")
=======
var action_list = [Action.new(Action.STOP),
				   Action.new(Action.MOVE, Action.TARGET_POSITION),
				   Action.new(Action.ATTACK, Action.TARGET_ANY),
				   Action.new(Action.MOVE_AND_ATTACK, Action.TARGET_POSITION),
				   Action.new(Action.DEFEND, Action.TARGET_FRIEND),
				   Action.new(Action.DIE),
				   Action.new(Action.CHANGE_STANCE, Action.TARGET_NONE,
					 [Action.new(Action.STANCE_DEFENSIVE),
					  Action.new(Action.STANCE_OFFENSIVE),
					  Action.new(Action.STANCE_PASSIVE)])]

func get_actions():
  return action_list

func perform_action(action_id : int, _world, new_target = null):
  match action_id:
	Action.DIE:
	  velocity = Vector2.ZERO
	  state = DEAD
	  emit_signal("died", self)
	  play_animation("death")
	Action.MOVE:
	  assert(typeof(new_target) == TYPE_VECTOR2)
	  set_target(new_target)
	Action.ATTACK:
	  assert(typeof(new_target) == TYPE_OBJECT)
	  set_target(new_target)
	_:
	  pass
>>>>>>> Stashed changes
