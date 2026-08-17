-- chunkname: @scripts/mods/color_mark/color_mark.lua
--[[
	彩色标记 (ColorMark)
	用聊天命令标记特殊玩家，被标记玩家的名字以指定颜色显示（富文本 {#color}）。
	与 AnonPlayers 共存：未标记玩家完全走 AnonPlayers 匿名逻辑，标记玩家被本 mod 截断上色。

	命令：
		/players               列出当前房间玩家（编号 + 显示名）
		/mark <编号> <颜色>    标记（颜色：预设名或 hex）
		/unmark <编号>         取消标记
		/marks                 查看已标记列表

	标识：一律使用账号唯一 ID（account_id），不用名字匹配（生僻字/特殊符号不可输入）。
	参考：AnonPlayers 的 hook 清单与 RemotePlayer/PlayerInfo 账号字段（反编译源码确认）。
]]

local mod = get_mod("color_mark")

-- 预设色板
local PRESET_COLORS = {
	red    = { 255, 80, 80 },
	orange = { 255, 160, 60 },
	yellow = { 255, 230, 80 },
	green  = { 90, 230, 120 },
	cyan   = { 80, 220, 230 },
	blue   = { 90, 150, 255 },
	purple = { 190, 120, 255 },
	pink   = { 255, 120, 200 },
	white  = { 240, 240, 240 },
	gray   = { 160, 160, 160 },
}

-- 标记表（跨会话持久化）：[account_id] = { color = {r,g,b}, name = 显示名缓存, time = os.time() }
mod.marks = mod:persistent_table("marks")

-- character_id -> account_id 映射（供 profile_utils 等只有 profile 的 hook 使用，/players 时构建）
mod.character_account_map = {}

-- ##########################################################
-- ################## 工具函数 ##############################

local function send_message(message)
	if Managers.event then
		Managers.event:trigger("system_chat_message", tostring(message), "SYSTEM")
	end
end

local function color_string(color, name)
	return string.format("{#color(%d,%d,%d)}%s{#reset()}", color[1], color[2], color[3], tostring(name))
end

-- 颜色解析：预设名 or hex（3/6 位）
local function parse_color(text)
	if not text then
		return nil
	end

	local lower = string.lower(text)
	local preset = PRESET_COLORS[lower]

	if preset then
		return { preset[1], preset[2], preset[3] }
	end

	local hex = lower:match("^#?(%x+)$")

	if hex then
		local len = #hex

		if len == 6 then
			return {
				tonumber(hex:sub(1, 2), 16),
				tonumber(hex:sub(3, 4), 16),
				tonumber(hex:sub(5, 6), 16),
			}
		elseif len == 3 then
			return {
				tonumber(hex:sub(1, 1) .. hex:sub(1, 1), 16),
				tonumber(hex:sub(2, 2) .. hex:sub(2, 2), 16),
				tonumber(hex:sub(3, 3) .. hex:sub(3, 3), 16),
			}
		end
	end

	return nil
end

-- 显示名（尊重 AnonPlayers：player:name() 返回匿名后的名字）
local function get_display_name(player)
	local ok, name = pcall(function ()
		return player:name()
	end)

	if ok and name and name ~= "" then
		return name
	end

	return "?"
end

-- 账号唯一 ID（标记 key）
local function get_account_id(player)
	if player and player.account_id then
		local ok, id = pcall(player.account_id, player)

		if ok and id and id ~= "" then
			return id
		end
	end

	return nil
end

-- 真名（real_color 模式用；拿不到返回 nil）
local function get_real_name(player)
	if not player then
		return nil
	end

	if player._cached_name then
		return player._cached_name
	end

	if HAS_STEAM and player._human_controlled and player._peer_id then
		local ok, name = pcall(Steam.user_name, player._peer_id)

		if ok and name and name ~= "" then
			return name
		end
	end

	return nil
end

-- ##########################################################
-- ################## 玩家列表 ##############################

-- 构建当前房间玩家列表（排除自己），同时刷新 character_id -> account_id 映射
local function refresh_room_players()
	local player_manager = Managers.player
	local list = {}

	mod.character_account_map = {}

	if not player_manager then
		return list
	end

	local all = player_manager:players()
	local local_player = player_manager:local_player(1)

	if all then
		for unique_id, player in pairs(all) do
			if player ~= local_player then
				local account_id = get_account_id(player)

				if account_id then
					list[#list + 1] = {
						player = player,
						account_id = account_id,
					}

					local profile = player._profile

					if profile and profile.character_id then
						mod.character_account_map[profile.character_id] = account_id
					end
				end
			end
		end
	end

	-- 按显示名排序，保持列表稳定
	table.sort(list, function (a, b)
		return (get_display_name(a.player) or "") < (get_display_name(b.player) or "")
	end)

	return list
end

-- ##########################################################
-- ################## 命令 ###################################

mod:command("players", "List players in the current room", function ()
	local list = refresh_room_players()

	if #list == 0 then
		send_message(mod:localize("no_players"))

		return
	end

	local show_real = mod:get("players_list_show_real")
	local parts = {}

	for i = 1, #list do
		local entry = list[i]
		local name

		if show_real then
			name = get_real_name(entry.player) or get_display_name(entry.player)
		else
			name = get_display_name(entry.player)
		end

		local mark = mod.marks[entry.account_id]

		if mark then
			name = color_string(mark.color, name)
		end

		parts[#parts + 1] = string.format("%d. %s", i, name)
	end

	send_message(table.concat(parts, "  "))
end)

mod:command("mark", "Mark a player with a color", function (...)
	-- 兼容 DMF 参数传递方式（分割参数或整串），统一合并后解析
	local text = table.concat({ ... }, " ")
	local num_str, color_text = text:match("^(%d+)%s+(%S+)$")

	if not num_str then
		send_message(mod:localize("mark_usage"))

		return
	end

	local color = parse_color(color_text)

	if not color then
		send_message(mod:localize("invalid_color"))

		return
	end

	local list = refresh_room_players()
	local index = tonumber(num_str)
	local entry = list[index]

	if not entry then
		send_message(mod:localize("invalid_index"))

		return
	end

	mod.marks[entry.account_id] = {
		color = color,
		name = get_display_name(entry.player),
		time = os.time(),
	}

	send_message(color_string(color, get_display_name(entry.player)) .. " " .. mod:localize("marked"))
end)

mod:command("unmark", "Remove a mark", function (...)
	local text = table.concat({ ... }, " ")
	local num_str = text:match("^(%d+)$")

	if not num_str then
		send_message(mod:localize("unmark_usage"))

		return
	end

	local list = refresh_room_players()
	local entry = list[tonumber(num_str)]

	if not entry then
		send_message(mod:localize("invalid_index"))

		return
	end

	mod.marks[entry.account_id] = nil
	send_message(get_display_name(entry.player) .. " " .. mod:localize("unmarked"))
end)

mod:command("marks", "List marked players", function ()
	local count = 0
	local parts = {}

	for account_id, mark in pairs(mod.marks) do
		count = count + 1
		parts[#parts + 1] = color_string(mark.color, mark.name or account_id)
	end

	if count == 0 then
		send_message(mod:localize("no_marks"))

		return
	end

	table.sort(parts)

	local message = mod:localize("marks_header") .. " " .. table.concat(parts, "  ")
	send_message(message .. "  (" .. mod:localize("marks_usage_hint") .. ")")
end)

-- ##########################################################
-- ################## 名字 hook #############################

-- 统一包装：命中标记 -> 彩色字符串；未命中 -> 放行
local function colorize_name(account_id, name)
	local mark = account_id and mod.marks[account_id]

	if not mark then
		return nil
	end

	local mode = mod:get("mark_display_mode")

	if mode == "real_color" then
		-- 真名由调用处提供（name 参数已是真名）；拿不到则用传入名
		return color_string(mark.color, name)
	else
		-- anon_color / label_color：直接给传入的显示名上色
		return color_string(mark.color, name)
	end
end

-- RemotePlayer:name() —— 头顶名字（hub+任务），核心
mod:hook("RemotePlayer", "name", function (func, self, ...)
	local account_id = get_account_id(self)

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)

		if mod:get("mark_display_mode") == "real_color" then
			name = get_real_name(self) or name
		end

		return color_string(mod.marks[account_id].color, name)
	end

	return func(self, ...)
end)

-- RemotePlayer:character_name() —— 结算等
mod:hook("RemotePlayer", "character_name", function (func, self, ...)
	local account_id = get_account_id(self)

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)

		if mod:get("mark_display_mode") == "real_color" then
			name = get_real_name(self) or name
		end

		return color_string(mod.marks[account_id].color, name)
	end

	return func(self, ...)
end)

-- PlayerInfo:character_name() —— 社交/聊天/结算
-- 注意：AnonPlayers 对 user_display_name 用了 hook_origin，此处一律用普通 hook（链尾是 origin）
mod:hook("PlayerInfo", "character_name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)

		if mod:get("mark_display_mode") == "real_color" and self._account_name then
			name = self._account_name
		end

		return color_string(mod.marks[account_id].color, name)
	end

	return func(self, ...)
end)

mod:hook("PlayerInfo", "user_display_name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)

		if mod:get("mark_display_mode") == "real_color" and self._account_name then
			name = self._account_name
		end

		return color_string(mod.marks[account_id].color, name)
	end

	return func(self, ...)
end)

-- PresenceEntryImmaterium:character_name() —— 邀请/组队界面
-- 注意：presence 的 account_id 是平台用户 ID，可能与标记 key 不同体系；匹配不到则放行（不崩）
mod:hook("PresenceEntryImmaterium", "character_name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and account_id ~= "" and mod.marks[account_id] then
		return color_string(mod.marks[account_id].color, func(self, ...))
	end

	return func(self, ...)
end)

-- profile_utils:character_name(profile) —— 预任务大厅/角色选择
-- 只有 profile，用 character_id -> account_id 映射表反查
mod:hook_require("scripts/utilities/profile_utils", function (instance)
	mod:hook(instance, "character_name", function (func, profile, ...)
		local account_id = profile and profile.character_id and mod.character_account_map[profile.character_id]

		if account_id and mod.marks[account_id] then
			return color_string(mod.marks[account_id].color, func(profile, ...))
		end

		return func(profile, ...)
	end)
end)
