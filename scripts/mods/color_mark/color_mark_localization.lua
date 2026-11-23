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

	-- 设置项 / 命令：混淆进度显示（true_level 显示的等级 / 威望 / 浩劫层数）
	fake_progress_group = {
		en = "Obfuscate progress (true_level)",
		["zh-cn"] = "混淆进度显示（true_level）",
	},
	fake_progress_group_description = {
		en = "Replaces the level / prestige / Havoc rank shown by the true_level mod with random values, re-rolled every time the game starts. Each account gets its own set for the session. Display-only — other clients and the server are unaffected. Requires the true_level mod.",
		["zh-cn"] = "把 true_level 模组显示的等级 / 威望 / 浩劫层数换成随机假值，每次进游戏重新随机；每个账号一组、会话内保持不变。仅改本机显示，队友与服务器不受影响。需要安装 true_level。",
	},
	fake_range_group = {
		en = "Fake value range (min / max)",
		["zh-cn"] = "假值区间（最低 / 最高）",
	},
	fake_range_group_description = {
		en = "Range the random fake values are rolled in, per value. 'Level' is the in-game character level (1-30); 'true level' is what the true_level mod computes past max level, which can go far beyond 30. Note: if the true level range goes above 30, the character level is shown as max level 30 — extra levels only exist after max level, so '29 (+216)' would be an impossible character. Defaults look like a real player: level 25-30, true level 100-300, prestige 0-3, Havoc 30-40. Changes take effect on the next roll — use /cmfake roll to re-roll immediately.",
		["zh-cn"] = "随机假值的取值区间（每个值一组最低 / 最高）。「等级」是游戏内的角色等级（1-30）；「真等级」是 true_level 模组在满级后继续累加出来的等级，可以远超 30。注意：**真等级区间一旦超过 30，角色等级会自动显示为满级 30** —— 额外等级只存在于满级之后，「29 (+216)」这种角色是不存在的。默认贴近真实玩家：等级 25-30、真等级 100-300、威望 0-3、浩劫 30-40。改完下次随机生效；想立刻生效用 /cmfake roll 重掷。",
	},
	fake_level_min = {
		en = "Level min",
		["zh-cn"] = "等级 · 最低",
	},
	fake_level_max = {
		en = "Level max",
		["zh-cn"] = "等级 · 最高",
	},
	fake_true_level_min = {
		en = "True level min",
		["zh-cn"] = "真等级 · 最低",
	},
	fake_true_level_max = {
		en = "True level max",
		["zh-cn"] = "真等级 · 最高",
	},
	fake_prestige_min = {
		en = "Prestige min",
		["zh-cn"] = "威望 · 最低",
	},
	fake_prestige_max = {
		en = "Prestige max",
		["zh-cn"] = "威望 · 最高",
	},
	fake_havoc_min = {
		en = "Havoc rank min",
		["zh-cn"] = "浩劫层数 · 最低",
	},
	fake_havoc_max = {
		en = "Havoc rank max",
		["zh-cn"] = "浩劫层数 · 最高",
	},
	fake_progress_enable = {
		en = "Enable (master switch)",
		["zh-cn"] = "总开关",
	},
	fake_progress_enable_description = {
		en = "Master switch. Off = nothing is obfuscated (neither yours nor teammates').",
		["zh-cn"] = "总开关。关闭 = 自己和队友的进度都不混淆。",
	},
	fake_progress_self_enable = {
		en = "Obfuscate MY progress",
		["zh-cn"] = "混淆我自己",
	},
	fake_progress_self_enable_description = {
		en = "Replace the level / prestige / Havoc rank shown for YOU with random values.",
		["zh-cn"] = "把显示给「你自己」的等级 / 威望 / 浩劫层数换成随机假值。",
	},
	fake_progress_other_enable = {
		en = "Obfuscate TEAMMATES' progress",
		["zh-cn"] = "混淆队友",
	},
	fake_progress_other_enable_description = {
		en = "Replace the level / prestige / Havoc rank shown for OTHER players with random values (each account gets its own set).",
		["zh-cn"] = "把显示给「其他玩家」的等级 / 威望 / 浩劫层数换成随机假值（每个账号各一组）。",
	},
	command_cmfake_description = {
		en = "Obfuscated progress: /cmfake shows the current state, /cmfake roll re-rolls, /cmfake on|off is the master switch, /cmfake self on|off and /cmfake other on|off toggle your own / teammates' obfuscation.",
		["zh-cn"] = "混淆进度显示：/cmfake 查看当前状态，/cmfake roll 重新随机，/cmfake on|off 总开关，/cmfake self on|off 与 /cmfake other on|off 分别控制自己 / 队友。",
	},
	fake_progress_rolled = {
		en = "[ColorMark] Re-rolled: {values}. The numbers already on screen only update when that panel rebuilds (open/close the social or party panel, or enter/leave the hub) — that's UI text caching, the command did work.",
		["zh-cn"] = "[彩色标记] 已重掷：{values}。界面上已显示的旧数字要等那个面板重建才会变（开合一次社交 / 队伍面板，或进出大厅即可）—— 那是 UI 的文本缓存，命令本身已经生效。",
	},
	fake_progress_status = {
		en = "[ColorMark] Obfuscated progress — master {master} | me {self} | teammates {other} | ranges: {ranges} | {groups} set(s), level/Havoc: {values}. Usage: /cmfake [roll|on|off|self on|off|other on|off]",
		["zh-cn"] = "[彩色标记] 混淆进度 —— 总开关 {master} | 自己 {self} | 队友 {other} | 区间 {ranges} | 共 {groups} 组，等级/浩劫：{values}。用法：/cmfake [roll|on|off|self on|off|other on|off]",
	},
	fake_progress_state_on = {
		en = "ON",
		["zh-cn"] = "已开启",
	},
	fake_progress_state_off = {
		en = "OFF",
		["zh-cn"] = "已关闭",
	},
	fake_progress_scope_master = {
		en = "master switch",
		["zh-cn"] = "总开关",
	},
	fake_progress_scope_self = {
		en = "my progress",
		["zh-cn"] = "我自己",
	},
	fake_progress_scope_other = {
		en = "teammates' progress",
		["zh-cn"] = "队友",
	},
	fake_progress_set_scope = {
		en = "[ColorMark] Obfuscated progress: {scope} = {state} (saved).",
		["zh-cn"] = "[彩色标记] 混淆进度：{scope} = {state}（已保存）。",
	},
	fake_progress_no_true_level = {
		en = "[ColorMark] true_level mod not detected — nothing to obfuscate.",
		["zh-cn"] = "[彩色标记] 未检测到 true_level 模组，没有可混淆的内容。",
	},

	-- 设置项 / 命令：调试探针日志（默认关闭，只在排查匿名泄漏时打开）
	debug_log = {
		en = "Debug log ([cm] probes)",
		["zh-cn"] = "调试日志（[cm] 探针）",
	},
	debug_log_description = {
		en = "Off by default. When on, every name lookup writes a log line (roughly 95 lines/second, ~29 MB per 30 minutes). Only turn it on to diagnose name/anon issues; you can also toggle it in-game with /markdebug on|off (session only, not saved).",
		["zh-cn"] = "默认关闭。开启后每次名字查询都会写一行日志（约 95 行/秒，30 分钟约 29 MB）。只在排查名字/匿名问题时开启；也可以用聊天命令 /markdebug on|off 临时开关（仅本次会话，不写配置）。",
	},
	command_markdebug_description = {
		en = "Toggle the [cm] debug probe log for this session: /markdebug on|off. Without an argument it shows the current state.",
		["zh-cn"] = "临时开关 [cm] 调试探针日志：/markdebug on|off。不带参数则显示当前状态。",
	},
	debug_log_on = {
		en = "[ColorMark] Debug log: ON (this session only; the Mod Options checkbox is unchanged). Use /markdebug off to stop.",
		["zh-cn"] = "[彩色标记] 调试日志：已开启（仅本次会话，设置项不变）。用 /markdebug off 关闭。",
	},
	debug_log_off = {
		en = "[ColorMark] Debug log: OFF.",
		["zh-cn"] = "[彩色标记] 调试日志：已关闭。",
	},
	debug_log_off_setting_on = {
		en = "[ColorMark] Session override cleared, but the \"Debug log\" option is still ON. Uncheck it in Mod Options to stop logging.",
		["zh-cn"] = "[彩色标记] 本次会话的临时开启已取消，但设置项「调试日志」仍是开启状态 —— 日志仍在写，请到 Mod Options 取消勾选。",
	},
	debug_log_state_on = {
		en = "ON (this session)",
		["zh-cn"] = "开启（本次会话临时）",
	},
	debug_log_state_setting_on = {
		en = "ON (Mod Options)",
		["zh-cn"] = "开启（来自设置项）",
	},
	debug_log_state_off = {
		en = "OFF",
		["zh-cn"] = "关闭",
	},
	debug_log_status = {
		en = "[ColorMark] Debug log: {state}. Usage: /markdebug on|off",
		["zh-cn"] = "[彩色标记] 调试日志：{state}。用法：/markdebug on|off",
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
