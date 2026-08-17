-- chunkname: @scripts/mods/color_mark/color_mark_localization.lua
-- 彩色标记 (ColorMark) 本地化

return {
	mod_name = {
		en = "ColorMark",
		["zh-cn"] = "彩色标记",
	},
	mod_description = {
		en = "Mark special players with chat commands and display their names in custom colors. Works alongside AnonPlayers.",
		["zh-cn"] = "用聊天命令标记特殊玩家，让他们的名字以指定颜色显示。与 AnonPlayers 兼容。",
	},

	-- 设置项
	mark_display_mode = {
		en = "Marked Name Display",
		["zh-cn"] = "标记名字显示",
	},
	mark_display_mode_description = {
		en = "How a marked player's name is displayed. Anonymous+Color keeps AnonPlayers masking. Real+Color shows the real name (bypasses AnonPlayers for marked players only).",
		["zh-cn"] = "被标记玩家名字的显示方式。匿名+颜色：保留 AnonPlayers 的隐藏；真名+颜色：显示真实账号名（仅对被标记玩家生效，会绕过 AnonPlayers 的隐藏）。",
	},
	display_mode_anon_color_setting_text = {
		en = "Anonymous + Color",
		["zh-cn"] = "匿名 + 颜色",
	},
	display_mode_real_color_setting_text = {
		en = "Real Name + Color",
		["zh-cn"] = "真名 + 颜色",
	},
	display_mode_label_color_setting_text = {
		en = "Label + Color",
		["zh-cn"] = "标签 + 颜色",
	},
	players_list_show_real = {
		en = "Show Real Names in /players",
		["zh-cn"] = "/players 列表显示真名",
	},
	players_list_show_real_description = {
		en = "Display real account names in the /players list instead of anonymized names. Off by default to respect AnonPlayers.",
		["zh-cn"] = "/players 列表显示真实账号名而非匿名名。默认关闭以尊重 AnonPlayers 的隐藏设置。",
	},

	-- 命令反馈
	no_players = {
		en = "No other players in the current room.",
		["zh-cn"] = "当前房间没有其他玩家。",
	},
	mark_usage = {
		en = "Usage: /mark <number> <color>  (see /players for numbers; colors: red/orange/yellow/green/cyan/blue/purple/pink/white/gray or hex like ff8800)",
		["zh-cn"] = "用法：/mark <编号> <颜色>（用 /players 查看编号；颜色：红/橙/黄/绿/青/蓝/紫/粉/白/灰 或 hex 如 ff8800）",
	},
	invalid_color = {
		en = "Invalid color. Use a preset (red/orange/yellow/green/cyan/blue/purple/pink/white/gray) or hex (e.g. ff8800).",
		["zh-cn"] = "无效颜色。使用预设（红/橙/黄/绿/青/蓝/紫/粉/白/灰）或 hex（如 ff8800）。",
	},
	invalid_index = {
		en = "Invalid number. Run /players to see the current list.",
		["zh-cn"] = "无效编号。运行 /players 查看当前列表。",
	},
	marked = {
		en = "marked. Use /unmark <number> to remove.",
		["zh-cn"] = "已标记。使用 /unmark <编号> 取消。",
	},
	unmarked = {
		en = "mark removed.",
		["zh-cn"] = "标记已取消。",
	},
	unmark_usage = {
		en = "Usage: /unmark <number>  (see /players for numbers)",
		["zh-cn"] = "用法：/unmark <编号>（用 /players 查看编号）",
	},
	no_marks = {
		en = "No players marked yet. Use /mark <number> <color>.",
		["zh-cn"] = "还没有标记任何玩家。使用 /mark <编号> <颜色>。",
	},
	marks_header = {
		en = "Marked players:",
		["zh-cn"] = "已标记玩家：",
	},
	marks_usage_hint = {
		en = "Run /players to refresh the room list.",
		["zh-cn"] = "运行 /players 刷新房间列表。",
	},
}
