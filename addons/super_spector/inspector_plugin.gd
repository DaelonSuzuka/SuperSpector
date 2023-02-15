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

	# var prop = get_inspector_properties()[0]
	# print(prop)
	# var _class = prop.get_class()
	# print(_class)
	# print(ClassDB.class_exists(_class))
	# print(JSON.stringify(ClassDB.class_get_method_list(_class)))
	# print(prop._get_property_list())

	for property in get_inspector_properties():
		var hbox = HBox.new()
		hbox.gui_input.connect(Callable(self._gui_input).bind(hbox))

		var check = hbox.add(Check.new(property))
		checks.append(check)
		check.gui_input.connect(Callable(self._gui_input).bind(check))
		check.mouse_entered.connect(Callable(self.mouse_entered).bind(check))

		var parent = property.get_parent()
		parent.remove_child(property)
		parent.add_child(hbox)

		hbox.add(property)

		property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		property.anchor_right = 1

var ctx = null
var dragging = false
var dragged = false
var click_source = null
var target_state = false

func mouse_entered(source):
	if dragging:
		dragged = true
		if source != click_source:
			source.set_pressed(target_state)

func _gui_input(event, source):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if source is CheckBox:
				if event.pressed:
					dragging = true
					click_source = source
					target_state = !click_source.button_pressed
					click_source.button_pressed = !click_source.button_pressed
				if !event.pressed:
					if dragging:
						if !dragged:
							click_source.button_pressed = !click_source.button_pressed
						dragged = false
					dragging = false

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_instance_valid(ctx):
				ctx.queue_free()

			var inspector = plugin.get_editor_interface().get_inspector()

			ctx = ContextMenu.new(inspector, self.item_selected)

			ctx.add_item('Copy Selected Properties')
			ctx.add_item('Paste Selected Properties')
			ctx.add_separator()
			ctx.add_item('Select All in Category')
			ctx.add_item('Select All in Section')
			ctx.add_item('Clear Selected Properties')

			var root = plugin.get_editor_interface().get_base_control()
			var pos = root.get_global_mouse_position()
			pos += root.get_screen_position()
			ctx.open(pos)
	
func item_selected(item):
	print(item)

	match item:
		'Copy Selected Properties':
			pass
		'Paste Selected Properties':
			pass
		'Clear Selected Properties':
			for check in checks:
				check.button_pressed = false

# ******************************************************************************

class Check:
	extends CheckBox

	var property = null

	func _init(_property) -> void:
		property = _property

		# tooltip_text = _property.get_label()


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