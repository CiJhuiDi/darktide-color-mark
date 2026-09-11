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

-- 标记表（跨会话持久化，mod:set 存 user_settings.config）：[account_id] = { color = {r,g,b}, name = 显示名缓存, time = os.time() }
-- 注意：DMF persistent_table 只是内存表不落盘，必须用 mod:set 才能跨重启
mod.marks = mod:get("marks") or {}

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

-- 清洗显示名：剥富文本标记 {#...} + 私有区图标字符（U+E000-U+F8FF，平台图标/职业图标等，名牌/队伍面板渲染异常源）
-- ⚠️ 私有区是 3 字节 UTF-8，必须按完整序列匹配：U+E000-U+EFFF = EE 80 80-EE BF BF；U+F000-U+F8FF = EF 80 80-EF A3 BF
-- 不能写成一字节范围 [\x80-\xEF]（Lua 字符集按字节解析，会剥掉所有 UTF-8 多字节字符包括中文！2026-08-22 修复）
local function strip_rich_text(text)
	if not text then
		return text
	end

	local cleaned = text:gsub("%{#[^}]*}", "")
	cleaned = cleaned:gsub("\xEE[\x80-\xBF][\x80-\xBF]", "") -- U+E000-U+EFFF
	cleaned = cleaned:gsub("\xEF[\x80-\xA3][\x80-\xBF]", "") -- U+F000-U+F8FF（EF A4 起是 CJK 兼容表意，不能剥）
	cleaned = cleaned:gsub("^%s+", ""):gsub("%s+$", "")

	return cleaned
end

-- 标记数据版本：nil/1 = 旧版（name 可能被匿名污染/富文本），2 = 新版（真名）
local MARK_VERSION = 2

-- 加载时迁移旧标记：清洗富文本残留 + 补版本字段
local function migrate_marks()
	local changed = false

	for account_id, mark in pairs(mod.marks) do
		if mark.name then
			local cleaned = strip_rich_text(mark.name)

			if cleaned ~= mark.name then
				mark.name = cleaned
				changed = true
			end
		end

		if not mark.version then
			mark.version = 1 -- 旧数据：name 可能不是真名
			changed = true
		end
	end

	if changed then
		mod:set("marks", mod.marks)
	end
end

migrate_marks()

-- 未标记玩家显示名：走 character_name（AnonPlayers 匿名成掩码），直播安全
local function get_masked_name(player_info)
	if not player_info then
		return "?"
	end

	local ok, name = pcall(function ()
		return player_info:character_name()
	end)

	if ok and name and name ~= "" then
		return name
	end

	return "?"
end

-- 已标记玩家真名：user_display_name 优先（AnonPlayers 只按 anon_other_accounts 匿名它，=0 时返回平台真名）；
-- character_name 会被 anon_others 匿名成面具名（???/个性名/随机码），仅兜底
-- 注意：调用 user_display_name 时用标志位绕开 color_mark 自己的 hook（否则返回被包装的彩色富文本）
mod._getting_real_name = false

local function get_real_name(player_info)
	if not player_info then
		return "?"
	end

	mod._getting_real_name = true
	local ok_acc, acc_name = pcall(function ()
		return player_info:user_display_name()
	end)
	mod._getting_real_name = false

	mod:info("[cm][squad] user_display_name ok=%s val=%s", tostring(ok_acc), tostring(acc_name))

	if ok_acc and acc_name and acc_name ~= "" and acc_name ~= "N/A" then
		-- 清洗平台图标等私有区字符（不剥中文）
		local cleaned = strip_rich_text(acc_name)

		if cleaned and cleaned ~= "" then
			return cleaned
		end
	end

	local ok, name = pcall(function ()
		return player_info:character_name()
	end)

	mod:info("[cm][squad] char_name ok=%s val=%s", tostring(ok), tostring(name))

	if ok and name and name ~= "" then
		return name
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
					local mark = mod.marks[account_id]
					local real_name = get_real_name(player_info)

					-- 已标记：自动升级真名；未标记：显示掩码（AnonPlayers 匿名），直播安全
					local display_name

					if mark then
						display_name = real_name

						-- 自动升级：旧版标记（version~=2）或 name 为空/被旧版清洗误剥（2026-08-22 中文名 bug）时补真名
						if real_name and real_name ~= "?" and (mark.version ~= MARK_VERSION or not mark.name or mark.name == "") then
							mark.name = real_name
							mark.version = MARK_VERSION
							mod:set("marks", mod.marks)
						end
					else
						display_name = get_masked_name(player_info)
					end

					list[#list + 1] = {
						account_id = account_id,
						name = display_name,
						real_name = real_name, -- 标记时用（/mark 存真名，不显示在列表里）
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

mod:command("squad", mod:localize("command_squad_description"), refresh_squad)

mod:command("mark", mod:localize("command_mark_description"), function (...)
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
		name = strip_rich_text(entry.real_name or entry.name),
		version = MARK_VERSION,
		time = os.time(),
	}
	mod:set("marks", mod.marks)

	send_message(color_string(color, entry.name) .. " " .. mod:localize("marked"))
end)

mod:command("unmark", mod:localize("command_unmark_description"), function (...)
	local text = table.concat({ ... }, " ")
	local num_str = text:match("^(%d+)$")

	if not num_str then
		send_message(mod:localize("unmark_usage"))

		return
	end

	-- 只认 /marks 列表编号（排序与 /marks 一致；玩家离队后也能取消）
	local mark_ids = {}

	for account_id, _ in pairs(mod.marks) do
		mark_ids[#mark_ids + 1] = account_id
	end

	table.sort(mark_ids)

	local mark_id = mark_ids[tonumber(num_str)]

	if not mark_id then
		send_message(mod:localize("invalid_index"))

		return
	end

	local mark = mod.marks[mark_id]
	local display = mark.name or mark_id

	mod.marks[mark_id] = nil
	mod:set("marks", mod.marks)
	send_message(display .. " " .. mod:localize("unmarked"))
end)

mod:command("marks", mod:localize("command_marks_description"), function ()
	local entries = {}

	for account_id, mark in pairs(mod.marks) do
		local display = (mark.version == MARK_VERSION and mark.name) or account_id
		local hint = mark.version == MARK_VERSION and "" or mod:localize("mark_old_data_hint")

		entries[#entries + 1] = {
			id = account_id,
			name = color_string(mark.color, display) .. hint,
		}
	end

	if #entries == 0 then
		send_message(mod:localize("no_marks"))

		return
	end

	table.sort(entries, function (a, b)
		return a.id < b.id
	end)

	local parts = {}

	for i = 1, #entries do
		parts[#parts + 1] = string.format("%d.%s", i, entries[i].name)
	end

	local message = mod:localize("marks_header") .. " " .. table.concat(parts, "  ")
	send_message(message .. "  (" .. mod:localize("marks_usage_hint") .. ")")
end)

-- ##########################################################
-- ################## 名字 hook #############################

-- RemotePlayer:name() —— 头顶名字（hub+任务），核心
-- real_color 真名来源：新版标记的 mark.name（/squad 直读真名）→ _cached_name → Steam
-- 旧版标记（version~=2）name 可能是面具名，不用于显示，走兜底
mod:hook("RemotePlayer", "name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)
		local mark = mod.marks[account_id]

		mod:info("[cm][RP:name] hit acc=%s mode=%s mark_v=%s mark_name=%s raw=%s", tostring(account_id), tostring(mod:get("mark_display_mode")), tostring(mark.version), tostring(mark.name), tostring(name))

		if mod:get("mark_display_mode") == "real_color" then
			if mark.version == MARK_VERSION and mark.name and mark.name ~= "" then
				name = strip_rich_text(mark.name)
			else
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
		end

		return color_string(mark.color, name)
	end

	return func(self, ...)
end)

-- RemotePlayer:character_name() —— 结算等（同 name 的真名逻辑）
mod:hook("RemotePlayer", "character_name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	mod:info("[cm][RP:char_name] acc=%s marked=%s mode=%s", tostring(account_id), tostring(account_id ~= nil and mod.marks[account_id] ~= nil), tostring(mod:get("mark_display_mode")))

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)
		local mark = mod.marks[account_id]

		if mod:get("mark_display_mode") == "real_color" then
			if mark.version == MARK_VERSION and mark.name and mark.name ~= "" then
				name = strip_rich_text(mark.name)
			else
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
		end

		return color_string(mark.color, name)
	end

	return func(self, ...)
end)

-- PlayerInfo:character_name() —— 社交/聊天/结算
-- 注意：AnonPlayers 对 user_display_name 用了 hook_origin，此处一律用普通 hook（链尾是 origin）
mod:hook("PlayerInfo", "character_name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)
		local mark = mod.marks[account_id]

		mod:info("[cm][PI:char_name] hit acc=%s mode=%s mark_v=%s mark_name=%s raw=%s", tostring(account_id), tostring(mod:get("mark_display_mode")), tostring(mark.version), tostring(mark.name), tostring(name))

		if mod:get("mark_display_mode") == "real_color" then
			if mark.version == MARK_VERSION and mark.name and mark.name ~= "" then
				name = strip_rich_text(mark.name)
			elseif self._account_name then
				name = self._account_name
			end
		end

		return color_string(mark.color, name)
	end

	return func(self, ...)
end)

mod:hook("PlayerInfo", "user_display_name", function (func, self, ...)
	-- 内部取真名时直接放行（get_real_name），避免把自己包装的彩色富文本当真名
	if mod._getting_real_name then
		return func(self, ...)
	end

	local account_id = self.account_id and self:account_id()

	if account_id and mod.marks[account_id] then
		local name = func(self, ...)
		local mark = mod.marks[account_id]

		if mod:get("mark_display_mode") == "real_color" then
			if mark.version == MARK_VERSION and mark.name and mark.name ~= "" then
				name = strip_rich_text(mark.name)
			elseif self._account_name then
				name = self._account_name
			end
		end

		return color_string(mark.color, name)
	end

	return func(self, ...)
end)

-- PresenceEntryImmaterium:character_name() —— 邀请/组队界面 + 哀星号左下角队伍面板（PartyImmateriumMember:name → presence:character_name）
-- 注意：presence 的 account_id 是平台用户 ID，可能与标记 key 不同体系；匹配不到则放行（不崩）
-- 2026-08-22 修复：旧版直接 color_string(func 结果) = 彩色掩码（AnonPlayers 已匿名），补 real_color 真名替换
mod:hook("PresenceEntryImmaterium", "character_name", function (func, self, ...)
	local account_id = self.account_id and self:account_id()

	if account_id and account_id ~= "" and mod.marks[account_id] then
		local mark = mod.marks[account_id]
		local name = func(self, ...)

		mod:info("[cm][PEI:char_name] hit acc=%s mode=%s mark_v=%s mark_name=%s raw=%s", tostring(account_id), tostring(mod:get("mark_display_mode")), tostring(mark.version), tostring(mark.name), tostring(name))

		if mod:get("mark_display_mode") == "real_color" then
			if mark.version == MARK_VERSION and mark.name and mark.name ~= "" then
				name = strip_rich_text(mark.name)
			else
				-- 旧标记兜底：account_name（AnonPlayers 不匿名账户名）
				local ok_acc, acc_name = pcall(function ()
					return self:account_name()
				end)

				if ok_acc and acc_name and acc_name ~= "" and acc_name ~= "N/A" then
					name = acc_name
				end
			end
		end

		return color_string(mark.color, name)
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

-- ##########################################################
-- ################## 加载顺序自检 ##########################
-- color_mark 必须排在 AnonPlayers **之后**：DMF 的 hook 链「后注册 = 外层」，
-- 我们靠外层截断才能让被标记玩家的名字不被 AnonPlayers 再次匿名。顺序反了就会出现
-- 「解除不了匿名」的假故障（本 mod 返回的彩色名被 AnonPlayers 又匿名一遍）。
local anon_players_loaded_before_us = get_mod("AnonPlayers") ~= nil

mod.on_all_mods_loaded = function (self)
	local anon = get_mod("AnonPlayers")

	if not anon then
		return -- 没装 AnonPlayers，无需检查
	end

	local wrong_order = not anon_players_loaded_before_us

	-- 双保险：能拿到 load_order_id 时再比一次（id 越大 = 加载位置越靠后）
	local my_id = mod:get_internal_data("load_order_id")
	local anon_id = anon:get_internal_data("load_order_id")

	if type(my_id) == "number" and type(anon_id) == "number" and my_id < anon_id then
		wrong_order = true
	end

	if wrong_order then
		mod._order_warning = true
		mod:warning("[color_mark] " .. mod:localize("warn_load_order"))
		send_message(mod:localize("warn_load_order"))
	else
		mod:info("[color_mark] load order OK (AnonPlayers before color_mark)")
	end
end

-- 进游戏状态时补一次提示（加载完成那一刻聊天栏可能还没就绪）
mod.on_game_state_changed = function (self, status, state_name)
	if mod._order_warning and status == "enter" then
		mod._order_warning = nil
		send_message(mod:localize("warn_load_order"))
	end
end
