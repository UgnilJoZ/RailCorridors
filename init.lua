local mod = {}
railcorridors = mod

-- „Parameter“/„Settings“

-- Wahrscheinlichkeit für jeden Chunk, solche Gänge mit Schienen zu bekommen
-- Probability for every newly generated chunk to get corridors
local probability_railcaves_in_chunk = 2/3

-- Innerhalb welcher Parameter soll sich die Pfadlänge bewegen?
-- Minimal and maximal value of path length
local way_min = 4;
local way_max = 7;

-- Wahrsch. für jeden geraden Teil eines Korridors, keine Fackeln zu bekommen
-- Probability for every horizontal part of a corridor to be without light
local probability_torches_in_segment = 0.5

-- Wahrsch. für jeden Teil eines Korridors, nach oben oder nach unten zu gehen
-- Probability for every part of a corridor to go up or down
local probability_up_or_down = 0.2

-- Wahrscheinlichkeit für jeden Teil eines Korridors, sich zu verzweigen – vorsicht, wenn fast jeder Gang sich verzweigt, kann der Algorithmus unlösbar werden und MT hängt sich auf
-- Probability for every part of a corridor to fork – caution, too high values may cause MT to hang on.
local propability_fork = 0.5

-- Wahrscheinlichkeit für Kisten
-- Probability for chests
local probability_chest = 1/100

-- Spielerische Generation, braucht aber mehr Rechenleistung
-- Fancy mode; deactivate if world generation too laggy
local fancy = true

-- Parameter Ende

local node_maincave = {name="default:dirt"}
local node_air = {name="air"}
local node_rails = {name="default:rail"}
local node_woodplanks = {name="default:wood"}
local node_fence = {name="default:fence_wood"}
local name_torch = "default:torch"
local node_water = {name="default:water_source"}
local node_lava = {name="default:lava_source"}

function mod.nextrandom(min, max)
	return pr:next() / 32767 * (max - min) + min
end

dofile(minetest.get_modpath("railcorridors").."/chests.lua")

function mod.Between(a,b)
	return a+(b-a)/2
end

function mod.vec3_add(a,b)
	return {x=a.x+b.x, y=a.y+b.y, z=a.z+b.z}
end

function mod.vec3_sub(a,b)
	return {x=a.x-b.x, y=a.y-b.y, z=a.z-b.z}
end

function mod.vec3_mul(v,s)
	return {x=s*v.x, y=s*v.y, z=s*v.z}
end

function mod.MinMax(a,b)
	if a < b then
		return {min=a, max=b}
	else
		return {min=b, max=a}
	end
end

function mod.isPointProper(p)
	return (minetest.get_node(p).name ~= "air") and (minetest.get_node(p).name ~= "default:water_source")
end

function mod.FillNodes(minp, maxp, node)
	for yi = minp.y, maxp.y do
		for zi = minp.z, maxp.z do
			for xi = minp.x, maxp.x do
				minetest.set_node({x=xi, y=yi, z=zi}, node)
			end
		end
	end
end

function mod.FillNodesProbable(minp, maxp, p, node)
	local y = mod.MinMax(minp.y, maxp.y)
	local z = mod.MinMax(minp.z, maxp.z)
	local x = mod.MinMax(minp.x, maxp.x)
	for yi = y.min, y.max do
		for zi = z.min,z.max do
			for xi = x.min, x.max do
				if mod.nextrandom(0,1) < p then
					minetest.set_node({x=xi, y=yi, z=zi}, node)
				end
			end
		end
	end
end

function mod.sqDistance(a,b,c)
	return a*a + b*b + c*c
end

function mod.FillNodesCircled(centrum, radius, node)
	local sqradius = radius * radius
	for yi = centrum.y-radius-1,centrum.y+radius+1 do
		for zi = centrum.z-radius-1,centrum.z+radius+1 do
			for xi = centrum.x-radius-1,centrum.x+radius+1 do
				if mod.sqDistance(centrum.x-xi, centrum.y-yi, centrum.z-zi) < sqradius then
					minetest.set_node({x=xi, y=yi, z=zi}, node)
				end
			end
		end
	end
end

