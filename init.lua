probability_mines_in_chunk = 0.42

local carts_loaded = false
local farmingplus_loaded = false

local function min(a,b)
	if a < b then
		return a
	else
		return b
	end
end


local function max(a,b)
	if a > b then
		return a
	else
		return b
	end
end

local function va6n(v3, v2, n)
	return {x=v3.x+v2[1]*n, y=v3.y, z=v3.z+v2[2]*n}
end

local function fill_area(data, area, minp, maxp, c_node)
	for z = min(minp.z,maxp.z), max(minp.z,maxp.z) do
		for x = min(minp.x,maxp.x), max(minp.x,maxp.x) do
			for y = min(minp.y, maxp.y), max(minp.y, maxp.y) do
				data[area:index(x, y, z)] = c_node
			end
		end
	end
end

local function fill_area_p(data, area, minp, maxp, c_node, p)
	for z = min(minp.z,maxp.z), max(minp.z,maxp.z) do
		for x = min(minp.x,maxp.x), max(minp.x,maxp.x) do
			for y = min(minp.y, maxp.y), max(minp.y, maxp.y) do
				if math.random(0,1) < p then
					data[area:index(x, y, z)] = c_node
				end
			end
		end
	end
end

local function main_cave(data, area, pos, nodes)
	fill_area(data, area, {x=pos.x-10, y=pos.y-1, z=pos.z-6}, {x=pos.x+10, y=pos.y+2, z=pos.z+6}, nodes.air)
	fill_area_p(data, area, {x=pos.x-10, y=pos.y+3, z=pos.z-6}, {x=pos.x+10, y=pos.y+3, z=pos.z+6}, nodes.air, 0.72)
	fill_area(data, area, {x=pos.x-10, y=pos.y-2, z=pos.z-6}, {x=pos.x+10, y=pos.y-2, z=pos.z+6}, nodes.dirt)
end

local function start_mine(data, area, startpos, dir, forkprob_start, forkprob_dec, nodes)
	local negdir = {-dir[2], dir[1]}
	local length = math.random(2,4)*5+1
	local endpoint = {x=startpos.x+dir[1]*length, z=startpos.z+dir[2]*length, y=startpos.y}
	local torches = math.random(0,1) < 0.5
	-- air
	fill_area(data, area, {x=startpos.x-negdir[1], z=startpos.z-negdir[2], y=startpos.y-1},
		{x=endpoint.x+negdir[1], z=endpoint.z+negdir[2], y=endpoint.y+1}, nodes.air)
	-- rails
	fill_area(data, area, {x=startpos.x, z=startpos.z, y=startpos.y-1}, {x=endpoint.x, z=endpoint.z, y=endpoint.y-1}, nodes.rails)

	for i = 1, length do
		local pos = {x=startpos.x+dir[1]*i, y=startpos.y, z=startpos.z+dir[2]*i}
		if i % 5 == 0 then
			-- stuff made out of wood
			fill_area(data, area, {x=pos.x+negdir[1], z=pos.z+negdir[2], y=pos.y-1}, {x=pos.x+negdir[1], z=pos.z+negdir[2], y=pos.y+1},
				nodes.fence)
			fill_area(data, area, {x=pos.x-negdir[1], z=pos.z-negdir[2], y=pos.y-1}, {x=pos.x-negdir[1], z=pos.z-negdir[2], y=pos.y+1},
				nodes.fence)
			fill_area(data, area, {x=pos.x-negdir[1], z=pos.z-negdir[2], y=pos.y+1}, {x=pos.x+negdir[1], z=pos.z+negdir[2], y=pos.y+1},
				nodes.wood)
			-- torches
			if torches then
				data[area:index(pos.x+dir[1], pos.y+1, pos.z+dir[2])] = nodes.torch
				data[area:index(pos.x-dir[1], pos.y+1, pos.z-dir[2])] = nodes.torch
			end
		end
	end

	local newprob = forkprob_start - forkprob_dec

	if newprob >= 0 and math.random(0,1) < forkprob_start then
		-- Fork / Change direction
		local twostoried = math.random(0,1) < 0.27	-- two floors for this intersection?
		local probs = {0.42,0.42,0.42, 0.42,0.42,0.42,0.42}	-- chances for new ways
		local new_startpoint = va6n(endpoint, dir, 2)
		if twostoried then
			-- Much wood
			fill_area(data, area, {x=new_startpoint.x-2, y=new_startpoint.y-1, z=new_startpoint.z-2},
				{x=new_startpoint.x+2, y=new_startpoint.y+7, z=new_startpoint.z+2}, nodes.air)
			fill_area(data, area, {x=new_startpoint.x-1, y=new_startpoint.y-1, z=new_startpoint.z-1},
				{x=new_startpoint.x-1, y=new_startpoint.y+7, z=new_startpoint.z-1}, nodes.wood)
			fill_area(data, area, {x=new_startpoint.x+1, y=new_startpoint.y-1, z=new_startpoint.z-1},
				{x=new_startpoint.x+1, y=new_startpoint.y+7, z=new_startpoint.z-1}, nodes.wood)
			fill_area(data, area, {x=new_startpoint.x-1, y=new_startpoint.y-1, z=new_startpoint.z+1},
				{x=new_startpoint.x-1, y=new_startpoint.y+7, z=new_startpoint.z+1}, nodes.wood)
			fill_area(data, area, {x=new_startpoint.x+1, y=new_startpoint.y-1, z=new_startpoint.z+1},
				{x=new_startpoint.x+1, y=new_startpoint.y+7, z=new_startpoint.z+1}, nodes.wood)
		else
			probs[math.floor(math.random(1,4))] = 1	-- one must be 1 – it's either a fork or a bulk of wood likely to fork.
			fill_area(data, area, {x=new_startpoint.x-1, y=new_startpoint.y-1, z=new_startpoint.z-1},
				{x=new_startpoint.x+1, y=new_startpoint.y+1, z=new_startpoint.z+1}, nodes.air)
		end
		if math.random(0,1) < probs[1] then	-- front
			start_mine(data, area, new_startpoint, dir, newprob, forkprob_dec, nodes)
		end
		if math.random(0,1) < probs[2] then	-- left
			start_mine(data, area, va6n(new_startpoint, negdir, 2), negdir, newprob, forkprob_dec, nodes)
		end
		if math.random(0,1) < probs[3] then	-- right
			start_mine(data, area, va6n(new_startpoint, negdir, -2), {-negdir[1], -negdir[2]}, newprob, forkprob_dec, nodes)
		end
		if twostoried then
			new_startpoint.y = new_startpoint.y + 4
			if math.random(0,1) < probs[4] then
				start_mine(data, area, new_startpoint, dir, newprob, forkprob_dec, nodes)	-- front
			end
			if math.random(0,1) < probs[4] then
				start_mine(data, area, va6n(new_startpoint, negdir, -3), {-negdir[1], -negdir[2]}, newprob, forkprob_dec, nodes)	-- right
			end
			if math.random(0,1) < probs[4] then
				start_mine(data, area, va6n(new_startpoint, negdir, 3), negdir, newprob, forkprob_dec, nodes)	-- left
			end
			if math.random(0,1) < probs[4] then
				start_mine(data, area, va6n(new_startpoint,dir,-3), {-dir[1], -dir[2]}, newprob, forkprob_dec, nodes)	-- back
			end
		end
	end
