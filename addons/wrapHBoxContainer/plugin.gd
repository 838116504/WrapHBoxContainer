tool
extends EditorPlugin

var addedClassPathes = []

func _enter_tree():
	add_class("WrapHBoxContainer", "Container", "wrapHBoxContainer.gd")
	get_editor_interface().get_file_system_dock().connect("file_removed", self, "_on_file_remove")
	get_editor_interface().get_file_system_dock().connect("files_moved", self, "_on_files_moved")


func _exit_tree():
	remove_classes()
	if get_editor_interface().get_file_system_dock().is_connected("file_removed", self, "_on_file_remove"):
		get_editor_interface().get_file_system_dock().disconnect("file_removed", self, "_on_file_remove")
	if get_editor_interface().get_file_system_dock().is_connected("files_moved", self, "_on_files_moved"):
		get_editor_interface().get_file_system_dock().disconnect("files_moved", self, "_on_files_moved")


func _on_file_remove(p_path):
	var find = addedClassPathes.find(p_path)
	if find >= 0:
		addedClassPathes.remove(find)

func _on_files_moved(p_oldPath, p_newPath):
	var find = addedClassPathes.find(p_oldPath)
	if find >= 0:
		addedClassPathes.remove(find)
		addedClassPathes.append(p_newPath)

func add_class(p_name:String, p_base:String, p_path:String, p_icon:String = ""):
	p_path = path_fix(p_path)
	var dir = Directory.new()
	if !dir.file_exists(p_path):
		printerr("File ", p_path, " does not exist")
		return
	
	var fp = File.new()
	var err = fp.open(p_path, File.READ)
	if err != OK:
		printerr("Load file ", p_path, " failed.", " Err = ", err)
		return
	
	var code = fp.get_as_text()
	fp.close()
	var newCode = remove_class_name(code)
	if newCode:
		code = newCode
	var lineRegex = RegEx.new()
	lineRegex.compile("\n")
	var result = lineRegex.search(code)
	if result:
		code = code.insert(result.get_end(), "class_name " + p_name + "\n")
	else:
		code = code.insert(0, "class_name " + p_name + "\n")
	err = fp.open(p_path, File.WRITE)
	if err != OK:
		printerr("Load file ", p_path, " failed.", " Err = ", err)
		return
	fp.store_string(code)
	fp.close()
	get_editor_interface().get_resource_filesystem().update_file(p_path)
	#print("code = ", code)
	#script.reload()
#	var data = []
#	if ProjectSettings.has_setting("_global_script_classes"):
#		data = ProjectSettings.get_setting("_global_script_classes")
#		for i in data:
#			if i['class'] == p_name:
#				if i.path != p_path:
#					printerr("Already has class " + p_name + ", it path is " + i.path)
#				else:
#					addedClasses.append(p_name)
#				return
#
#	data.append({"base":p_base, "class":p_name, "language":"GDScript", "path":p_path})
#	ProjectSettings.set_setting("_global_script_classes", data)
#
#	var iconData = {}
#	if ProjectSettings.has_setting("_global_script_class_icons"):
#		iconData = ProjectSettings.get_setting("_global_script_class_icons")
#	iconData[p_name] = p_icon
#	ProjectSettings.set_setting("_global_script_class_icons", iconData)
#	ProjectSettings.save()
	
	addedClassPathes.append(p_path)
	get_editor_interface().get_resource_filesystem().scan()
	get_editor_interface().get_resource_filesystem().update_script_classes()

func remove_classes():
	var code
	var fp := File.new()
	var err
	for path in addedClassPathes:
		err = fp.open(path, File.READ)
		if err != OK:
			printerr("Load file ", path, " failed.", " Err = ", err)
			continue
		code = fp.get_as_text()
		fp.close()
		code = remove_class_name(code)
		if code:
			err = fp.open(path, File.WRITE)
			if err != OK:
				printerr("Load file ", path, " failed.", " Err = ", err)
				continue
			fp.store_string(code)
			#print("code = ", code)
			fp.close()
			get_editor_interface().get_resource_filesystem().update_file(path)
			#script.reload()
#	var changed = false
#	if ProjectSettings.has_setting("_global_script_classes"):
#		var data = ProjectSettings.get_setting("_global_script_classes")
#		for i in data:
#			var find = addedClasses.find(i['class'])
#			if find >= 0:
#				data.erase(i)
#		if data.size() == 0:
#			data = null
#		ProjectSettings.set_setting("_global_script_classes", data)
#		changed = true
#	if ProjectSettings.has_setting("_global_script_class_icons"):
#		var data = ProjectSettings.get_setting("_global_script_class_icons")
#		for i in addedClasses:
#			if data.has(i):
#				data.erase(i)
#		if data.size() == 0:
#			data = null
#		ProjectSettings.set_setting("_global_script_class_icons", data)
#		changed = true
#
#	if changed:
#		ProjectSettings.save()
	
	addedClassPathes.clear()
	get_editor_interface().get_resource_filesystem().scan()
	get_editor_interface().get_resource_filesystem().update_script_classes()

func path_fix(p_path:String):
	p_path = p_path.replace("\\", "/")
	var find = p_path.find(":/")
	if find < 0:
		var curDir = get_script().get_path().get_base_dir() + "/"
		p_path = curDir + p_path
	return p_path

func remove_class_name(p_code:String):
	var regex = RegEx.new()
	regex.compile("(#|[^\\\\]'|^'|[^\\\\]\"|^\"|^class_name[^0-9a-zA-Z_\\(]|[^0-9a-zA-Z_\\.]class_name[^0-9a-zA-Z_\\(])")
	var lineRegex = RegEx.new()
	lineRegex.compile("\n")
	var strRegex = RegEx.new()
	strRegex.compile("([^\\\\]\"|^\")")
	var strRegex2 = RegEx.new()
	strRegex2.compile("([^\\\\]'|^')")
	var result
	var classNameRegex = RegEx.new()
	classNameRegex.compile("(\n|#)")
	result = regex.search(p_code, 0)
	var s
	var reload = false
	while result:
		s = result.get_start()
		if p_code[s] == '#':
			result = lineRegex.search(p_code, result.get_end())
			if result:
				result = regex.search(p_code, result.get_end())
		elif p_code[s] == '"':
			result = strRegex.search(p_code, result.get_end())
			if result:
				result = regex.search(p_code, result.get_end())
		elif p_code[s] == "'":
			result = strRegex2.search(p_code, result.get_end())
			if result:
				result = regex.search(p_code, result.get_end())
		elif p_code[s] == 'c':
			result = classNameRegex.search(p_code, result.get_end())
			var end = p_code.length()
			if result:
				end = result.get_start()
			p_code.erase(s, end - s)
			reload = true
			break
		elif p_code[s + 1] == '"':
			result = strRegex.search(p_code, result.get_end())
			if result:
				result = regex.search(p_code, result.get_end())
		elif p_code[s + 1] == "'":
			result = strRegex2.search(p_code, result.get_end())
			if result:
				result = regex.search(p_code, result.get_end())
		elif p_code[s + 1] == 'c':
			result = classNameRegex.search(p_code, result.get_end())
			var end = p_code.length()
			if result:
				end = result.get_start()
			p_code.erase(s, end - s)
			reload = true
			break
		else:
			break
	if reload:
		return p_code
	return null
