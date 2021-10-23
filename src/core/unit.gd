extends KinematicBody2D
class_name Unit
# Base unit class. This should be extended by every other unit

# Unit state enum
enum {NORMAL = 0, ATTACKING, DEAD}

enum Stance {PASSIVE = 0, OFFENSIVE, DEFENSIVE}

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
export var view_range = 500

export var team = Globals.TEAM1

var velocity = Vector2.ZERO
var target = null
var health = 3
var state = NORMAL
var type_name = "Unit"
var armor = 1
var magic_resist = 1
onready var animated_body : BodyWithAnimation = $BodyWithAnimation
onready var selection_area : Area2D = $UnitSelectionArea
onready var health_bar : ProgressBar = $HealthBar

var last_action = Action.NONE
var flow_field : Astar.FlowField = null
var stance = Stance.OFFENSIVE

# minimum distance to next target observed
var min_distance_to_target = INF
# number of times unit attempted to move closer to target
var nr_of_move_attempts = 0
# maximum number of attempts to get closer to target
const max_nr_of_move_attempts = 15

var stat_list:Dictionary setget , get_stat_list

func get_stat_list():
  stat_list['health'] = health
  stat_list['attack'] = attack
  stat_list['speed'] = speed
  stat_list['armor'] = armor
  stat_list['magic_resist'] = magic_resist
  return stat_list

func reset():
  health = max_health
  emit_signal("update_max_health", max_health)
  emit_signal("update_current_health", health)
  state = NORMAL
  target = null
  velocity = Vector2.ZERO

# Set collision based on team: Unit exists on its team collision layer,
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
  self.connect("update_current_health", health_bar, "set_current_health")
  health_bar.set_max_health(max_health)
  
func destination_unreachable(target_position):
  var delta : float = (target_position - position).length_squared()
  if delta < min_distance_to_target:
    min_distance_to_target = delta
    nr_of_move_attempts = 0
  if nr_of_move_attempts > max_nr_of_move_attempts:
    nr_of_move_attempts = 0
    return true
  else:
    nr_of_move_attempts += 1
  return false
  
func destination_reached(target_position, tolerance = 10):
  var delta : float = (target_position - position).length_squared()
  if delta < tolerance:
    return true
  return false
    
func seek(to_position):
  return (to_position - position).normalized()

func follow_flow_field():
  if flow_field.cell_size.length_squared() > (position - flow_field.goal).length_squared():
    return (flow_field.goal - position).normalized()
  return flow_field.get_closest_vector_to(position).normalized()

func avoid_collision():
  var area2d : Area2D = $Area2D
  var vector = Vector2.ZERO
  for body in area2d.get_overlapping_bodies():
    vector += position - body.position
  return vector
    

func _physics_process(_delta):
  if state == NORMAL:
    match last_action:
      Action.MOVE, Action.MOVE_AND_ATTACK:
        if destination_reached(flow_field.goal) or destination_unreachable(flow_field.goal):
          last_action = Action.NONE
          velocity = Vector2.ZERO
          min_distance_to_target = INF
          nr_of_move_attempts = 0
        else:
          if last_action == Action.MOVE_AND_ATTACK:
            var enemy = get_closest_enemy()
            if enemy:
              perform_action(Action.ATTACK, null, enemy)
          velocity = follow_flow_field()
          var vector = avoid_collision()
          velocity += vector * 30
          velocity = velocity.normalized() * speed
      Action.ATTACK:
        if is_within_range(target.position, attack_range):
          state = ATTACKING
          play_animation("attack")
          velocity = Vector2.ZERO
        else:
          velocity = seek(target.position)
          velocity = velocity.normalized() * speed
      Action.NONE:
        var enemy = get_closest_enemy()
        if enemy:
          perform_action(Action.ATTACK, null, enemy)
        else:
          var vector = avoid_collision()
          if vector != Vector2.ZERO:
            velocity = avoid_collision().normalized() * speed
          else:
            velocity = Vector2.ZERO
        

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
func take_damage(val, attacker):
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
  else:
    if stance == Stance.DEFENSIVE and last_action != Action.ATTACK:
      perform_action(Action.ATTACK, null, attacker)

