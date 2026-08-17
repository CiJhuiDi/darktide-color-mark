-- chunkname: @scripts/mods/color_mark/color_mark_data.lua
-- 彩色标记 (ColorMark) 数据文件：设置项定义

local mod = get_mod("color_mark")

local mod_data = {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
}

mod_data.options = {
	widgets = {
		-- 被标记玩家的显示模式
		{
			setting_id = "mark_display_mode",
			type = "dropdown",
			default_value = "anon_color",
			options = {
				{ text = "display_mode_anon_color_setting_text", value = "anon_color" },
				{ text = "display_mode_real_color_setting_text", value = "real_color" },
				{ text = "display_mode_label_color_setting_text", value = "label_color" },
			},
		},
		-- /players 列表是否显示真实账号名（默认显示匿名名，尊重 AnonPlayers）
		{
			setting_id = "players_list_show_real",
			type = "checkbox",
			default_value = false,
		},
	},
}

return mod_data
