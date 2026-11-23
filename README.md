# 彩色标记 (Color Mark) v1.0.5

《战锤 40K：暗潮》DMF mod：用聊天命令把固定队友标记成彩色，被标记玩家的名字在所有显示位置（头顶名牌 / 聊天 / 结算 / 组队界面）以指定颜色呈现，一眼认出熟人。

配合 **AnonPlayers**（匿名玩家 mod）使用效果最佳：未标记玩家保持匿名，只有你标记过的熟人显示颜色。

## 功能

- 聊天命令标记队友，无需 UI，标记对象 = 当前队伍成员
- 10 种预设颜色 + 任意 RGB 十六进制（如 `ff8800`）
- 标记按**账号**持久化：跨会话保存，任意房间/任务生效
- **给自己换个显示名**：自定义别名 + 颜色替换自己的名字（左下角 HUD / 聊天 / 结算 / 组队面板 / 大厅）。
  **仅本机可见** —— 队友看到的仍是你原本的名字
- **混淆进度显示**：把 true_level 模组显示的**等级 / 威望 / 浩劫层数**换成随机假值 ——
  每次进游戏重新随机一次，每个账号一组、会话内保持不变（**自己和队友都被盖住**）。**仅本机显示**（需装 true_level）
- 两种显示模式：
  - `anon_color`（默认）：匿名名 + 颜色 —— 直播安全，靠颜色认人
  - `real_color`：真名 + 颜色 —— 仅标记玩家生效，绕过匿名

## 依赖

- **DMF**（Darktide Mod Framework）—— 硬依赖
- 可选但推荐：**AnonPlayers**（不装也能用，但"匿名 + 彩色标记"的组合需要它）
- 可选：**true_level**（等级 / 威望 / 浩劫层数由它显示；「混淆进度显示」混淆的就是它显示的内容，不装则该项无效）

**加载顺序**：建议 `color_mark` 排在 **AnonPlayers 与 true_level 之后** —— DMF 的 hook 链是「后注册 = 外层」，
排在后面本 mod 才能在最外层截断 / 改写它们的输出。顺序反了也不会坏：

- true_level 的 hook 失败时会在 `on_all_mods_loaded` 兜底补装（那时注册 = 仍是最外层）
- AnonPlayers 顺序反了会表现为"解除不了匿名"（mod 会在启动时提示）

> `info.json` 里的 `self_after` 只是**声明性元数据** —— 当前**没有程序读它**（DMF 读 `info.json`，但只取
> metadata / `localization` 字段；DMM 读的是 `.mod` 的 `packages`）。真正决定顺序的是
> 游戏根目录的 `mod_load_order.txt`。

## 安装

