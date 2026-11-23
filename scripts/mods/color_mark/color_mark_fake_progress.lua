-- chunkname: @scripts/mods/color_mark/color_mark_fake_progress.lua
--[[
	混淆进度显示（v1.0.5）—— 把 true_level 显示出来的等级 / 威望 / 浩劫层数换成假值。

	背景：true_level 会把「真实等级 / 威望 / 浩劫层数」拼进名字文本，覆盖 9 个界面
	（主菜单角色卡、大厅、哀星号左下角队伍面板、结算、社交、组队查找、头顶名牌、装备、查看玩家）。
	本模块只拦它一个入口 —— 那 9 个界面最终都调用 mod.replace_level(text, true_levels, ...)。
	hook 它、把入参里的等级字段换成假值即可全覆盖，且不改 true_level 自身逻辑。

	规则：
	  * 每次进游戏随机一次（自建 PRNG，**不碰 math.random 序列**，避免影响游戏自身随机）
	  * 同一个账号在整个会话里保持同一组假值（按 account_id 缓存），不会来回跳
	  * 自己与每个队友各随机一组，且**自己 / 队友分别可开关**
	  * **假值区间可配**（最低 / 最高）：默认贴近真实玩家（等级 25-30、威望 0-3、浩劫 30-40），
	    避免出现"等级 3 / 浩劫 1"这种一眼看穿的随机数
	  * 只改本机显示：队友客户端与服务器数据不受影响

	⛔ 血泪教训（2026-10-11 实测崩溃）：
	  **绝不要在这个模块里调用 `Managers.player:local_player(1)` 之类去查"我是谁"。**
	  游戏启动早期（玩家管理还没初始化、_num_players=0）时，local_player 内部会走到
	  未初始化的 `peer_id`（C 函数）上 → `Access violation (0xc0000005)` 直接把游戏打崩，
	  而且这是 native crash，**pcall 挡不住**。
	  判断「是不是自己」一律用下面的 is_mine()：反查 true_level 自己的 _self/_others 缓存表（纯 Lua）。

	仅当装了 true_level 时生效；没装则本模块静默跳过。
]]

local mod = get_mod("color_mark")

-- 各维度的硬边界 + 默认区间
--   注意 level 与 true_level 是两回事：
--     level      = 角色等级，面板上就是 1-30
--     true_level = true_level 模组算的"真等级"—— 满级后按 XP 继续累加，**可以远超 30**（几百上千都正常）
--   默认值刻意贴近真实玩家分布，避免一眼看穿
local BOUNDS = {
	level      = { min = 1, max = 30,   def_min = 25,  def_max = 30 },
	true_level = { min = 1, max = 9999, def_min = 100, def_max = 300 },
	prestige   = { min = 0, max = 9,    def_min = 0,   def_max = 3 },
	havoc      = { min = 1, max = 40,   def_min = 30,  def_max = 40 },
}

local RANGE_KEYS = { "level", "true_level", "prestige", "havoc" }

-- 游戏内角色等级上限。true_level 的「额外等级」是**满级之后**按 XP 累加出来的，
-- 所以未满级时它根本不存在 —— 假值必须遵守这条，否则会造出 "29 (+216)" 这种不存在的角色。
local MAX_LEVEL = 30

-- 自建线性同余 PRNG：不动 math.random 的全局序列（游戏逻辑可能依赖它）
local _seed = (os.time() % 2147483647) + math.floor((os.clock() or 0) * 1000)

local function next_rand()
	_seed = (1103515245 * _seed + 12345) % 2147483648

	-- ⚠️ 不能把 _seed 直接拿去取模：LCG 的**低位**比特周期极短
	-- （bit0 周期 2、bit1 周期 4…），实测表现为「等级永远 30、威望永远 0」这种退化。
	-- 取高 15 位（bit16 以上）再取模，分布立刻正常。
	return math.floor(_seed / 65536) % 32768
end

local function rand_int(lo, hi)
	if hi <= lo then
		return lo
	end

	return lo + (next_rand() % (hi - lo + 1))
end

-- 读某维度的区间；存档值缺失/不合法时回落到默认，并 clamp 到硬边界、保证 lo <= hi
local function read_range(key)
	local b = BOUNDS[key]
	local lo = tonumber(mod:get("fake_" .. key .. "_min")) or b.def_min
	local hi = tonumber(mod:get("fake_" .. key .. "_max")) or b.def_max

	lo = math.floor(lo)
	hi = math.floor(hi)
	lo = math.max(b.min, math.min(b.max, lo))
	hi = math.max(b.min, math.min(b.max, hi))

	if hi < lo then
		hi = lo
	end

	return lo, hi
