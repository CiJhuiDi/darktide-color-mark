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
			},
		},
		-- 自己的名字：用自定义别名 + 颜色替换（仅本机可见）
		{
			setting_id = "self_name_group",
			type = "group",
			sub_widgets = {
				{
					setting_id = "self_alias_enable",
					type = "checkbox",
					default_value = false,
				},
				{
					setting_id = "self_alias",
					type = "text",
					default_value = "",
					max_length = 24,
					placeholder_text = "self_alias_placeholder",
				},
				{
					setting_id = "self_alias_color",
					type = "color",
					has_alpha = false,
					-- DMF 颜色控件的值是 **{A, R, G, B}** 四个元素（见 color_widget_passes 的 CHANNELS 标签），
					-- 少一个元素会在设置面板刷新文本时 string.format("%.0f", nil) 直接报错把游戏带崩。
					-- has_alpha=false 时 alpha 位仍必须存在（界面只不显示它）。
					default_value = { 255, 90, 150, 255 },
				},
			},
		},
	},
}

return mod_data
