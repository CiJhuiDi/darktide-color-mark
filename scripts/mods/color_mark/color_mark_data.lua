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
		-- 混淆 true_level 显示的等级 / 威望 / 浩劫层数（每次进游戏随机一组假值）
		-- 总开关 + 自己 / 队友分别开关；总开关关闭 = 谁都不混淆
		{
			setting_id = "fake_progress_group",
			type = "group",
			sub_widgets = {
				{
					setting_id = "fake_progress_enable",
					type = "checkbox",
					default_value = true,
				},
				{
					setting_id = "fake_progress_self_enable",
					type = "checkbox",
					default_value = true,
				},
				{
					setting_id = "fake_progress_other_enable",
					type = "checkbox",
					default_value = true,
				},
			},
		},
		-- 假值区间（最低 / 最高）—— 默认贴近真实玩家，避免"等级 3 / 浩劫 1"这种一眼假的随机数
		{
			setting_id = "fake_range_group",
			type = "group",
			sub_widgets = {
				{ setting_id = "fake_level_min", type = "numeric", default_value = 25, range = { 1, 30 }, decimals_number = 0 },
				{ setting_id = "fake_level_max", type = "numeric", default_value = 30, range = { 1, 30 }, decimals_number = 0 },
				-- true_level 的"真等级"满级后继续累加，可以远超 30（几百上千），故单独给一组区间
				{ setting_id = "fake_true_level_min", type = "numeric", default_value = 100, range = { 1, 9999 }, decimals_number = 0 },
				{ setting_id = "fake_true_level_max", type = "numeric", default_value = 300, range = { 1, 9999 }, decimals_number = 0 },
				{ setting_id = "fake_prestige_min", type = "numeric", default_value = 0, range = { 0, 9 }, decimals_number = 0 },
				{ setting_id = "fake_prestige_max", type = "numeric", default_value = 3, range = { 0, 9 }, decimals_number = 0 },
				{ setting_id = "fake_havoc_min", type = "numeric", default_value = 30, range = { 1, 40 }, decimals_number = 0 },
				{ setting_id = "fake_havoc_max", type = "numeric", default_value = 40, range = { 1, 40 }, decimals_number = 0 },
			},
		},
		-- 调试探针日志（默认关闭）
		-- 这些 [cm][...] 日志在名字 hook 热路径上，开启时 ≈95 行/秒（33 分钟 29 MB，占整份日志 97.8%）。
		-- 只在排查 AnonPlayers / anon_names 的匿名泄漏时打开；临时开可用聊天命令 /markdebug on（不落盘）。
		{
			setting_id = "debug_log",
			type = "checkbox",
			default_value = false,
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
