tool
extends Container


func _set(p_property, p_value):
	if p_property == "HSeparation" || p_property == "VSeparation":
		if p_value == null:
			add_constant_override(p_property, 0)
		else:
			add_constant_override(p_property, p_value)
	else:
		return false
	return true

func _get(p_property):
	if p_property == "HSeparation" || p_property == "VSeparation":
		return 0 if !has_constant_override(p_property) else get_constant(p_property)
	
	return null

func _get_property_list():
	var checkedUsage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_CHECKABLE | PROPERTY_USAGE_CHECKED
	var uncheckedUsage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_CHECKABLE
	var ret := []
	ret.append({"name":"HSeparation", "type":TYPE_INT, "hint":PROPERTY_HINT_RANGE, "hint_string":"0, 100, or_greater", "usage":checkedUsage if has_constant("HSeparation") else uncheckedUsage})
	ret.append({"name":"VSeparation", "type":TYPE_INT, "hint":PROPERTY_HINT_RANGE, "hint_string":"0, 100, or_greater", "usage":checkedUsage if has_constant("VSeparation") else uncheckedUsage})
	return ret

func _notification(p_what):
	if p_what == NOTIFICATION_SORT_CHILDREN:
		var lines = wrapline()
		var w = rect_size.x
		var ofy = 0
		var vSep = 0 if !has_constant("VSeparation") else get_constant("VSeparation")
		for l in lines:
			var nodeData := {}
			var stretch := 0
			var stretchNodes := []
			var stretchRatio = 0
			var temp
			var node
			for i in l.nodes.size():
				node = l.nodes[i]
				temp = [l.minSizes[i], bool(node.size_flags_horizontal & SIZE_EXPAND && node.size_flags_stretch_ratio > 0)]
				nodeData[node.get_instance_id()] = temp
				if temp[1]:
					stretch += temp[0].x
					stretchNodes.append(node)
					stretchRatio += node.size_flags_stretch_ratio
			var diff = max(w - l.w, 0)
			stretch += diff
			while stretchRatio > 0:
				var ok = true
				for i in stretchNodes.size():
					temp = nodeData[stretchNodes[i].get_instance_id()]
					if temp[0].x > stretchNodes[i].size_flags_stretch_ratio * stretch / stretchRatio:
						stretchNodes.remove(i)
						stretchRatio -= stretchNodes[i].size_flags_stretch_ratio
						stretch -= temp[0].x
						temp[1] = false
						ok = false
						break
				if ok:
					break
			
			var stretchCount := 0
			var restStretch = stretch
			var rect := Rect2(0, ofy, 0, l.h)
			var hSep = 0 if !has_constant("HSeparation") else get_constant("HSeparation")
			for n in l.nodes:
				temp = nodeData[n.get_instance_id()]
				if temp[1]:
					stretchCount += 1
					if stretchCount != stretchNodes.size():
						rect.size.x = node.size_flags_stretch_ratio * stretch / stretchRatio
						restStretch -= rect.size.x
					else:
						rect.size.x = restStretch
				else:
					rect.size.x = temp[0].x
				fit_child_in_rect(n, rect)
				rect.position.x += rect.size.x + hSep
			ofy += l.h + vSep

func _get_minimum_size():
	var lines = wrapline()
	var ret = Vector2.ZERO
	for i in lines.size():
		ret.y += lines[i].h
		for j in lines[i].minSizes.size():
			ret.x = max(ret.x, lines[i].minSizes[j].x)
	var vSep = 0 if !has_constant("VSeparation") else get_constant("VSeparation")
	ret.y += vSep * (lines.size() - 1)
	return ret

func get_containable_nodes() -> Array:
	var ret := []
	for i in get_children():
		if !i is Control || !i.visible || i.is_set_as_toplevel():
			continue
		ret.append(i)
	return ret

func wrapline() -> Array:
	var nodes = get_containable_nodes()
	if nodes.size() <= 0:
		return []
	
	var w = max(rect_size.x, rect_min_size.x)
	var nodesMinSize = []
	for node in nodes:
		nodesMinSize.append(node.get_combined_minimum_size())
		w = max(w, nodesMinSize.back().x)
	
	var lines := []
	var line := { 'w':nodesMinSize[0].x, 'h':nodesMinSize[0].y, 'nodes':[nodes[0]], 'minSizes': [nodesMinSize[0]] }
	var hSep = 0 if !has_constant("HSeparation") else get_constant("HSeparation")
	for i in range(1, nodes.size()):
		if line.w + nodesMinSize[i].x + hSep > w:
			lines.append(line)
			line = { 'w':nodesMinSize[i].x, 'h':nodesMinSize[i].y, 'nodes':[nodes[i]], 'minSizes': [nodesMinSize[i]]}
			continue
		line.w += nodesMinSize[i].x + hSep
		line.h = max(line.h, nodesMinSize[i].y)
		line.nodes.append(nodes[i])
		line.minSizes.append(nodesMinSize[i])
	if line.nodes.size() > 0:
		lines.append(line)
	
	return lines
