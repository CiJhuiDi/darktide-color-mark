# 彩色标记 (Color Mark) v1.0.1

《战锤 40K：暗潮》DMF mod：用聊天命令把固定队友标记成彩色，被标记玩家的名字在所有显示位置（头顶名牌 / 聊天 / 结算 / 组队界面）以指定颜色呈现，一眼认出熟人。

配合 **AnonPlayers**（匿名玩家 mod）使用效果最佳：未标记玩家保持匿名，只有你标记过的熟人显示颜色。

## 功能

- 聊天命令标记队友，无需 UI，标记对象 = 当前队伍成员
- 10 种预设颜色 + 任意 RGB 十六进制（如 `ff8800`）
- 标记按**账号**持久化：跨会话保存，任意房间/任务生效
- 两种显示模式：
  - `anon_color`（默认）：匿名名 + 颜色 —— 直播安全，靠颜色认人
  - `real_color`：真名 + 颜色 —— 仅标记玩家生效，绕过匿名

## 依赖

- **DMF**（Darktide Mod Framework）
- 可选但推荐：**AnonPlayers**（不装也能用，但"匿名 + 彩色标记"的组合需要它）
- 加载顺序：无硬性要求，建议本 mod 排在 AnonPlayers **之后**

## 安装

1. 把 `color_mark` 文件夹整个复制到游戏 mods 目录：
   `Steam\steamapps\common\Warhammer 40,000 DARKTIDE\mods\`
2. 打开游戏根目录 `mod_load_order.txt`，添加一行 `color_mark`
3. 启动游戏 → ESC → **Mod Options → 彩色标记** 查看/调整设置

## 使用

| 命令 | 参数 | 说明 |
|---|---|---|
| `/squad` | 无 | 列出当前队伍成员真名（排除自己），得到编号 |
| `/mark <编号> <颜色>` | 编号 = `/squad` 列表序号；颜色 = 预设名或 hex | 标记该玩家；对同一玩家重复标记 = 改颜色 |
| `/unmark <编号>` | 编号 | 取消标记 |
| `/marks` | 无 | 列出所有已标记玩家 |

**颜色**：预设 `red` `orange` `yellow` `green` `cyan` `blue` `purple` `pink` `white` `gray`，或 hex（如 `/mark 2 ff8800`，3 位/6 位均可）。

**边界提示**：未先运行 `/squad` 或编号越界 → 提示无效编号；颜色无法解析 → 提示无效颜色；队伍无其他玩家 → 提示队伍为空。

## 配置项

| 设置 | 默认 | 说明 |
|---|---|---|
| 显示模式 `mark_display_mode` | `anon_color` | `anon_color`：匿名名 + 颜色（直播安全）<br>`real_color`：真名 + 颜色（仅标记玩家，绕过 AnonPlayers） |

## 已知限制与注意

- **直播安全**：`real_color` 显示的是账号名（Steam 昵称），可能被他人改成违规词 → 有炸直播风险。**直播时请用默认的 `anon_color`**（显示 `???` + 颜色，靠颜色认人，完全安全）
- **任务中（combat）头顶名字**仍会被匿名掩盖；大厅名牌、聊天、结算、组队界面/哀星号队伍面板均正常
- `/squad` 依赖队伍成员数据：单人 / 队伍为空时列表为空并提示
- bot 无账号 ID，不可标记；自己默认不可标记

## 文件结构

```
color_mark/
├── color_mark.mod                          # 入口清单（version / author）
└── scripts/mods/color_mark/
    ├── color_mark.lua                      # 主逻辑（/squad 列表、命令、名字 hook、颜色渲染）
    ├── color_mark_data.lua                 # 设置项定义
    └── color_mark_localization.lua         # 中英本地化
```

## 更新日志

- **v1.0.1**（2026-08-27）：修复中文名被剥离问题（私有区字符按完整 UTF-8 字节序列匹配）；平台图标字符清洗；哀星号左下角队伍面板补充真名替换逻辑
- **v1.0.0**（2026-08-19）：首个发布版

## 发布包

- https://github.com/CiJhuiDi/darktide-color-mark/releases（下载 `color_mark_x.y.z.zip`，解压后为 `color_mark/` 目录，可直接放入 mods）
