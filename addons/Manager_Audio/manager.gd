tool
extends EditorPlugin

var _print_prefix = "\tAddon:Manager_Audio | manager.gd"


func _enter_tree():
	add_autoload_singleton("Manager_Audio", "res://addons/Manager_Audio/Manager_Audio.gd")
	print("%s _enter_tree, add_autoload_singleton Manager_Audio"%[_print_prefix])

func _exit_tree():
	remove_autoload_singleton("Manager_Audio")
	print("%s _exit_tree, remove_autoload_singleton Manager_Audio"%[_print_prefix])