end

local function roll()
	local lvl_lo, lvl_hi = read_range("level")
	local tl_lo, tl_hi = read_range("true_level")
	local pre_lo, pre_hi = read_range("prestige")
	local hav_lo, hav_hi = read_range("havoc")

	local current = rand_int(lvl_lo, lvl_hi)
	local true_lvl = rand_int(tl_lo, tl_hi)

	-- 语义自洽：真等级要超过上限，那这个角色就**必须是满级**（额外等级只存在于满级之后）；
	-- 反过来，没超过上限就表示"没满级/没额外等级"，此时 true_level / additional_level 都不该有值
	-- （true_level 原生实现里这两个字段正是只在满级分支才赋值）。
	local has_extra = true_lvl > MAX_LEVEL

	if has_extra then
		current = MAX_LEVEL
	end

	return {
		current_level = current,
		true_level = has_extra and true_lvl or nil,
		additional_level = has_extra and (true_lvl - MAX_LEVEL) or nil,
		prestige = rand_int(pre_lo, pre_hi),
		havoc_rank = rand_int(hav_lo, hav_hi),
	}
end

-- account_id -> 一组假值（会话内稳定）
mod._fake_progress = {}

local function fake_for(key)
	local f = mod._fake_progress[key]

	if not f then
		f = roll()
		mod._fake_progress[key] = f
	end

	return f
end

local function fake_progress_count()
	local n = 0

	for _, _ in pairs(mod._fake_progress) do
		n = n + 1
	end

	return n
end

-- 假值清单（状态显示用）：account_id 前 8 位 = 等级/浩劫
local function values_text()
	local parts = {}

	for k, v in pairs(mod._fake_progress) do
		local label = type(k) == "string" and k:sub(1, 8) or tostring(k)

		parts[#parts + 1] = string.format("%s=%d/%d", label, v.current_level, v.havoc_rank)
	end

	return #parts > 0 and table.concat(parts, "  ") or "-"
end

-- 当前区间摘要（状态显示用）
local function ranges_text()
	local parts = {}

	for i = 1, #RANGE_KEYS do
		local key = RANGE_KEYS[i]
		local lo, hi = read_range(key)

		parts[#parts + 1] = string.format("%s %d-%d", key, lo, hi)
	end

	return table.concat(parts, ", ")
end

-- 重掷：**立即**给已有分组重新随机（而不是清空缓存等下次取用）。
-- 清空缓存的写法会导致「界面上已渲染的数字不变」，看起来像命令没生效 —— 那是 UI 文本缓存，
-- 得等界面自己重算；至少保证值本身已经换了。
mod.reroll_fake_progress = function ()
	for k in pairs(mod._fake_progress) do
		mod._fake_progress[k] = roll()
	end
end

-- 「我自己」那组缓存的 key：从 true_level 的 _self 反查 account_id（纯 Lua，零引擎调用）
local function my_cache_key()
	local tl = get_mod("true_level")

	if tl and type(tl._self) == "table" then
		for _, v in pairs(tl._self) do
			if type(v) == "table" and type(v.account_id) == "string" then
				return v.account_id
			end
		end
	end

	return "self"
end

-- 判断这条 true_levels 是不是「我自己」—— 纯 Lua，零引擎调用（见文件头的崩溃教训）
--   1) true_level 自己就把缓存分成 _self（自己）/ _others（他人），直接反查表引用最准
--   2) 反查不到（例如手工构造的表）：没有 account_id 视为自己，有则视为他人
local function is_mine(true_levels)
	local tl = get_mod("true_level")

	if tl then
		if type(tl._self) == "table" then
			for _, v in pairs(tl._self) do
				if v == true_levels then
					return true
				end
			end
		end

		if type(tl._others) == "table" then
			for _, v in pairs(tl._others) do
				if v == true_levels then
					return false
				end
			end
		end
	end

	return true_levels.account_id == nil
end

local function state_text(setting_id)
	return mod:get(setting_id) and mod:localize("fake_progress_state_on") or mod:localize("fake_progress_state_off")
end

-- 首次安装 / 升级后，设置项在 config 里可能还没有值（DMF 的 get 对未存储项返回 nil）。
-- 显式落成默认值：否则 nil 在 hook 里会被 `not x` 当成「关」，而且面板显示与实际行为不一致。
local function init_defaults()
	if mod:get("fake_progress_enable") == nil then
		mod:set("fake_progress_enable", true)
	end

	if mod:get("fake_progress_self_enable") == nil then
		mod:set("fake_progress_self_enable", true)
	end

	if mod:get("fake_progress_other_enable") == nil then
		mod:set("fake_progress_other_enable", true)
	end

	for key, b in pairs(BOUNDS) do
		if mod:get("fake_" .. key .. "_min") == nil then
			mod:set("fake_" .. key .. "_min", b.def_min)
		end

		if mod:get("fake_" .. key .. "_max") == nil then
			mod:set("fake_" .. key .. "_max", b.def_max)
		end
	end
