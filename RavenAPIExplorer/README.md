# RavenCraft API Explorer（1.14.2）

面向 RavenCraft Classic Era 1.14.2 的游戏内 Lua API 浏览器。纯 AddOn，不注入 DLL，不修改游戏文件。

## 安装

将 `RavenAPIExplorer/` 复制到游戏的 `Interface/AddOns/`，确保文件结构是：

```
Interface/AddOns/RavenAPIExplorer/
  RavenAPIExplorer.toc
  Core.lua
  UI.lua
```

插件选择界面勾选 RavenCraft API Explorer。进入游戏后使用 `/ravenapi` 或 `/ra` 开关面板。

## 功能

- 动态枚举当前进程暴露的全局函数及直接位于 `C_*` 命名空间的函数；不会假装预装 6254 个 API。
- 英文名、中文关键字查找；左侧列表滚轮滚动；右侧显示分类、中文提示与说明。
- 已人工审阅的安全读取 API 可手动输入一项参数执行；输出与错误显示在面板。
- 其他函数仅浏览，**禁止直接执行**。没有通用 `loadstring` 执行器。
- 保留最近 100 条执行记录；手动点击「保存导出快照」后 `/reload` 或正常退出，使 `WTF/Account/<账号>/SavedVariables/RavenAPIExplorer.lua` 落盘。

## 中文说明的准确性

所有函数均有中文索引提示，但 **不是 6254 条已认证的中文文档**：明确人工编写的条目会显示“有人工说明”，其余函数采用标识符切词提示，并标记“待核实”。未知 API 不会伪造签名或执行效果。导出总数取决于实际游戏环境和加载的其他插件。

## 安全与兼容限制

- `pcall` 只捕获 Lua 错误，不能保证原生函数没有副作用，因此测试功能严格白名单。
- 扫描列表包括 Blizzard UI 和其他已加载插件的全局函数，不等于全部来自客户端原生引擎。
- 本项目面向 `Interface: 11402`。其他构建的接口与模板兼容性未验证。
- 游戏内手工测试尚未完成；目前仅完成源代码提交与静态审查。

## 首次测试

1. 在选择角色界面确认插件已启用；进入游戏输入 `/ra`。
2. 搜索 `UnitHealth`，点击条目，参数保留 `target`，点击「只读测试」。
3. 搜索 `GetSpellInfo`，输入 `116`，检查是否显示 Frostbolt。
4. 搜索 `ClosestUnitPosition`，应该能浏览，但测试按钮不可用。
5. 点击「保存导出快照」并 `/reload`，检查 SavedVariables 中的 `export` 与 `history`。

## 下一步

- 从游戏内 API 文档提取准确的函数参数和返回值（不对未知字段猜测）。
- 完善逐条中文释义和分类（保持“已验证/待核实”的区分）。
- 根据游戏实测修复 1.14.2 特有的 UI 或运行时差异。
