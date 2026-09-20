-- chunkname: @scripts/mods/color_mark/color_mark_localization.lua
-- 彩色标记 (ColorMark) 本地化

return {
	mod_name = {
		en = "ColorMark",
		["zh-cn"] = "彩色标记",
	},
	mod_description = {
		en = "Mark party members with chat commands and display their names in custom colors. Works alongside AnonPlayers.",
		["zh-cn"] = "用聊天命令标记队伍成员，让他们的名字以指定颜色显示。与 AnonPlayers 兼容。",
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

	-- 设置项：自己的名字
	self_name_group = {
		en = "My Own Name",
		["zh-cn"] = "我自己的名字",
	},
	self_name_group_description = {
		en = "Replace YOUR OWN displayed name with a custom alias (and color) on this client only. Other players still see your real name.",
		["zh-cn"] = "用自定义别名（可上色）替换**你自己**在本机的显示名。仅本机可见 —— 队友看到的仍是你原本的名字。",
	},
	self_alias_enable = {
		en = "Use a custom name for myself",
		["zh-cn"] = "用自定义名字显示自己",
	},
	self_alias_enable_description = {
		en = "When on, your own name is shown as the alias below (in the chosen color) instead of your real name.",
		["zh-cn"] = "开启后，你自己的名字将显示为下面填的别名（并用选定颜色），而不是真名。",
	},
	self_alias = {
		en = "My displayed name",
		["zh-cn"] = "我的显示名",
	},
	self_alias_description = {
		en = "The name shown in your place (HUD / chat / end-of-match / party panels / lobby). Leave empty to keep your real name.",
		["zh-cn"] = "替换你名字的文字（左下角 HUD / 聊天 / 结算 / 组队面板 / 大厅）。留空则仍显示真名。",
	},
	self_alias_placeholder = {
		en = "e.g. Me / 主播",
		["zh-cn"] = "例如：我 / 主播",
	},
	self_alias_color = {
		en = "Color of my displayed name",
		["zh-cn"] = "我的显示名颜色",
	},
	self_alias_color_description = {
		en = "Color used for the alias above.",
		["zh-cn"] = "上面那个别名使用的颜色。",
	},

	-- 命令 description（DMF 候选列表 / tab_complete 补全时显示）
	command_squad_description = {
		en = "List party members with numbers. Numbers are used by /mark.",
		["zh-cn"] = "列出队伍成员（带编号）。编号用于 /mark 标记。",
	},
	command_mark_description = {
		en = "Mark a party member: /mark <number> <color>. Number from /squad. Colors: red/orange/yellow/green/cyan/blue/purple/pink/white/gray or hex (e.g. ff8800).",
		["zh-cn"] = "标记队伍成员：/mark <编号> <颜色>。编号来自 /squad。颜色：红/橙/黄/绿/青/蓝/紫/粉/白/灰 或 hex（如 ff8800）。",
	},
	command_unmark_description = {
		en = "Remove a mark: /unmark <number>. Number from /marks list.",
		["zh-cn"] = "取消标记：/unmark <编号>。编号来自 /marks 列表。",
	},
	command_marks_description = {
		en = "List marked players. Numbers work with /unmark (including players who left the party).",
		["zh-cn"] = "列出已标记玩家。编号可配合 /unmark 取消（含已离队玩家）。",
	},

	-- 命令反馈
	no_players = {
		en = "No other players in the current party.",
		["zh-cn"] = "当前队伍没有其他玩家。",
	},
	mark_usage = {
		en = "Usage: /mark <number> <color>  (run /squad to list party members; colors: red/orange/yellow/green/cyan/blue/purple/pink/white/gray or hex like ff8800)",
		["zh-cn"] = "用法：/mark <编号> <颜色>（先用 /squad 查看队伍编号；颜色：红/橙/黄/绿/青/蓝/紫/粉/白/灰 或 hex 如 ff8800）",
	},
	invalid_color = {
		en = "Invalid color. Use a preset (red/orange/yellow/green/cyan/blue/purple/pink/white/gray) or hex (e.g. ff8800).",
		["zh-cn"] = "无效颜色。使用预设（红/橙/黄/绿/青/蓝/紫/粉/白/灰）或 hex（如 ff8800）。",
	},
	invalid_index = {
		en = "Invalid number. Run /marks to list marked players.",
		["zh-cn"] = "无效编号。运行 /marks 查看已标记列表。",
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
		en = "Usage: /unmark <number>  (number from /marks list)",
		["zh-cn"] = "用法：/unmark <编号>（编号来自 /marks 列表）",
	},
	no_marks = {
		en = "No players marked yet. Run /squad, then /mark <number> <color>.",
		["zh-cn"] = "还没有标记任何玩家。先 /squad，再 /mark <编号> <颜色>。",
	},
	marks_header = {
		en = "Marked players:",
		["zh-cn"] = "已标记玩家：",
	},
	marks_usage_hint = {
		en = "Numbers work with /unmark, including players who left the party",
		["zh-cn"] = "编号可配合 /unmark 取消（含已离队玩家）",
	},
	mark_old_data_hint = {
		en = " (old mark, re-mark to update real name)",
		["zh-cn"] = "（旧标记，重新标记以更新真名）",
	},
	err_no_social = {
		en = "Social service unavailable.",
		["zh-cn"] = "社交服务不可用。",
	},
	err_squad_failed = {
		en = "Failed to fetch party members.",
		["zh-cn"] = "获取队伍成员失败。",
	},
	warn_load_order = {
		en = "[ColorMark] Wrong load order: put color_mark AFTER AnonPlayers in mod_load_order.txt, otherwise AnonPlayers will re-anonymize the names this mod colors.",
		["zh-cn"] = "[彩色标记] 加载顺序不对：请在 mod_load_order.txt 里把 color_mark 排在 AnonPlayers 之后，否则 AnonPlayers 会把本 mod 上色的名字再匿名一遍（表现为解除不了匿名）。",
	},
}
