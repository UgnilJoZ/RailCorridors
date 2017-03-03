local mod = railcorridors

-- Random chest items
-- Zufälliger Kisteninhalt
function mod.rci()
	if mod.nextrandom(0,1) < 0.03 then
		return "farming:bread "..mod.nextrandom(1,3)
	elseif mod.nextrandom(0,1) < 0.05 then
		if mod.nextrandom(0,1) < 0.3 then
			return "farming:seed_cotton "..math.floor(mod.nextrandom(1,4))
		elseif mod.nextrandom(0,1) < 0.5 then
			return "default:sapling "..math.floor(mod.nextrandom(1,4))
		else
			return "farming:seed_wheat "..math.floor(mod.nextrandom(1,4))
		end
	elseif mod.nextrandom(0,1) < 0.005 then
		return "tnt:tnt "..mod.nextrandom(1,3)
	elseif mod.nextrandom(0,1) < 0.003 then
		if mod.nextrandom(0,1) < 0.8 then
			return "default:mese_crystal "..math.floor(mod.nextrandom(1,3))
		else
			return "default:diamond "..math.floor(mod.nextrandom(1,3))
		end
	end
	return nil
end
-- chests
function mod.place_chest(pos)
	minetest.set_node(pos, {name="default:chest"})

	local meta = minetest.get_meta(pos)
	local meta_table = meta:to_table()

	local inventory_main = {}
	for i=1,32 do
		inventory_main[i] = mod.rci()
	end
	
	if meta_table ~= nil then -- Makes the chest workable regardless of the chest's readiness
		meta_table.inventory.main = inventory_main
		meta:from_table(meta_table)
		meta:set_string("infotext", "Chest");
	else
		meta:from_table({
			inventory = {
				main = inventory_main
			},
			fields = {
				infotext = "Chest"
			}
		})
	end

	local inv = meta:get_inventory()
	inv:set_size("main", 8*4) -- Fixes trimmed inventory space issue.
end