1. 把 `color_mark` 文件夹整个复制到游戏 mods 目录：
   `Steam\steamapps\common\Warhammer 40,000 DARKTIDE\mods\`
2. 打开游戏根目录 `mod_load_order.txt`，添加一行 `color_mark`（**放在 `AnonPlayers` 与 `true_level` 之后**）
   - ⚠️ **若同时使用 AnonPlayers：`color_mark` 必须排在 `AnonPlayers` 之后**（越靠后加载 = hook 越外层）。顺序反了 AnonPlayers 会把本 mod 的彩色名再匿名一遍，表现为"解除不了匿名"（mod 会在启动时提示）
   - 若使用 true_level：同理排在它之后最稳（顺序反了也会在 `on_all_mods_loaded` 兜底补装，功能不受影响）
3. 启动游戏 → ESC → **Mod Options → 彩色标记** 查看/调整设置

## 使用

| 命令 | 参数 | 说明 |
|---|---|---|
| `/squad` | 无 | 列出当前队伍成员真名（排除自己），得到编号 |
| `/mark <编号> <颜色>` | 编号 = `/squad` 列表序号；颜色 = 预设名或 hex | 标记该玩家；对同一玩家重复标记 = 改颜色 |
| `/unmark <编号>` | 编号 | 取消标记 |
| `/marks` | 无 | 列出所有已标记玩家 |
| `/markdebug on\|off` | 无 | 临时开关调试探针日志（排查名字/匿名问题用；仅本次会话，不写配置） |
| `/cmfake [roll\|on\|off\|self on\|off\|other on\|off]` | 无 | 混淆进度：查看状态 / 重新随机 / 总开关 / 分别开关「我自己」「队友」（默认全开） |

**颜色**：预设 `red` `orange` `yellow` `green` `cyan` `blue` `purple` `pink` `white` `gray`，或 hex（如 `/mark 2 ff8800`，3 位/6 位均可）。

**边界提示**：未先运行 `/squad` 或编号越界 → 提示无效编号；颜色无法解析 → 提示无效颜色；队伍无其他玩家 → 提示队伍为空。

> **`/cmfake roll` 与界面刷新**：roll 会**立即**换掉假值（聊天栏里的 `/cmfake` 输出就是新值），
> 但**界面上已经画出来的旧数字**要等那个面板重建才会变 —— 开合一次社交 / 队伍面板、或进出大厅即可。
> 那是 UI 的文本缓存，不是命令没生效。

## 配置项

| 设置 | 默认 | 说明 |
|---|---|---|
| 显示模式 `mark_display_mode` | `anon_color` | `anon_color`：匿名名 + 颜色（直播安全）<br>`real_color`：真名 + 颜色（仅标记玩家，绕过 AnonPlayers） |
| 用自定义名字显示自己 `self_alias_enable` | 关 | 开启后用自己的别名替换真名显示 |
| 我的显示名 `self_alias` | 空 | 别名文本（最长 24 字）；留空则仍旧显示真名 |
| 我的显示名颜色 `self_alias_color` | 蓝 | 别名的颜色（设置面板里点色板选） |
| 混淆进度 · 总开关 `fake_progress_enable` | **开** | 关掉 = 自己和队友都不混淆 |
| 混淆进度 · 我自己 `fake_progress_self_enable` | **开** | 把显示给你自己的等级/威望/浩劫层数换成随机假值 |
| 混淆进度 · 队友 `fake_progress_other_enable` | **开** | 把显示给其他玩家的等级/威望/浩劫层数换成随机假值（每人一组） |
| 假值区间（等级/真等级/威望/浩劫） | 25-30 / 100-300 / 0-3 / 30-40 | 六项最低/最高可调。**「真等级」是 true_level 满级后累加的等级，可远超 30**（区间上限 9999）；改完 `/cmfake roll` 立即生效 |

**等级显示成什么样，取决于 true_level 自己的 `display_style` 设置**：

| display_style | 等级栏显示 |
|---|---|
| `separate` | `28 (+170)` —— 超过 30 的部分在括号里（本 mod 会按真等级假值算好这个差值） |
| `total` | 直接显示真等级假值（如 `198`）—— 想让等级栏直接是大数字就选这个 |
| `default` | 只显示 1-30 的角色等级，没有超过 30 的部分 |
| 调试日志 `debug_log` | 关 | 开启后每次名字查询写一行 `[cm]` 日志（≈95 行/秒，30 分钟约 29 MB）。**只在排查匿名/名字问题时打开**；临时开启可用 `/markdebug on` |

## 已知限制与注意

- **直播安全**：`real_color` 显示的是账号名（Steam 昵称），可能被他人改成违规词 → 有炸直播风险。**直播时请用默认的 `anon_color`**（显示 `???` + 颜色，靠颜色认人，完全安全）
- **任务中（combat）头顶名字**仍会被匿名掩盖；大厅名牌、聊天、结算、组队界面/哀星号队伍面板均正常
- `/squad` 依赖队伍成员数据：单人 / 队伍为空时列表为空并提示
- **混淆进度是纯本机显示层**：改的只是你屏幕上看到的数字，队友客户端与服务器数据不变（匹配、层数判定都不受影响）；没装 true_level 时本项无效
- bot 无账号 ID，不可标记；自己默认不可标记

## 文件结构

```
color_mark/
├── color_mark.mod                          # 入口清单（version / author）
└── scripts/mods/color_mark/
    ├── color_mark.lua                      # 主逻辑（/squad 列表、命令、名字 hook、颜色渲染）
    ├── color_mark_fake_progress.lua        # 混淆进度显示（hook true_level.replace_level 的等级/威望/浩劫层数）
    ├── color_mark_data.lua                 # 设置项定义
    └── color_mark_localization.lua         # 中英本地化
```

## 更新日志

- **v1.0.5**（2026-10-10）：新增「混淆进度显示」—— 把 true_level 显示的等级 / 威望 / 浩劫层数
  换成随机假值（每次进游戏随机一次，每个账号一组、会话内稳定；纯本机显示，队友与服务器不受影响）。
  **自己 / 队友分别可开关**（总开关 `fake_progress_enable` + `fake_progress_self_enable` + `fake_progress_other_enable`），
  命令 `/cmfake [roll|on|off|self on|off|other on|off]`
- **v1.0.4**（2026-10-10）：调试探针日志改为**默认关闭** —— 7 处 `[cm][...]` 日志原在名字查询热路径上
  （实测 ≈95 行/秒，30 分钟约 29 MB，占整份游戏日志 97.8%）。现在用 `/markdebug on|off`（临时）
  或 Mod Options → 彩色标记 → 调试日志（持久）按需开启，显示行为完全不变
- **v1.0.3**（2026-09-20）：新增「自己的显示名」—— 自定义别名 + 颜色替换自己的名字显示
  （HUD / 聊天 / 结算 / 组队面板 / 大厅，仅本机可见）
- **v1.0.2**（2026-09-11）：修复「被标记玩家解除不了匿名」—— 根因是加载顺序，新增顺序自检与提示
- **v1.0.1**（2026-08-27）：修复中文名被剥离问题（私有区字符按完整 UTF-8 字节序列匹配）；平台图标字符清洗；哀星号左下角队伍面板补充真名替换逻辑
- **v1.0.0**（2026-08-19）：首个发布版

## 发布包

- https://github.com/CiJhuiDi/darktide-color-mark/releases（下载 `color_mark_x.y.z.zip`，解压后为 `color_mark/` 目录，可直接放入 mods）

## 许可 / License

MIT License —— 详见 [LICENSE](LICENSE)。