# deal damage to current target
func deal_damage_to_target():
  if typeof(target) == TYPE_OBJECT:
    target.take_damage(attack, self)

# interrupt attack
func interrupt_attack():
  state = NORMAL
  if target != null and typeof(target) == TYPE_OBJECT:
    target.disconnect("died", self, "target_killed")
    target = null
    if last_action == Action.ATTACK:
      last_action = Action.NONE
  stop_all_animation()

# triggered by target if it dies to stop this unit from attacking
func target_killed(_unit):
  if state == ATTACKING:
    interrupt_attack()
  else:
    target = null
    if last_action == Action.ATTACK:
      last_action = Action.NONE
    velocity = Vector2.ZERO

# triggerd via animation node when the weapon swing happens to deal
# damage to target
func handle_hit(_projectile_sprite):
  deal_damage_to_target()

# triggered by animation node when attack is finished. Changes state
func handle_attack_finished():
  if state == ATTACKING:
    state = NORMAL

# triggered by animation node when the death animation finishes
func handle_death():
  queue_free()

# plays an animation. See BodyWithAnimation for details
func play_animation(anim_name):
  $BodyWithAnimation.set_direction(velocity.normalized())
  if "attack" == anim_name:
    $BodyWithAnimation.set_animation("onehand")
  elif "walk" == anim_name:
    $BodyWithAnimation.set_animation("walk")
  elif "death" == anim_name:
    $BodyWithAnimation.set_animation("death")

func stop_all_animation():
  $BodyWithAnimation.stop()

# Update animation. Called at the end of _physics_process
func update_animation():
  if state == NORMAL:
    if velocity.length() >= 10:
      play_animation("walk")


func set_selected(is_selected : bool) -> void:
  animated_body.set_selected(is_selected)

func get_actions():
  return [Action.new(Action.STOP),
          Action.new(Action.MOVE, Action.TARGET_POSITION),
          Action.new(Action.ATTACK, Action.TARGET_ENEMY),
          Action.new(Action.MOVE_AND_ATTACK, Action.TARGET_POSITION),
          Action.new(Action.DEFEND, Action.TARGET_FRIEND),
          Action.new(Action.DIE),
          Action.new(Action.CHANGE_STANCE, Action.TARGET_NONE,
            [Action.new(Action.STANCE_DEFENSIVE),
            Action.new(Action.STANCE_OFFENSIVE),
            Action.new(Action.STANCE_PASSIVE)])]

func perform_action(action_id : int, _world, new_target = null):
  last_action = action_id
  nr_of_move_attempts = 0
  min_distance_to_target = INF
  print_debug("Perform action " + str(action_id))
  match action_id:
    Action.DIE:
      velocity = Vector2.ZERO
      state = DEAD
      emit_signal("died", self)
      play_animation("death")
    Action.MOVE, Action.MOVE_AND_ATTACK:
      flow_field = new_target
      interrupt_attack()
    Action.ATTACK:
      if target != new_target:
        interrupt_attack()
        set_target(new_target)
    Action.STANCE_DEFENSIVE:
      stance = Stance.DEFENSIVE
    Action.STANCE_PASSIVE:
      stance = Stance.PASSIVE
    Action.STANCE_OFFENSIVE:
      stance = Stance.OFFENSIVE
    Action.STOP:
      velocity = Vector2.ZERO
      interrupt_attack()
      last_action = Action.NONE
    _:
      assert(false, "This action is not implemented yet")
      
func get_closest_enemy():
  if stance != Stance.OFFENSIVE:
    return null
    
  var circle_shape = CircleShape2D.new()
  circle_shape.radius = view_range
  var query : Physics2DShapeQueryParameters = Physics2DShapeQueryParameters.new()
  query.set_shape(circle_shape)
  query.transform = Transform2D(0, position)
  query.collision_layer = (~(1 << team) & 0xf)
  query.collide_with_areas = false
  query.collide_with_bodies = true
  
  var enemy = null
  var dist = INF
  var space = get_world_2d().direct_space_state
  for result in space.intersect_shape(query):
    var body = result["collider"]
    var diff = (body.position - position).length_squared()
    if diff < dist:
      dist = diff
      enemy = body
  return enemy
