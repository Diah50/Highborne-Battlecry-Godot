tool
extends Node2D
class_name BodyWithAnimation
# This node implements animations for every unit in the game. It allows
# switching the sprites and using the same animation for every unit.

# Signals to report back to parent
signal hit
signal attack_finished
signal death

export(Texture) var head_texture setget set_head_texture, get_head_texture
export(Texture) var body_texture setget set_body_texture, get_body_texture
export(Texture) var left_texture setget set_left_texture, get_left_texture
export(Texture) var right_texture setget set_right_texture, get_right_texture

func get_animator():
  return $BodyAnimator

func get_animation_tree():
  return $AnimationTree

func _ready():
  $head.texture = head_texture
  $body.texture = body_texture
  $item_l.texture = left_texture
  $item_r.texture = right_texture

func set_head_texture(texture):
  head_texture = texture
  if is_inside_tree():
	$head.texture = texture

func get_head_texture():
  return head_texture

func set_body_texture(texture):
  body_texture = texture
  if is_inside_tree():
	$body.texture = texture

func get_body_texture():
  return body_texture

func set_left_texture(texture):
  left_texture = texture
  if is_inside_tree():
	$item_l.texture = texture

func get_left_texture():
  return left_texture

func set_right_texture(texture):
  right_texture = texture
  if is_inside_tree():
	$item_r.texture = texture

func get_right_texture():
  return right_texture


# Set direction of the animation
# The animationTree of this node supports selecting one of four different
# directional animations for: walking and attacking using a blendSpace2d
func set_direction(dir : Vector2):
  $AnimationTree.set("parameters/walk/direction/blend_position", dir)
  $AnimationTree.set("parameters/attackonehand/direction/blend_position", dir)
  $AnimationTree.set("parameters/attackonehand/attack/blend_position", dir)

# Set the animation to be played
# The animationTree has a stateMachine at the highest level, each node contains
# one animation with 4 directions in it. This functions selects the state at the
# highest (state machine) level
func set_animation(anim_name):
  var playback = $AnimationTree.get("parameters/playback")
  match anim_name:
	"walk":
	  playback.travel("walk")
	"attack":
	  if playback.get_current_node() == "attackonehand":
		playback.start("attackonehand")
	  else:
		playback.travel("attackonehand")
	"death":
	  playback.travel("death")

# these are called from animation player method track
func report_hit():
  emit_signal("hit")
func report_attack_finished():
  emit_signal("attack_finished")
func report_death():
  emit_signal("death")

func stop():
  var playback = $AnimationTree.get("parameters/playback")
  playback.stop()

# set team color shader parameters
func set_team_colors(team_no):
  # TODO: maybe do it in a nicer way? If you just change the
  # shader properties it changes in every scene. This way we
  # create a new shader first so that changes affect only
  # the calling instance
  $head.material = $head.material.duplicate()
  $body.material = $body.material.duplicate()
  $selection_circle.material = $selection_circle.material.duplicate()
  var color = Globals.get_team_color(team_no)
  $head.material.set_shader_param("color", color)
  $body.material.set_shader_param("color", color)
  $selection_circle.material.set_shader_param("color", color)

func set_selected(is_selected : bool) -> void:
  $selection_circle.visible = is_selected
