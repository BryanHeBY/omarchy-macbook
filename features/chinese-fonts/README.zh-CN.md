# 中文字体回退

[English](README.md)

中文界面文字优先使用 Sarasa UI SC，等宽文字优先使用 Sarasa Mono SC，并以 Noto CJK 作为回退字体。衬线文字回退到 Noto Serif CJK SC。

`fontconfig.conf` 定义 Fontconfig 字体别名。在仓库根目录安装字体包并部署链接。

```bash
omarchy pkg add ttf-sarasa-gothic noto-fonts-cjk
bash installer/links.sh --apply --only fonts
fc-cache -f
fc-match 'sans-serif:charset=4e2d'
fc-match 'monospace:charset=4e2d'
fc-match 'serif:charset=4e2d'
```

配置链接位于 `~/.config/fontconfig/conf.d/50-omarchy-input-method.conf`。以上命令查询一个汉字的字体匹配结果，应依次选中 Sarasa UI SC、Sarasa Mono SC 和 Noto Serif CJK SC。缓存字体选择的应用需要重新打开。

移除该功能的链接并刷新 Fontconfig，即可恢复此前的字体回退选择。也可以从链接安装器的备份中还原被替换的配置项。
