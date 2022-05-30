extends CanvasLayer
class_name UserInterface
# Implement the in-game user interface

signal perform_action(action_name)

onready var action_panel = $ActionPanel
onready var unit_details_panel = $UnitCommandPanel/UnitDetailsPanel

func _ready():
# warning-ignore:return_value_discarded
  action_panel.connect("perform_action", self, "receive_perform_action")

# Fill action panel
func setup_actions(action_list):
  action_panel.setup(action_list)

# empty action panel
func reset_actions():
  action_panel.empty()

# receive perform_action signal and forward it to the listeners
func receive_perform_action(action_name):
  emit_signal("perform_action", action_name)

# check if mouse is hovering over gui
func is_mouse_on_gui() -> bool:
  var mouse_pos = get_viewport().get_mouse_position()
  var rect = $GuiArea.get_rect()
  return rect.has_point(mouse_pos)

func setup_unit_details(stat_list : Dictionary, unit_portrait : Texture = null):
  unit_details_panel.activate_unit_details(stat_list)
  if unit_portrait == null:
	unit_details_panel.deactivate_portrait()
  else:
	unit_details_panel.activate_portrait(unit_portrait)

func reset_unit_details():
  unit_details_panel.deactivate_unit_details()
  unit_details_panel.deactivate_portrait()
