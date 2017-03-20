minetest.register_node("compressed_obsidian:compressed_obsidian_block", {
	description = "Compressed Obsidian Block",
	tiles = {"compressed_obsidian_block.png"},
	groups = {cracky = 1},
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})

minetest.register_node("compressed_obsidian:compressed_obsidian_glass", {
	description = "Compressed Obsidian Glass",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_obsidian_glass.png", "default_obsidian_glass_detail.png"},
	paramtype = "light",
	on_blast = function() end,
	is_ground_content = false,
	sunlight_propagates = true,
	sounds = default.node_sound_glass_defaults(),
	groups = {cracky = 3},
})

doors.register("compressed_obsidian:compressed_obsidian_glass_door", {
	tiles = {"doors_door_obsidian_glass.png"},
	description = "Compressed Obsidian Glass Door",
	inventory_image = "doors_item_obsidian_glass.png",
	groups = {snappy = 1, cracky = 1, oddly_breakable_by_hand = 3},
	on_blast = function() end,
	sounds = default.node_sound_glass_defaults(),
	protected = true,
	recipe = {
		{"compressed_obsidian:compressed_obsidian_block", "compressed_obsidian:compressed_obsidian_block"},
		{"compressed_obsidian:compressed_obsidian_block", "compressed_obsidian:compressed_obsidian_block"},
		{"compressed_obsidian:compressed_obsidian_block", "compressed_obsidian:compressed_obsidian_block"}
	}
})

local function register_stair(subname, recipeitem, groups, images, description, sounds)
	groups.stair = 1
	minetest.register_node("compressed_obsidian:stair_" .. subname, {
		description = description,
		drawtype = "mesh",
		mesh = "stairs_stair.obj",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		sounds = sounds,
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		collision_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
			},
		},
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local p0 = pointed_thing.under
			local p1 = pointed_thing.above
			local param2 = 0

			local placer_pos = placer:getpos()
			if placer_pos then
				local dir = {
					x = p1.x - placer_pos.x,
					y = p1.y - placer_pos.y,
					z = p1.z - placer_pos.z
				}
				param2 = minetest.dir_to_facedir(dir)
			end

			if p0.y - 1 == p1.y then
				param2 = param2 + 20
				if param2 == 21 then
					param2 = 23
				elseif param2 == 23 then
					param2 = 21
				end
			end

			return minetest.item_place(itemstack, placer, pointed_thing, param2)
		end,
		on_blast = function() end,
	})

	if recipeitem then
		minetest.register_craft({
			output = "compressed_obsidian:stair_" .. subname .. " 8",
			recipe = {
				{recipeitem, "", ""},
				{recipeitem, recipeitem, ""},
				{recipeitem, recipeitem, recipeitem},
			},
		})

		-- Flipped recipe for the silly minecrafters
		minetest.register_craft({
			output = "compressed_obsidian:stair_" .. subname .. " 8",
			recipe = {
				{"", "", recipeitem},
				{"", recipeitem, recipeitem},
				{recipeitem, recipeitem, recipeitem},
			},
		})
	end
end

-- Slab facedir to placement 6d matching table
local slab_trans_dir = {[0] = 8, 0, 2, 1, 3, 4}
-- Slab facedir when placing initial slab against other surface
local slab_trans_dir_place = {[0] = 0, 20, 12, 16, 4, 8}

local function register_slab(subname, recipeitem, groups, images, description, sounds)
	groups.slab = 1
	minetest.register_node("compressed_obsidian:slab_" .. subname, {
		description = description,
		drawtype = "nodebox",
		tiles = images,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		sounds = sounds,
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
		on_place = function(itemstack, placer, pointed_thing)
			local under = minetest.get_node(pointed_thing.under)
			local wield_item = itemstack:get_name()

			if under and wield_item == under.name then
				-- place slab using under node orientation
				local dir = minetest.dir_to_facedir(vector.subtract(
					pointed_thing.above, pointed_thing.under), true)

				local p2 = under.param2

				-- combine two slabs if possible
				if slab_trans_dir[math.floor(p2 / 4)] == dir then
					if not recipeitem then
						return itemstack
					end
					local player_name = placer:get_player_name()
					if minetest.is_protected(pointed_thing.under, player_name) and not
							minetest.check_player_privs(placer, "protection_bypass") then
						minetest.record_protection_violation(pointed_thing.under,
							player_name)
						return
					end
					minetest.set_node(pointed_thing.under, {name = recipeitem, param2 = p2})
					if not minetest.setting_getbool("creative_mode") then
						itemstack:take_item()
					end
					return itemstack
				end

				-- Placing a slab on an upside down slab should make it right-side up.
				if p2 >= 20 and dir == 8 then
					p2 = p2 - 20
				-- same for the opposite case: slab below normal slab
				elseif p2 <= 3 and dir == 4 then
					p2 = p2 + 20
				end

				-- else attempt to place node with proper param2
				minetest.item_place_node(ItemStack(wield_item), placer, pointed_thing, p2)
				if not minetest.setting_getbool("creative_mode") then
					itemstack:take_item()
				end
				return itemstack
			else
				-- place slab using look direction of player
				local dir = minetest.dir_to_wallmounted(vector.subtract(
					pointed_thing.above, pointed_thing.under), true)

				local rot = slab_trans_dir_place[dir]
				if rot == 0 or rot == 20 then
					rot = rot + minetest.dir_to_facedir(placer:get_look_dir())
				end

				return minetest.item_place(itemstack, placer, pointed_thing, rot)
			end
		end,
		on_blast = function() end,
	})

	if recipeitem then
		minetest.register_craft({
			output = "compressed_obsidian:slab_" .. subname .. " 6",
			recipe = {
				{recipeitem, recipeitem, recipeitem},
			},
		})
	end
end

register_stair(
	"compressed_obsidian_block",
	"compressed_obsidian:compressed_obsidian_block",
	{cracky = 1},
	{"compressed_obsidian_block.png"},
	"Compressed Obsidian Stair",
	default.node_sound_stone_defaults()
)

register_slab(
	"compressed_obsidian_block",
	"compressed_obsidian:compressed_obsidian_block",
	{cracky = 1},
	{"compressed_obsidian_block.png"},
	"Compressed Obsidian Slab",
	default.node_sound_stone_defaults()
)