end

-- 安装 hook；true_level 已经加载则立即成功，否则等 on_all_mods_loaded 兜底再试
mod.install_fake_progress = function ()
	init_defaults()

	local tl = get_mod("true_level")

	if not (tl and type(tl.replace_level) == "function") then
		return false
	end

	if mod._tl_fake_hooked then
		return true
	end

	mod:hook(tl, "replace_level", function (func, text, true_levels, reference, need_adding)
		-- 显式 false 才算「关」：nil（还没落盘/损坏的存档）按默认开处理
		if mod:get("fake_progress_enable") == false or type(true_levels) ~= "table" then
			return func(text, true_levels, reference, need_adding)
		end

		-- 自己 / 队友分别受各自开关控制
		local switch = is_mine(true_levels) and "fake_progress_self_enable" or "fake_progress_other_enable"

		if mod:get(switch) == false then
			return func(text, true_levels, reference, need_adding)
		end

		local f = fake_for(true_levels.account_id or "self")
		local masked = table.clone(true_levels)

		-- 等级三件套 + 威望 + 浩劫层数，全部替换。
		-- 注意 true_level / additional_level 可能是 nil —— 那表示"未满级、没有额外等级"，
		-- 这里显式赋值 nil 是**有意清除** clone 过来的真实值（与 true_level 的原生语义一致）。
		masked.current_level = f.current_level
		masked.true_level = f.true_level
		masked.additional_level = f.additional_level
		masked.prestige = f.prestige
		masked.havoc_rank = f.havoc_rank

		return func(text, masked, reference, need_adding)
	end)

	mod._tl_fake_hooked = true
	mod:info("[color_mark] fake progress: hooked true_level.replace_level")

	return true
end

-- 加载时先试一次（本机 true_level=load_order 10 < color_mark=32，通常会成功）
mod.install_fake_progress()

-- /cmfake [roll | on|off | self on|off | other on|off]
--   on|off       总开关（一键全关）
--   self on|off  只控制「我自己」的混淆
--   other on|off 只控制「队友」的混淆
--   roll         重新随机（改了区间后用它立即生效）；无参数则显示当前状态
mod:command("cmfake", mod:localize("command_cmfake_description"), function (...)
	local args = { ... }
	local a1 = string.lower(tostring(args[1] or ""))
	local a2 = string.lower(tostring(args[2] or ""))

	-- 改设置并回报（文本用 {} 占位符，见开发文档 4.9：本地化文本里不能留 %s/%d）
	local function set_switch(setting_id, scope_key, value)
		mod:set(setting_id, value)

		local text = mod:localize("fake_progress_set_scope")

		text = text:gsub("{scope}", mod:localize(scope_key))
		text = text:gsub("{state}", value and mod:localize("fake_progress_state_on") or mod:localize("fake_progress_state_off"))

		mod.send_chat(text)
	end

	if a1 == "on" or a1 == "off" then
		set_switch("fake_progress_enable", "fake_progress_scope_master", a1 == "on")

		return
	elseif a1 == "self" and (a2 == "on" or a2 == "off") then
		set_switch("fake_progress_self_enable", "fake_progress_scope_self", a2 == "on")

		return
	elseif a1 == "other" and (a2 == "on" or a2 == "off") then
		set_switch("fake_progress_other_enable", "fake_progress_scope_other", a2 == "on")

		return
	elseif a1 == "roll" then
		mod.reroll_fake_progress()

		local text = mod:localize("fake_progress_rolled")

		text = text:gsub("{values}", values_text())
		mod.send_chat(text)

		return
	end

	if not mod._tl_fake_hooked then
		mod.send_chat(mod:localize("fake_progress_no_true_level"))

		return
	end

	local f = fake_for(my_cache_key())
	local text = mod:localize("fake_progress_status")

	text = text:gsub("{master}", state_text("fake_progress_enable"))
	text = text:gsub("{self}", state_text("fake_progress_self_enable"))
	text = text:gsub("{other}", state_text("fake_progress_other_enable"))
	text = text:gsub("{ranges}", ranges_text())
	text = text:gsub("{groups}", tostring(fake_progress_count()))
	text = text:gsub("{values}", values_text())

	mod.send_chat(text)
end)