function mod.placeStaff(coord)
	minetest.set_node(coord, node_woodplanks)
	minetest.set_node({x=coord.x, y=coord.y-1, z=coord.z}, node_fence)
	minetest.set_node({x=coord.x, y=coord.y-2, z=coord.z}, node_fence)
end

function mod.placeMaybePlanks(pt)
	if minetest.get_node(pt).name == "air" then
		if mod.nextrandom(0,1) < 0.9 then
			minetest.set_node(pt, node_woodplanks)
		end
	end
end

function mod.mainCave(coord)
	local xdif = 4
	--air
	mod.FillNodes({x=coord.x-3, y=coord.y-2, z=coord.z-3}, {x=coord.x+3, y=coord.y+2, z=coord.z+3}, node_air)
	-- roof
	mod.FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y-3}, {x=coord.x+3, z=coord.z+3, y=coord.y-3}, node_maincave)
	mod.FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y+3}, {x=coord.x+3, z=coord.z+3, y=coord.y+3}, node_maincave)
	-- walls
	mod.FillNodes({x=coord.x-4, z=coord.z-3, y=coord.y-2}, {x=coord.x-4, z=coord.z+3, y=coord.y+2}, node_maincave)
	mod.FillNodes({x=coord.x+4, z=coord.z-3, y=coord.y-2}, {x=coord.x+4, z=coord.z+3, y=coord.y+2}, node_maincave)

	mod.FillNodes({x=coord.x-3, z=coord.z-4, y=coord.y-2}, {x=coord.x+3, z=coord.z-4, y=coord.y+2}, node_maincave)
	mod.FillNodes({x=coord.x-3, z=coord.z+4, y=coord.y-2}, {x=coord.x+3, z=coord.z+4, y=coord.y+2}, node_maincave)
	-- round inner edges
	mod.FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y-2}, {x=coord.x+3, z=coord.z-3, y=coord.y-2}, node_maincave)
	mod.FillNodes({x=coord.x-3, z=coord.z+3, y=coord.y-2}, {x=coord.x+3, z=coord.z+3, y=coord.y-2}, node_maincave)
	mod.FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y-2}, {x=coord.x-3, z=coord.z+3, y=coord.y-2}, node_maincave)
	mod.FillNodes({x=coord.x+3, z=coord.z-3, y=coord.y-2}, {x=coord.x+3, z=coord.z+3, y=coord.y-2}, node_maincave)

	mod.FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y+2}, {x=coord.x+3, z=coord.z-3, y=coord.y+2}, node_maincave)
	mod.FillNodes({x=coord.x-3, z=coord.z+3, y=coord.y+2}, {x=coord.x+3, z=coord.z+3, y=coord.y+2}, node_maincave)
	mod.FillNodes({x=coord.x-3, z=coord.z-3, y=coord.y+2}, {x=coord.x-3, z=coord.z+3, y=coord.y+2}, node_maincave)
	mod.FillNodes({x=coord.x+3, z=coord.z-3, y=coord.y+2}, {x=coord.x+3, z=coord.z+3, y=coord.y+2}, node_maincave)
end

