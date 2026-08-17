return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`color_mark` encountered an error loading the Darktide Mod Framework.")

		new_mod("color_mark", {
			mod_script       = "color_mark/scripts/mods/color_mark/color_mark",
			mod_data         = "color_mark/scripts/mods/color_mark/color_mark_data",
			mod_localization = "color_mark/scripts/mods/color_mark/color_mark_localization",
		})
	end,
	packages = {},
	version = "1.0.0",
}
