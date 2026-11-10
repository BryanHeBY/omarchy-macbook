# 仓库架构

[English](architecture.md)

Omarchy MacBook 按功能组织桌面行为。每个 feature 维护理解、配置和测试该行为所需的文件。

## 功能归属

`features/` 下的每个目录均提供英文 `README.md` 和简体中文 `README.zh-CN.md`，说明用途、文件职责、依赖、生效、验证与恢复方法。简单功能可以只有一个配置文件。原生代码位于 `native/`，Shell 插件将完整运行文件放在 `plugin/`。

`configure.py`、`build.sh` 和 `configure.cjs` 等组件工具与功能放在一起，专属回归测试位于该功能的 `tests/`。严格 JSON 格式的清单和翻译文件由功能 README 解释，源码注释使用对应文件格式的原生注释语法。

完整 QML 文件、相邻脚本和翻译文件一起移动，以保持 Qt 相对 URL 解析有效。上游版权元数据予以保留，许可声明位于 `LICENSES/`。

## 安装策略与接入

`profiles/recommended.json` 定义推荐功能选择和输入法方案。`install.py` 负责验证预设、应用显式命令行覆盖，并编排依赖安装、配置和生效步骤。

`installer/` 维护共享部署机制。`symlinks.tsv` 记录分组、仓库相对源路径和 HOME 相对目标路径。`links.sh` 备份并部署单个配置文件和完整插件目录，`patches.sh` 在预检查后应用指定范围的接入补丁，并支持失败回滚。Hyprland 加载补丁位于 `installer/patches/`，功能专属的 Fcitx5 补丁与键盘功能放在一起。

`installer/build-native.sh` 和 `installer/native_plugin.py` 提供共享的原生编译、显式启停、串行化和动态库／标记恢复。窗口焦点手势与触摸板惯性保留各自的功能入口。

工作区导航和窗口焦点手势使用独立加载器。可选焦点功能在加载原生代码前检查显式启用标记。

## 运行时布局

源码路径映射到安装路径。Lua 模块逐个链接到 `~/.config/hypr/customizations/`，Omarchy 插件以完整目录链接到 `~/.config/omarchy/plugins/`。这些安装别名使用户配置能够独立于仓库目录组织加载模块。

keyd 系统配置由键盘工具安装为 root 持有的副本。运行记录、选择标记、缓存、备份和原生动态库使用用户的 XDG 配置、状态、缓存和数据目录，存放在受版本控制的源码树之外。

链接安装器可以将此前由本仓库管理的 Hyprland 目录链接转换为独立文件链接。它备份父目录链接、复制剩余本地文件，失败时恢复父目录链接。并发新增的内容保留在失败安装的备份目录中。

## 文档与测试

根目录的中英文 README 介绍项目、列出功能并链接到操作说明。[安装说明](installation.zh-CN.md) 介绍生效与恢复，功能 README 提供组件细节，[示例目录](examples/README.zh-CN.md) 提供参考配置。

对应的中英文页面在顶部提供语言互切链接。中文页面优先链接已有中文版本，代码、配置、许可和没有中文版的外部资料链接到原始目标。

`tests/installation/` 覆盖跨功能编排、软链接迁移、补丁应用、备份和失败恢复。组件测试通过各功能自己的入口验证行为。在仓库根目录运行 [主 README](../README.zh-CN.md) 中列出的命令。
