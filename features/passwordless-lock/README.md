# Passwordless lock dismissal

Dismiss the lock screen with a click or any key. Anyone with physical access can
enter the session when this feature is enabled. It is an explicit installation
option.

| File | Responsibility |
| --- | --- |
| `plugin/manifest.json` | Plugin ID, entry points and replacement of `omarchy.lock` |
| `plugin/LockView.qml` | Lock interface and dismissal hint |
| `plugin/Service.qml` | Lock lifecycle, background and dismissal handling |
| `plugin/FingerprintModel.js` | Retained upstream fingerprint state and recovery |
| `plugin/poster.sh` | Cached thumbnail for video backgrounds |
| `plugin/i18n/en.json` | English `dismissHint` translation |
| `plugin/i18n/zh-CN.json` | Simplified Chinese `dismissHint` translation |

The plugin ID is `passwordless-lock`, with `clonedFrom` pointing to `omarchy.lock`.
`LockView.qml` reads the flat translation catalogs through Omarchy's translation
component. The background poster helper requires ffmpegthumbnailer and flock.

```bash
python3 install.py --apply --with-passwordless-lock
omarchy system lock
```

Check dismissal by a click or key. Enable `omarchy.lock` and restart the shell to
restore the built-in lock behavior. Thumbnail caches use the user cache
directory. The complete plugin payload derives from Omarchy 4.5 and retains the
[upstream MIT notice](../../LICENSES/Omarchy-MIT.txt).
