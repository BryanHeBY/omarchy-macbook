# 安装预设

[English](README.md)

`recommended.json` 是推荐生效默认值的来源。`input_method` 选择 `caps-fn` 或 `shift`，`features` 将每个受支持的功能目录名映射到 JSON 布尔值。根目录安装器在执行任何命令前验证完整功能集合。

命令行参数覆盖对应的推荐选择。各功能工具支持安装后的定向配置。输入法方案选择完整键盘行为，其中 Shift 方案恢复原来的左 Shift 主触发键。

这些选项定义安装和生效工作，已有的其他功能用户配置予以保留。每次完整运行都会应用所选输入法方案和双指状态。停用及恢复行为见 [安装说明](../docs/installation.zh-CN.md)。
