extends Panel
# this implements the action panel in the user interface bottom left corner
var action_list_storage = null
var button_scene = preload("res://scenes/gui/ButtonPanel.tscn")
signal perform_action(action_name)

func _ready():
  empty()

# Setup panel buttons and actions
func setup(action_list):
  empty()
  action_list_storage = action_list
  fill(action_list)
	
func fill(action_list):
  for action in action_list:
	var button = button_scene.instance()
	button.action = action
	button.connect("perform_action", self, "receive_perform_action")
	$GridContainer.add_child(button)
	
func reset():
  empty()
  fill(action_list_storage)

# Empty the panel
func empty():
  for child in $GridContainer.get_children():
	child.queue_free()

# Forward the signal upwards
func receive_perform_action(action):
  if action.sublist != []:
	empty()
	fill(action.sublist)
  else:
	emit_signal("perform_action", action)
	reset()
