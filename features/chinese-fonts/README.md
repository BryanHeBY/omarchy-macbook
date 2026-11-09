# Chinese font fallbacks

[简体中文](README.zh-CN.md)

Prefer Sarasa UI SC for Chinese interface text and Sarasa Mono SC for monospace
text, with Noto CJK fallbacks. Serif text falls back to Noto Serif CJK SC.

`fontconfig.conf` contains the Fontconfig aliases. Install the packages and link
the file from the repository root:

```bash
omarchy pkg add ttf-sarasa-gothic noto-fonts-cjk
bash installer/links.sh --apply --only fonts
fc-cache -f
fc-match 'sans-serif:charset=4e2d'
fc-match 'monospace:charset=4e2d'
fc-match 'serif:charset=4e2d'
```

The file is linked at
`~/.config/fontconfig/conf.d/50-omarchy-input-method.conf`. The queries check a
Chinese character and should select Sarasa UI SC, Sarasa Mono SC and Noto Serif
CJK SC respectively. Reopen applications that cache their selected fonts.
Remove this feature's link and refresh Fontconfig to restore prior fallback
selection, or restore the replaced entry from the link installer's backup.
