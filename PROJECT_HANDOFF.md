# color_mark · 项目交接摘要

> **给新会话的快速上手文档**：读完这个 + 通用规范（`暗潮\01-开发规范\Darktide-Mod开发规范.md`）即可接手。
> 最后更新：2026-08-27 13:00 | 当前版本：**v1.0.1**（已发 Release，2026-08-27；中文名误剥修复，待游戏内实测）

---

## 一、项目是什么

《战锤40K：暗潮》的彩色标记 mod（DMF Lua mod）。配合 **AnonPlayers**（匿名玩家 mod）使用：
用聊天命令把队伍成员标记成彩色，被标记玩家在所有显示位置（头顶/聊天/结算/组队界面）以指定颜色呈现，一眼认出固定队友。

- **位置**：`D:\DeepseekWorkspace\暗潮\04-Mods\color_mark\`
- **仓库**：https://github.com/CiJhuiDi/darktide-color-mark（✅ 已发 Release：v1.0.0 2026-08-19 / v1.0.1 2026-08-27）
- **状态**：实现完成，已发 Release v1.0.0/v1.0.1，**待游戏内实测反馈**

## 二、命令

| 命令 | 参数 | 行为 |
|---|---|---|
| `/squad` | 无 | 列出当前队伍成员：`1. 真名A  2. 真名B...`（排除自己） |
| `/mark <编号> <颜色>` | 编号=/squad 列表序号；颜色=预设名或 hex | 标记该玩家；重复标记=改颜色 |
| `/unmark <编号>` | 编号 | 取消标记 |
| `/marks` | 无 | 列出所有已标记 |

颜色：预设 10 色（red/orange/yellow/green/cyan/blue/purple/pink/white/gray）或 hex（如 ff8800，3/6 位）。

## 三、选人方案演进（重要，勿重蹈）

| 方案 | 结论 | 原因 |
|---|---|---|
| `/mark <steam名> <颜色>` | ❌ | 生僻字/特殊符号难输入；暴露隐私 |
| 准星指向选人 | ❌ | **活人会跑**，不可能一直拿准星指着目标 |
| 编号列表（/players 房间玩家） | ❌ | AnonPlayers 开着时全是匿名名，认不出人 |
| **队伍列表（/squad）** | ✅ 定稿 | 标记对象=熟人=当前队伍成员；真名可辨识 |

## 四、实现要点

### 队伍列表

```lua
Managers.data_service.social:fetch_party_members()  -- Promise → {unique_id → PlayerInfo}
-- PlayerInfo:account_id()（标记 key）
-- PlayerInfo:character_name()（真名，mod 内部拿数据不受 AnonPlayers UI 隐藏影响；_account_name 兜底）
```

- 任务中该接口自动用任务内玩家表（源码已处理）；单人时列表为空提示
- character_id→account_id 映射（供 profile_utils hook）在 `/squad` 时构建

### 标记表

`mod:persistent_table("marks")`：[account_id] = { color={r,g,b}, name=真名缓存, time }。跨会话，任意房间生效。

### 名字 hook（照 AnonPlayers，6 处）

| 对象 | 函数 | 说明 |
|---|---|---|
| RemotePlayer | name / character_name | 头顶/结算 |
| PlayerInfo | character_name / user_display_name | ⚠️ AnonPlayers 对 user_display_name 用 hook_origin，**本 mod 必须普通 hook** |
| PresenceEntryImmaterium | character_name | account_id 是 platform_user_id，Steam 下大概率相等，匹配不到放行 |
| profile_utils | character_name | 只有 profile，靠映射表反查 |

### 彩色渲染

`{#color(r,g,b)}名字{#reset()}` 富文本。聊天/结算 ✅；**头顶 nameplate 待实测**（Plan B：hook nameplate 改 text_color）。

### 显示模式（设置项）

`mark_display_mode`：`anon_color`（默认，匿名名+颜色，直播安全）/ `real_color`（真名+颜色，仅标记玩家生效，绕过 AnonPlayers）。

## 五、文件结构

```
color_mark/
├── color_mark.mod              # version = "1.0.1"、author = "CiJhuiDi"
├── 开发文档.md                 # 完整设计文档（选人演进/命令/风险清单）
└── scripts\mods\color_mark\
    ├── color_mark.lua          # 主逻辑（squad 列表/命令/hook）
    ├── color_mark_data.lua     # 设置项
    └── color_mark_localization.lua
```

## 六、待办

- [ ] 游戏内实测：`/squad` 列人、`/mark` 变色、`/unmark`、重启持久化、与 AnonPlayers 同开
- [ ] 头顶 nameplate 富文本验证（不行就 Plan B）
- [x] 打 zip + Release（v1.0.1，2026-08-27 已发：https://github.com/CiJhuiDi/darktide-color-mark/releases/tag/v1.0.1）

## 八、2026-08-22 修复：中文名被 strip_rich_text 误剥（用户反馈）

- **用户反馈**：colormark 不展示中文 ID 玩家的真名
- **根因**：`strip_rich_text` 私有区正则 `[\xEE\x80\x80-\xEE\xBF\xBF\xEF\x80\x80-\xEF\xA3\xBF]` 在 Lua 中按**字节**解析，`\x80\x80-\xEE` 被解析成字节范围 0x80-0xEE → 最终集合覆盖 0x80-0xEF = **所有 UTF-8 多字节字符全被剥**。中文名 → mark.name 变空串 → real_color 走 `_cached_name` 兜底显示面具名
- **修**：改精确 3 字节序列匹配 `\xEE[\x80-\xBF][\x80-\xBF]`（U+E000-EFFF）+ `\xEF[\x80-\xA3][\x80-\xBF]`（U+F000-F8FF，EF A4 起是 CJK 兼容表意不能剥）；`get_real_name` 返回前 strip 平台图标；/squad 自动升级逻辑放宽为「旧版 **或 name 为空/被误剥**」时补真名（老标记无需手动重标）
- **验证**：`99-临时文件/verify_strip_regex.py`（字节级模拟 Lua matchbracketclass，复现旧正则剥光中文）；luaparser 语法 OK；已备份游戏 mods\color_mark → color_mark.bak_20260822_145315 并同步 3 个 lua
- **待实测**：重启游戏后 /squad 中文名正常、/mark 中文名玩家、名牌/队伍面板显示中文真名；老标记 /squad 一次自动补名
- **后续**：已打 zip 并发布 v1.0.1（2026-08-27）；待游戏内实测

## 七、2026-08-20 修复：real_color 解除匿名失败

- **用户反馈**：标记玩家显示仍是匿名（???），real_color 模式没解除匿名
- **根因分析**：
  1. `_cached_name` / `Steam.user_name(peer_id)` 依赖 RemotePlayer origin 实现，不可靠（反编译字符串池确认 origin 有这段，但实际拿不到真名）
  2. `/squad` 缓存的 mark.name 也被 AnonPlayers 匿名化（character_name 走 hook 链）→ 真名缓存本身就是面具名
  3. hook 链顺序无问题：AnonPlayers 31 → color_mark 32，color_mark wrapper 链首截断标记玩家 ✓（DMF get_hook_chain 返回最新注册）
  4. AnonPlayers 默认 anon_others=0（不匿名），用户手动开启后才会触发此问题
- **修**：
  - `get_player_name`：检测 `get_mod("AnonPlayers")` 的 `anon_others` 设置，匿名模式时直读 `player_info._account_name`（平台账号名，不走 hook 链，AnonPlayers 匿名不了）
  - real_color 真名来源改为：`mark.name`（标记时缓存的真名）→ `_cached_name` → Steam（PlayerInfo 版本：mark.name → _account_name）
- **同步**：已备份游戏 mods\color_mark → `color_mark.bak_20260820_111842`，覆盖同步 3 个 lua 到游戏
- **待实测**：/squad 列表是否显示真名（匿名模式下列平台名）、real_color 头顶/聊天是否显示真名+颜色
- **v1.0.1 已发布**（2026-08-27）：release\color_mark_1.0.1.zip（重打，含 08-22 修复）+ release_notes_1.0.1.md；GitHub Release v1.0.1 已发（2026-08-27）；color_mark.mod version → 1.0.1；开发文档.md 已加 4.5 节 real_color 直播安全风险说明
