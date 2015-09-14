#Copyright(c) 2015 Jeremy Bayley. All rights reserved.
#This software is provided under The MIT License(MIT) 

#LOD script for terrain chunks. 
#will apply LOD to all children of node

extends Spatial

var terrainChunks = []
var terrainHiddenChunks = []
var renderDist = 5

func _ready():
	#Collect out terrain meshes
	for node in self.get_children():
		terrainChunks.append(node.get_name())
		print(terrainChunks)
	self.set_process(true)
	#print(get_child_count())


func _process(delta):
	for chunk in terrainChunks:
		var node = get_node(chunk)
		var nodeVec = node.get_translation()
		var camVec = get_node("../act_player").get_translation()
		#test if hidden
		if chunk in terrainHiddenChunks:
			#calc distance
			var dist = (sqrt(nodeVec.x*camVec.x + nodeVec.z*camVec.z)*1)
			#make visible
			if dist < renderDist:
				node.PAUSE_MODE_PROCESS
				terrainHiddenChunks.remove(chunk)
				print("added %s too visible" %(str(node)))
		else:
			#var dist = sqrt((chunkVec.x - camVec.x *2) + (chunkVec.z + camVec.z * 2))*1
			var dist = (sqrt(nodeVec.x*camVec.x + nodeVec.z*camVec.z)*1)
			print(dist)
			if dist > renderDist:
				#node.free()
				node.PAUSE_MODE_STOP				
				terrainHiddenChunks.append(chunk)
				print("added %s too hidden" %(str(node)))



