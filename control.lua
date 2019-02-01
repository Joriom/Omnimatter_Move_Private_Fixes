ore_to_move = {}
ore_to_move_misfits = {}

function start_with(a,b)
	return string.sub(a,1,string.len(b)) == b
end
function end_with(a,b)
	return string.sub(a,string.len(a)-string.len(b)+1) == b
end

local round = function(nr)
	local dec = nr-math.floor(nr)
	if dec >= 0.5 then
		return math.floor(nr)+1
	else
		return math.floor(nr)
	end
end

function can_accept_ore(surface, x, y)
	return surface.get_tile(x, y).collides_with("ground-tile") and surface.count_entities_filtered{area = {{x, y}, {x+1, y+1}}, type="resource"} == 0
end

script.on_event(defines.events.on_player_alt_selected_area, function(event)

end)

script.on_event(defines.events.on_player_selected_area, function(event)
	if event.item == "ore-move-planner" then
		local player = game.players[event.player_index]
		local surface = player.surface
		ore_to_move[event.player_index] = {ore={},centre={}}
		ore_to_move_misfits[event.player_index] = {ore={}}
		local centre = {x=0,y=0}
		local qnt = 0
		for _,entity in pairs(event.entities) do
			if entity.type == "resource" then
				
				qnt=qnt+1
				local pos = entity.position
				centre.x=centre.x+pos.x
				centre.y=centre.y+pos.y
				ore_to_move[event.player_index].ore[#ore_to_move[event.player_index].ore+1]={name=entity.name,pos=pos,surface = entity.surface,amount=entity.amount}

				local extra = entity
				--extra.destroy()
							
					--surf.create_entity({name = "compressed-"..name.."-ore" , position = pos, force = force, amount = quant})
			end
		end
		centre.x=round(centre.x/qnt)
		centre.y=round(centre.y/qnt)
		ore_to_move[event.player_index].centre.x=centre.x
		ore_to_move[event.player_index].centre.y=centre.y
		for _, ore in pairs(ore_to_move[event.player_index].ore) do
			ore.pos.x=round(ore.pos.x-centre.x)
			ore.pos.y=round(ore.pos.y-centre.y)
		end
			--player.insert({name = resource, count = miscount})
	end
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
	if event.item == "ore-move-planner" and ore_to_move[event.player_index] ~= nil then
		local player = game.players[event.player_index]
		local surface = player.surface
		local centre = {x=round((event.area.left_top.x+event.area.right_bottom.x)/2),y=round((event.area.left_top.y+event.area.right_bottom.y)/2)}
		
		local spiral = { x = centre.x, y = centre.y, direction = 0, step = 0, turn_in = 1, turn_next = 2 }
		spiral.do_step = function()
			if spiral.step >= spiral.turn_in then
				if spiral.direction >= 3 then
					spiral.direction = 0
				else
					spiral.direction = spiral.direction + 1
				end
				spiral.step = 0
				spiral.turn_in = spiral.turn_next;
				spiral.turn_next = spiral.turn_next + 1;
			end
			
			spiral.step = spiral.step + 2
			if spiral.direction == 0 then
				spiral.y = spiral.y - 1
			elseif spiral.direction == 1 then
				spiral.x = spiral.x + 1
			elseif spiral.direction == 2 then
				spiral.y = spiral.y + 1
			else
				spiral.x = spiral.x - 1
			end
		end
		--[[
		local radius = math.floor(math.sqrt(#ore_to_move[event.player_index].ore)/2)
		local area = {}
		local ground_tiles_count = 0
		local free_spots_count = 0
		
		--local current_pos = { x = centre.x, y = centre.y, offset = 0,  }
		--local start_pos_unset = true
		repeat
			radius = radius + 1
			area = {{centre.x-radius,centre.y-radius}, {centre.x+radius+1,centre.y+radius+1}}
			ground_tiles_count = surface.count_tiles_filtered{area = area, collision_mask="ground-tile"}
			free_spots_count = ground_tiles_count - surface.count_entities_filtered{area = area, type="resource"}
		--	if (start_pos_unset and free_spots_count > 0) then
		--		start_pos.x = 
		until(free_spots_count >= #ore_to_move[event.player_index].ore or radius >= 100)
		
		if radius >= 100 then
			player.print("Not enough space to place ores. Sorry! -Joriom")
			return
		end
		--]]
		for n, ore in pairs(ore_to_move[event.player_index].ore) do
			local entities = surface.find_entities_filtered{
			  area= {{ore_to_move[event.player_index].centre.x+ore.pos.x-0.5, ore_to_move[event.player_index].centre.y+ore.pos.y-0.5},
			  {ore_to_move[event.player_index].centre.x+ore.pos.x +0.5, ore_to_move[event.player_index].centre.y+ore.pos.y +0.5}},
			  name=ore.name,
			}
			local dist = math.sqrt(math.pow(centre.x-ore_to_move[event.player_index].centre.x,2)+math.pow(centre.y-ore_to_move[event.player_index].centre.y,2))
			ore_to_move[event.player_index].ore[n].cost = 1/(1+dist/5000)
			
			for _, ent in pairs(entities) do
				ent.destroy()
			end
		end
		
		for _, ore in pairs(ore_to_move[event.player_index].ore) do
			
			local pos = {}
			pos.x = centre.x+ore.pos.x
			pos.y = centre.y+ore.pos.y
			while not can_accept_ore(surface, pos.x, pos.y) do
				pos.x = spiral.x;
				pos.y = spiral.y;
				spiral.do_step();
			end
			ore.surface.create_entity({name = ore.name , position = pos, amount = round(ore.amount*ore.cost)})
			--ent.destroy()
			
		end
		ore_to_move[event.player_index]=nil
	end
end)

