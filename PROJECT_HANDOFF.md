# color_mark · 项目交接摘要

> **给新会话的快速上手文档**：读完这个 + 通用规范（`暗潮\01-开发规范\Darktide-Mod开发规范.md`）即可接手。
> 最后更新：2026-08-19 14:15 | 当前版本：v1.0.0（✅ 已发 Release，待实测反馈）

---

## 一、项目是什么

《战锤40K：暗潮》的彩色标记 mod（DMF Lua mod）。配合 **AnonPlayers**（匿名玩家 mod）使用：
用聊天命令把队伍成员标记成彩色，被标记玩家在所有显示位置（头顶/聊天/结算/组队界面）以指定颜色呈现，一眼认出固定队友。

- **位置**：`D:\DeepseekWorkspace\暗潮\04-Mods\color_mark\`
- **仓库**：https://github.com/CiJhuiDi/darktide-color-mark（✅ 已发 Release v1.0.0，2026-08-19）
- **状态**：实现完成，已发 Release，**待游戏内实测反馈**

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
├── color_mark.mod              # version = "1.0.0"、author = "CiJhuiDi"
├── 开发文档.md                 # 完整设计文档（选人演进/命令/风险清单）
└── scripts\mods\color_mark\
    ├── color_mark.lua          # 主逻辑（squad 列表/命令/hook）
    ├── color_mark_data.lua     # 设置项
    └── color_mark_localization.lua
```

## 六、待办

- [ ] 游戏内实测：`/squad` 列人、`/mark` 变色、`/unmark`、重启持久化、与 AnonPlayers 同开
- [ ] 头顶 nameplate 富文本验证（不行就 Plan B）
- [ ] 实测通过 → 打 zip + Release
