minetest.register_craft({
	output = "compressed_obsidian:compressed_obsidian_block",
	recipe = {
		{"default:obsidianbrick", "default:obsidianbrick", "default:obsidianbrick"},
		{"default:obsidianbrick", "default:obsidianbrick", "default:obsidianbrick"},
		{"default:obsidianbrick", "default:obsidianbrick", "default:obsidianbrick"}
	}
})

minetest.register_craft({
	type = "cooking",
	output = "compressed_obsidian:compressed_obsidian_glass",
	recipe = "default:obsidianbrick",
})