-- horizontal even corridor part
function mod.corridor_part(point, direction, length, i_offset)
	local vector = mod.vec3_add(point, direction);
	local place_torches = mod.nextrandom(0,1) < probability_torches_in_segment
	if place_torches then
		torchdir = {1,1}
		if direction.z > 0 then
			torchdir = {5, 4}
		elseif direction.z < 0 then
			torchdir = {4,5}
		elseif direction.x < 0 then
			torchdir = {2, 3}
		elseif direction.x > 0 then
			torchdir = {3, 2}
		else torchdir = {1,1}
		end
	end
	for i = 1+i_offset,length+i_offset+2 do
		minetest.set_node(vector, node_air)
		
		minetest.set_node({x=vector.x-direction.z, y=vector.y, z=vector.z+direction.x}, node_air)
		minetest.set_node({x=vector.x-direction.z, y=vector.y-1, z=vector.z+direction.x}, node_air)
		minetest.set_node({x=vector.x+direction.z, y=vector.y, z=vector.z-direction.x}, node_air)
		minetest.set_node({x=vector.x+direction.z, y=vector.y-1, z=vector.z-direction.x}, node_air)

		-- Decke
		mod.FillNodesProbable({x=vector.x-direction.z, y=vector.y+1, z=vector.z-direction.x}, {x=vector.x+direction.z, y=vector.y+1, z=vector.z+direction.x}, 0.9, node_air)
		if direction.y == 0 then
			if mod.nextrandom(0,2) < 1 then
				minetest.set_node({x=vector.x, y=vector.y-1, z=vector.z}, node_rails)
			elseif mod.nextrandom(1,10) > 1 then
				minetest.set_node({x=vector.x, y=vector.y-1, z=vector.z}, node_air)
			end
			-- when there is no floor: maybe wood will make it!
			mod.placeMaybePlanks({x=vector.x-direction.z, y=vector.y-2, z=vector.z+direction.x})
			mod.placeMaybePlanks({x=vector.x, y=vector.y-2, z=vector.z})
			mod.placeMaybePlanks({x=vector.x+direction.z, y=vector.y-2, z=vector.z-direction.x})
			vector.y = vector.y+1
			if i % 5 == 0 then
				-- Wooden staff structures
				minetest.set_node(vector, node_woodplanks)
				mod.placeStaff({x=vector.x+direction.z, y=vector.y, z=vector.z-direction.x})
				mod.placeStaff({x=vector.x-direction.z, y=vector.y, z=vector.z+direction.x})
			-- torches
			elseif place_torches and (i % 5 == 1) and (i > 1+i_offset) then
				minetest.set_node(vector, {name=name_torch,param2=torchdir[1]})
			elseif place_torches and (i % 5 == 4) then
				minetest.set_node(vector, {name=name_torch,param2=torchdir[2]})
			-- water or lava in the corridors?
			elseif vector.y < 0 and mod.nextrandom(0,1) < 0.001 then
				local cnode
				if mod.nextrandom(0,02) < 0.3 then
					cnode = node_lava
				else
					cnode = node_water
				end
				minetest.set_node({x=vector.x+2*direction.z, y=vector.y+mod.nextrandom(-2,-1), z=vector.z-2*direction.x}, cnode)
			-- chests?
			elseif mod.nextrandom(0,1) < probability_chest then
				mod.place_chest({x=vector.x-direction.z, y=vector.y-2, z=vector.z+direction.x})
			end
			vector.y = vector.y-1
		end
		
		vector = mod.vec3_add(vector, direction);
	end
	return mod.vec3_sub(vector, mod.vec3_mul(direction, 2))
end

-- up or down going corridor part
function mod.coridor_part_with_y(point, direction)
	local air_disc = function(p, facedir)
		mod.FillNodesProbable({x=p.x-facedir.z, y=p.y+1, z=p.z-facedir.x},
			{x=p.x+facedir.z, y=p.y-1, z=p.z+facedir.x}, 0.99, node_air)
		--mod.FillNodesProbable({x=p.x-direction.z, y=p.y-1, z=p.z-direction.x}, {x=p.x+direction.z, y=p.y-1, z=p.z+direction.x}, 0.95, node_air)
		--mod.FillNodesProbable({x=p.x-direction.z, y=p.y, z=p.z-direction.x}, {x=p.x+direction.z, y=p.y, z=p.z+direction.x}, 0.95, node_air)
		--mod.FillNodesProbable({x=p.x-direction.z, y=p.y+1, z=p.z-direction.x}, {x=p.x+direction.z, y=p.y+1, z=p.z+direction.x}, 0.95, node_air)
		--minetest.set_node(p, node_air)
		--print("air_disc at "..p.x..", "..p.y..", "..p.z)
	end
	if direction.y < 0 then
		direction.y = -1
	else
		direction.y = 1
	end
	local vector = mod.vec3_add(point, {x=direction.x, z=direction.z, y=0})
	air_disc(vector, direction)
	vector = mod.vec3_add(vector, direction)
	air_disc(vector, direction)
	vector = mod.vec3_add(vector, {x=direction.x, z=direction.z, y=0})
	air_disc(vector, direction)
	vector = mod.vec3_add(vector, direction)
	air_disc(vector, direction)
	vector = mod.vec3_add(vector, direction)
	air_disc(vector, direction)
	vector = mod.vec3_add(vector, {x=direction.x, z=direction.z, y=0})
	air_disc(vector, direction)
	vector = mod.vec3_add(vector, direction)
	air_disc(vector, direction)
	return vector
end

