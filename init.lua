
--Todo make lift go up and down!

minetest.register_node("lifter:lift", {
	tiles = {"lifter.png"},
	description = "Lift",
	drawtype = "normal",
	paramtype = "light",
	groups = {crumbly=3},
	on_rightclick = function(pos, node, player, itemstack, pointed_thing) 
		local obj = minetest.add_entity(pos, "lifter:travelling_lift")
		minetest.remove_node(pos)
		
		if not player then
			return
		end
		
		obj:get_luaentity().driver = player

		player:set_attach(obj, "", {x=0, y=15, z=0}, {x=0, y=0, z=0})
		player:set_eye_offset({x=0, y=6, z=0},{x=0, y=0, z=0})
	end,
})

minetest.register_entity("lifter:travelling_lift", {
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.5,-0.5,-0.5, 0.5,2.5,0.5},
	visual = "cube",
	textures = {"lifter.png", "lifter.png", "lifter.png", "lifter.png", "lifter.png", "lifter.png"},
	--visual_size = {x=1, y=1},
	
	driver = nil,
	direction = 0,
	
	on_punch = function(self, dtime)
	end,
	
	on_step = function(self, dtime)
		local exit = false
		
		-- Turn to actual sand when collides to ground or just move
		local pos = self.object:getpos()
		local bcp = {x=pos.x, y=pos.y-0.7, z=pos.z} -- Position of bottom center point
		local bcn = minetest.get_node(bcp)
		local bcd = minetest.registered_nodes[bcn.name]
		-- Note: walkable is in the node definition, not in item groups
		local np = {x=bcp.x, y=bcp.y+1, z=bcp.z}
		
		if not self.driver then
			minetest.add_node(np, {name="lifter:lift"})
			self.object:remove()
			nodeupdate(np)
			return
		end
		
		local ctrl = self.driver:get_player_control()
		if ctrl.jump then
			self.direction = 1
		end
		if ctrl.sneak then
			self.direction = -1
		end
		if ctrl.aux1 then
			self.direction = 0
			self.object:setvelocity({x=0, y=0, z=0})
		end
		
		pos.y = pos.y+1
		local nex = 1
		local wnode = minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z})
		local wbnode = minetest.get_node({x=pos.x+1, y=pos.y-nex, z=pos.z})
		local snode = minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z})
		local sbnode = minetest.get_node({x=pos.x-1, y=pos.y-nex, z=pos.z})
		local anode = minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1})
		local abnode = minetest.get_node({x=pos.x, y=pos.y-nex, z=pos.z+1})
		local dnode = minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1})
		local dbnode = minetest.get_node({x=pos.x, y=pos.y-nex, z=pos.z-1})
		
		if self.direction ~= 0 and not ctrl.jump and not ctrl.sneak then
		 	if (wnode.name == "air" and wbnode.name ~= "air") or 
		 		(snode.name == "air" and sbnode.name ~= "air") or 
		 		(anode.name == "air" and abnode.name ~= "air") or 
		 		(dnode.name == "air" and dbnode.name ~= "air") then
				self.direction = 0
				self.object:setvelocity({x=0, y=0, z=0})
				self.object:setacceleration({x=0, y=0, z=0})
			end
		end
		
		if wnode.name == "air" and snode.name == "air" and anode.name == "air" and dnode.name == "air" then
			if self.direction >= 0  then
				self.direction = 0
				self.object:setvelocity({x=0, y=0, z=0})
			else 
				self.object:setacceleration({x=0, y=-10, z=0})
			end
		end
		
		local vel = self.object:getvelocity()
		if vector.equals(vel, {x=0,y=0,z=0}) then
			if ctrl.up or ctrl.down or ctrl.left or ctrl.right then
				exit = true
			end
			local npos = self.object:getpos()
			if self.direction == 1 then
				npos.y = npos.y+0.5
				if minetest.get_node({x=npos.x, y=npos.y+2.5, z=npos.z}).name ~= "air" then
					npos.y = npos.y-0.5
				end
			end
			if self.direction == -1 then
				npos.y = npos.y-1
				if minetest.get_node(npos).name ~= "air" then
					npos.y = npos.y+0.5
				end
			end
			self.object:setpos(vector.round(npos))
		end
		
		
		if exit then
			-- Create node and remove entity
			minetest.add_node(np, {name="lifter:lift"})
			self.object:remove()
			nodeupdate(np)
			
			if self.driver then
				self.driver:set_detach()
				self.driver:set_eye_offset({x=0, y=0, z=0},{x=0, y=0, z=0})
				pos.y = pos.y-0.2
				self.driver:setpos(pos)
			end
			
			return
		end
		
		-- Set gravity
		self.object:setacceleration({x=0, y=self.direction*10, z=0})
	
	end
})

minetest.register_craft({
	output = "lifter:lift",
	recipe = {
		{"group:wood", "group:stick", "group:wood"},
		{"group:wood", "default:mese", "default:wood"},
		{"group:wood", "group:stick", "group:wood"},
	},
})

