-- chunkname: @scripts/mods/color_mark/color_mark.lua
--[[
	彩色标记 (ColorMark) v1.0.0
	Author: CiJhuiDi
	用聊天命令标记队伍成员，被标记玩家的名字以指定颜色显示（富文本 {#color}）。
	与 AnonPlayers 共存：未标记玩家完全走 AnonPlayers 匿名逻辑，标记玩家被本 mod 截断上色。

	命令：
		/squad               列出当前队伍成员（编号 + 真名）
		/mark <编号> <颜色>  标记（编号来自 /squad 列表；颜色：预设名或 hex）
		/unmark <编号>       取消标记
		/marks               查看已标记

	标识：一律使用账号唯一 ID（account_id），不用名字匹配。
	队伍列表来自 Managers.data_service.social:fetch_party_members()（PlayerInfo，真名不受 AnonPlayers UI 隐藏影响）。
	标记跨会话持久化，任意房间遇到被标记玩家都显示彩色。
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

-- 当前队伍列表缓存（/squad 刷新，/mark /unmark 用编号索引）
mod.squad_list = {}

-- character_id -> account_id 映射（供 profile_utils 等只有 profile 的 hook 使用，/squad 时构建）
mod.character_account_map = {}

local function build_character_map()
	mod.character_account_map = {}

	local social = Managers.data_service and Managers.data_service.social

	if not social or type(social.fetch_party_members) ~= "function" then
		return
	end

	local ok, promise = pcall(social.fetch_party_members, social)

	if not (ok and type(promise) == "table" and type(promise.next) == "function") then
		return
	end

	promise:next(function (members)
		if type(members) ~= "table" then
			return
		end

		local map = {}

		for _, player_info in pairs(members) do
			local ok_acc, account_id = pcall(function ()
				return player_info:account_id()
			end)

			local ok_char, character_id = pcall(function ()
				return player_info:character_id()
			end)

			if ok_acc and ok_char and account_id and character_id then
				map[character_id] = account_id
			end
		end

		mod.character_account_map = map
	end):catch(function ()
		-- 映射构建失败不阻塞主流程
	end)
end

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

-- PlayerInfo 真名（character_name 优先，_account_name 兜底）
local function get_player_name(player_info)
	if not player_info then
		return "?"
	end

	local ok, name = pcall(function ()
		return player_info:character_name()
	end)

	if ok and name and name ~= "" then
		return name
	end

	if player_info._account_name then
		return player_info._account_name
	end

	return "?"
end

-- ##########################################################
-- ################## 队伍列表 ##############################

-- 刷新当前队伍列表并输出到聊天；列表缓存在 mod.squad_list
local function refresh_squad()
	build_character_map()
	mod.squad_list = {}

	local social = Managers.data_service and Managers.data_service.social

	if not social or type(social.fetch_party_members) ~= "function" then
		send_message(mod:localize("err_no_social"))

		return
	end

	local ok, promise = pcall(social.fetch_party_members, social)

	if not (ok and type(promise) == "table" and type(promise.next) == "function") then
		send_message(mod:localize("err_squad_failed"))

		return
	end

	promise:next(function (members)
		local list = {}

		if type(members) == "table" then
			-- 自己（不可标记）
			local local_account_id
			local local_player = Managers.player and Managers.player:local_player(1)

			if local_player then
				local ok_local, id = pcall(function ()
					return local_player:account_id()
				end)

				if ok_local and id then
					local_account_id = id
				end
			end

			for _, player_info in pairs(members) do
				local ok_acc, account_id = pcall(function ()
					return player_info:account_id()
				end)

				if ok_acc and account_id and account_id ~= "" and account_id ~= local_account_id then
					list[#list + 1] = {
						account_id = account_id,
						name = get_player_name(player_info),
					}
				end
			end
		end

		table.sort(list, function (a, b)
			return (a.name or "") < (b.name or "")
		end)

		mod.squad_list = list

		if #list == 0 then
			send_message(mod:localize("no_players"))

			return
		end

		local parts = {}

		for i = 1, #list do
			parts[#parts + 1] = string.format("%d. %s", i, list[i].name)
		end

		send_message(table.concat(parts, "  "))
	end):catch(function ()
		send_message(mod:localize("err_squad_failed"))
	end)
end

-- ##########################################################
-- ################## 命令 ###################################

mod:command("squad", "List current party members", refresh_squad)

mod:command("mark", "Mark a party member with a color", function (...)
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

	local entry = mod.squad_list[tonumber(num_str)]

	if not entry then
		send_message(mod:localize("invalid_index"))

		return
	end

	mod.marks[entry.account_id] = {
		color = color,
		name = entry.name,
		time = os.time(),
	}

	send_message(color_string(color, entry.name) .. " " .. mod:localize("marked"))
end)

mod:command("unmark", "Remove a mark", function (...)
	local text = table.concat({ ... }, " ")
	local num_str = text:match("^(%d+)$")

	if not num_str then
		send_message(mod:localize("unmark_usage"))

		return
	end

	local entry = mod.squad_list[tonumber(num_str)]

	if not entry then
		send_message(mod:localize("invalid_index"))

		return
	end

	mod.marks[entry.account_id] = nil
	send_message(entry.name .. " " .. mod:localize("unmarked"))
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

-- RemotePlayer:name() —— 头顶名字（hub+任务），核心
mod:hook("RemotePlayer", "name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)

		if mod:get("mark_display_mode") == "real_color" then
			local real = self._cached_name

			if real then
				name = real
			elseif HAS_STEAM and self._human_controlled and self._peer_id then
				local ok, steam_name = pcall(Steam.user_name, self._peer_id)

				if ok and steam_name and steam_name ~= "" then
					name = steam_name
				end
			end
		end

		return color_string(mod.marks[account_id].color, name)
	end

	return func(self, ...)
end)

-- RemotePlayer:character_name() —— 结算等
mod:hook("RemotePlayer", "character_name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)

		if mod:get("mark_display_mode") == "real_color" then
			local real = self._cached_name

			if real then
				name = real
			elseif HAS_STEAM and self._human_controlled and self._peer_id then
				local ok, steam_name = pcall(Steam.user_name, self._peer_id)

				if ok and steam_name and steam_name ~= "" then
					name = steam_name
				end
			end
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
-- 只有 profile，用 character_id -> account_id 映射表反查（/squad 时构建）
mod:hook_require("scripts/utilities/profile_utils", function (instance)
	mod:hook(instance, "character_name", function (func, profile, ...)
		local account_id = profile and profile.character_id and mod.character_account_map[profile.character_id]

		if account_id and mod.marks[account_id] then
			return color_string(mod.marks[account_id].color, func(profile, ...))
		end

		return func(profile, ...)
	end)
end)
