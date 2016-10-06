
--Todo make lift go up and down!

doors.register_door("lifter:door", {
	description = "Lift Door",
	inventory_image = "lifter_door_inv.png",
	groups = {choppy=3, cracky=3, oddly_breakable_by_hand=1, flammable=2, door=1},
	tiles_bottom = {"lifter_door_b.png", "lifter_door.png"},
	tiles_top = {"lifter_door_a.png", "lifter.png"},
	only_placer_can_open = false,
	sounds = default.node_sound_wood_defaults(),
	sunlight = false
})

-- should only be ignore if there's not generated map
local function get_far_node(pos)
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		minetest.get_voxel_manip():read_from_map(pos, pos)
		node = minetest.get_node(pos)
	end
	return node
end


local function fetch_lift(pos, node, clicker, rel, i, open_door, plus)
	local wnode = get_far_node({x=pos.x+1, y=pos.y+i, z=pos.z})
	local snode = get_far_node({x=pos.x-1, y=pos.y+i, z=pos.z})
	local anode = get_far_node({x=pos.x, y=pos.y+i, z=pos.z+1})
	local dnode = get_far_node({x=pos.x, y=pos.y+i, z=pos.z-1})
	
	if wnode.name ~= "lifter:lift" and snode.name ~= "lifter:lift" and 
		anode.name ~= "lifter:lift" and dnode.name ~= "lifter:lift" then
		
			if wnode.name ~= "air" and snode.name ~= "air" and 
			   anode.name ~= "air" and dnode.name ~= "air" and
			   wnode.name ~= "bones:bones" and snode.name ~= "bones:bones" and 
			anode.name ~= "bones:bones" and dnode.name ~= "bones:bones"then
				print("lift not found, no air")
				return
			end
			
			local test = minetest.find_nodes_in_area({x=pos.x-2, y=pos.y+i, z=pos.z-2}, {x=pos.x+2, y=pos.y+i, z=pos.z+2}, "air")
			if #test == 16 then
				print("lift not found, too much air")
				return
			end
			
			if i%20 == 0 then
				minetest.after(1, fetch_lift, pos, node, clicker, rel, i+plus, open_door, plus)
			else
				fetch_lift(pos, node, clicker, rel, i+plus, open_door, plus)
			end
	else 	
		if wnode.name == "lifter:lift" then
			local name = minetest.get_node({x=pos.x+1, y=pos.y+rel, z=pos.z}).name
			if name == "air" or name == "ignore" or name == "bones:bones" then
				minetest.remove_node({x=pos.x+1, y=pos.y+i, z=pos.z})
				minetest.add_node({x=pos.x+1, y=pos.y+rel, z=pos.z}, {name="lifter:lift"})
			else
				print("lift blocked")
			end
		end
		if snode.name == "lifter:lift" then
			local name = minetest.get_node({x=pos.x-1, y=pos.y+rel, z=pos.z}).name
			if name == "air" or name == "ignore" or name == "bones:bones" then
				minetest.remove_node({x=pos.x-1, y=pos.y+i, z=pos.z})
				minetest.add_node({x=pos.x-1, y=pos.y+rel, z=pos.z}, {name="lifter:lift"})
			else
				print("lift blocked")
			end
		end
		if anode.name == "lifter:lift" then
			local name = minetest.get_node({x=pos.x, y=pos.y+rel, z=pos.z+1}).name
			if name == "air" or name == "ignore" or name == "bones:bones" then
				minetest.remove_node({x=pos.x, y=pos.y+i, z=pos.z+1})
				minetest.add_node({x=pos.x, y=pos.y+rel, z=pos.z+1}, {name="lifter:lift"})
			else
				print("lift blocked")
			end
		end
		if dnode.name == "lifter:lift" then
			local name = minetest.get_node({x=pos.x, y=pos.y+rel, z=pos.z-1}).name
			if name == "air" or name == "ignore" or name == "bones:bones" then
				minetest.remove_node({x=pos.x, y=pos.y+i, z=pos.z-1})
				minetest.add_node({x=pos.x, y=pos.y+rel, z=pos.z-1}, {name="lifter:lift"})
			else
				print("lift blocked")
			end
		end
		open_door(pos,node,clicker)
	end
end

local b1rc = minetest.registered_nodes["lifter:door_a"].on_rightclick
--local t2rc = minetest.registered_nodes["lifter:door_t_2"].on_rightclick

minetest.override_item("lifter:door_a", {
	on_rightclick = function(pos, node, clicker)
		if string.sub(node.name, -2) == "_a" then
			if clicker:is_player() then
				minetest.chat_send_player(clicker:get_player_name(), "You called for a lift...")
			end
			fetch_lift(pos, node, clicker, -1, 0, b1rc, 1)
			fetch_lift(pos, node, clicker, -1, 0, b1rc, -1)
--			minetest.after(5, b1rc, pos, node, clicker)
		else
			b1rc(pos, node, player)
		end
	end
})

minetest.register_abm({
      nodenames = {"lifter:door_b"},
      interval = 8,
      chance = 1,
      catch_up = false,
      action = function(pos, node)
	 minetest.after(1, b1rc, pos, node, "")
      end
})

--minetest.override_item("lifter:door_b_2", {
	--on_rightclick = hijack_click(b2rc)
--})


--minetest.override_item("lifter:door_t_2", {
	--on_rightclick = hijack_click(t2rc)
--})

local b2rc = minetest.registered_nodes["lifter:door_b"].on_rightclick

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
		
		local door = minetest.find_node_near(pos, 2, "lifter:door_b")
		if door then
			b2rc(door, minetest.get_node(door), player)
		end
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
			if (wnode.name:find("door") and not wbnode.name:find("door")) or 
		 		(snode.name:find("door") and not sbnode.name:find("door")) or 
		 		(anode.name:find("door") and not abnode.name:find("door")) or 
		 		(dnode.name:find("door") and not dbnode.name:find("door")) then
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
			local door = minetest.find_node_near(np, 2, "lifter:door_a")
			if door then
				b1rc(door, minetest.get_node(door), self.driver)
			end
		
			-- Create node and remove entity
			minetest.add_node(np, {name="lifter:lift"})
			self.object:remove()
			nodeupdate(np)
			
			if self.driver then
				self.driver:set_detach()
				self.driver:set_eye_offset({x=0, y=0, z=0},{x=0, y=0, z=0})
				pos.y = pos.y
				self.driver:setpos(pos)
			end
			
			return
		end
		
		if ctrl.jump or ctrl.sneak then
			-- Set gravity
			self.object:setacceleration({x=0, y=self.direction*5, z=0})
		else
			self.object:setacceleration({x=0, y=0, z=0})
		end
	end
})

minetest.register_craft({
	output = "lifter:lift",
	recipe = {
		{"group:wood", "group:stick", "group:wood"},
		{"group:wood", "default:mese", "group:wood"},
		{"group:wood", "group:stick", "group:wood"},
	},
})

minetest.register_craft({
	output = "lifter:door",
	recipe = {
		{"group:stick", "group:stick", "group:stick"},
		{"group:stick", "doors:door_wood", "group:stick"},
		{"group:stick", "group:stick", "group:stick"},
	},
})