function mod.BulkOfWood(pt, height)
	-- Luftkreuz
	mod.FillNodes({x=pt.x-2, z=pt.z-1, y=pt.y-1}, {x=pt.x+2, z=pt.z+1, y=pt.y+height-1}, node_air)
	mod.FillNodes({x=pt.x-1, z=pt.z-2, y=pt.y-1}, {x=pt.x+1, z=pt.z+2, y=pt.y+height-1}, node_air)
	for yi = -1,height-1 do
		-- Holz
		minetest.set_node({x=pt.x+1, z=pt.z+1, y=pt.y+yi-1}, node_woodplanks)
		minetest.set_node({x=pt.x+1, z=pt.z-1, y=pt.y+yi-1}, node_woodplanks)
		minetest.set_node({x=pt.x-1, z=pt.z+1, y=pt.y+yi-1}, node_woodplanks)
		minetest.set_node({x=pt.x-1, z=pt.z-1, y=pt.y+yi-1}, node_woodplanks)
	end
end

function mod.cross(point, lastdir, new_way_probability)
	--print("cross at "..point.x..", "..point.y..", "..point.z)
	local wood = mod.nextrandom(0,5) < 1
	local second_floor = wood and mod.nextrandom(1,3) < 2
	if wood then
		if second_floor then
			mod.BulkOfWood(point, 7)
		else
			mod.BulkOfWood(point, 3)
		end
	end
	local startpoint
	-- Code reduction by defining function
	local newway_func = function(midpoint, direction)
		if mod.nextrandom(0,1) < new_way_probability then
			if wood then
		 		startpoint = mod.vec3_add(midpoint, mod.vec3_mul(direction, 2))
			else
				startpoint = midpoint
			end
			mod.start_corridors(startpoint, direction)
		end
	end
	if not wood and mod.nextrandom(0,1) < probability_up_or_down then
		lastdir.y = mod.nextrandom(-0.5, 0.5)
	end
	newway_func(point, lastdir)
	newway_func(point, {x=-lastdir.z, y=0, z=lastdir.x})
	newway_func(point, {x=lastdir.z, y=0, z=-lastdir.x})
	if second_floor then
		newway_func({x=point.x, y=point.y+4, z=point.z}, lastdir)
		newway_func({x=point.x, y=point.y+4, z=point.z}, {x=-lastdir.z, y=0, z=lastdir.x})
		newway_func({x=point.x, y=point.y+4, z=point.z}, {x=lastdir.z, y=0, z=-lastdir.x})
		newway_func({x=point.x, y=point.y+4, z=point.z}, {x=-lastdir.x, y=0, z=-lastdir.z})
	end
end

function mod.start_corridors(startpoint, direction)
	local length = mod.nextrandom(1,4)*4
	local waypoint = mod.vec3_add(startpoint, mod.vec3_mul(direction, length))
	local gofurther = mod.isPointProper(waypoint)
	if direction.y ~= 0 then
		waypoint = mod.coridor_part_with_y(startpoint, direction)
	else
		waypoint = mod.corridor_part(startpoint, direction, length, 3)
	end
	if not gofurther then
		return
	end
	local fork = mod.nextrandom(0,1) < propability_fork
	if fork then
		mod.cross(waypoint, direction, 0.5)
	end
end

function mod.railcaves(main_cave_coord)
	mod.mainCave(main_cave_coord)
	local dir = {x=1,y=0,z=0}
	local waypoint = mod.corridor_part(mod.vec3_add(main_cave_coord, mod.vec3_mul(dir, 3)), dir, mod.nextrandom(4,5)*3, 2)
	mod.cross(waypoint, dir, 1)
end

minetest.register_on_generated(function(minp, maxp, seed)
	if not pr then
		pr = PseudoRandom(seed)
	end
	if mod.nextrandom(0,1) < probability_railcaves_in_chunk and maxp.y < 10 then
		local mp
		for i = 1,3 do
			mp = {x=mod.nextrandom(minp.x,maxp.x), y=mod.nextrandom(minp.y,maxp.y), z=mod.nextrandom(minp.z,maxp.z)}
			if mod.isPointProper(mp) then
				break
			end
		end
		if mod.isPointProper(mp) then
			mod.railcaves(mp)
		end
	end
end)
