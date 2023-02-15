@tool
extends EditorInspectorPlugin

# ******************************************************************************

var plugin: EditorPlugin
var checks = []

# ******************************************************************************

func find_properties(node, _children=[]):
	for child in node.get_children():
		if child.get_class().begins_with('EditorProperty'):
			_children.append(child)

		if child.get_child_count():
			find_properties(child, _children)

	return _children

func get_inspector_properties():
	var inspector = plugin.get_editor_interface().get_inspector()
	return find_properties(inspector)

# ------------------------------------------------------------------------------

func _can_handle(object) -> bool:
	return true

func _parse_end(object: Object) -> void:
	checks.clear()


	var prop = get_inspector_properties()[0]
	print(prop)
	print(prop.get_class())
	print(prop._get_property_list())

	for node in get_inspector_properties():
		var hbox = HBox.new()
		hbox.gui_input.connect(Callable(self._gui_input).bind(hbox))

		var check = hbox.add(Check.new())
		checks.append(check)
		check.property = node
		check.gui_input.connect(Callable(self._gui_input).bind(hbox))

		var parent = node.get_parent()
		parent.remove_child(node)
		parent.add_child(hbox)

		hbox.add(node)

		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.anchor_right = 1

var ctx = null

func _gui_input(event, source):
	if !(event is InputEventMouseButton) or !event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		if is_instance_valid(ctx):
			ctx.queue_free()

		var inspector = plugin.get_editor_interface().get_inspector()

		ctx = ContextMenu.new(inspector, self.item_selected)

		ctx.add_item('penis')
		ctx.add_item('also penis')

		var root = plugin.get_editor_interface().get_base_control()
		var pos = root.get_global_mouse_position()
		pos += root.get_screen_position()
		ctx.open(pos)
	
func item_selected(item):
	print(item)

# ******************************************************************************

class Check:
	extends CheckBox

	var property = null

	func _init() -> void:
		tooltip_text = 'Select this property'


class HBox:
	extends HBoxContainer

	func _init() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		anchor_right = 1

	func add(object):
		add_child(object)

		return object

class ContextMenu:
	extends PopupMenu

	signal item_selected(item)

	func _init(obj=null, cb=null):
		if obj:
			obj.add_child(self)

		if obj and cb:
			item_selected.connect(cb)

		index_pressed.connect(self._on_index_pressed)

	func open(pos=null):
		if pos:
			position = pos
		popup()

	func _on_index_pressed(idx):
		var item = get_item_text(idx)
		item_selected.emit(item)