end

local function start_mines(data, area, maincave, forkprob_start, forkprob_dec, nodes)
	main_cave(data, area, maincave, nodes)
	local probs = {1, 1, 1, 1}	-- probabilities:
	probs[math.floor(math.random(1,4))] = 1	-- one mineshaft minimum
	if math.random(0,1) < probs[1] then start_mine(data, area, va6n(maincave, {0, 1}, 5), {0, 1}, forkprob_start, forkprob_dec, nodes) end
	if math.random(0,1) < probs[2] then start_mine(data, area, va6n(maincave, {0, -1}, 5), {0, -1}, forkprob_start, forkprob_dec, nodes) end
	if math.random(0,1) < probs[3] then start_mine(data, area, va6n(maincave, {1, 0}, 10), {1, 0}, forkprob_start, forkprob_dec, nodes) end
	if math.random(0,1) < probs[4] then start_mine(data, area, va6n(maincave, {-1, 0}, 10), {-1, 0}, forkprob_start, forkprob_dec, nodes) end
end

function generate_mines(minp, maxp, seed)
	local t0 = os.clock()
	local chulens = {x=maxp.x-minp.x+1, y=maxp.y-minp.y+1, z=maxp.z-minp.z+1}
	local imin, imax = {x=minp.x-10, y=minp.y, z=minp.z-10}, {x=maxp.x+10, y=maxp.y, z=maxp.z+10}

	local c_ignore = 126
	local c_air = minetest.get_content_id("air")
	local c_stone = minetest.get_content_id("default:stone")
	local c_dirt = minetest.get_content_id("default:dirt")
	local c_dirt_wg = minetest.get_content_id("default:dirt_with_grass")
	local c_wood = minetest.get_content_id("default:wood")
	local c_fence = minetest.get_content_id("default:fence_wood")
	local c_rails = minetest.get_content_id("default:rail")
	local c_torch = minetest.get_content_id("default:torch")

	local vm, emin, emax
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(imin, imax)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()

	local startposition = {x=minp.x+chulens.x/2, y=minp.y+chulens.y/2, z=minp.z+chulens.z/2}
	local node_dict = {air=c_air, dirt=c_dirt, rails=c_rails, fence=c_fence, wood=c_wood, torch=c_torch}
	start_mines(data, area, startposition, 1, 0.2, node_dict)

	vm:set_data(data)
	vm:set_lighting({day=1, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)

	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[mines] "..chugent.." ms")
end

minetest.register_on_generated(generate_mines)
