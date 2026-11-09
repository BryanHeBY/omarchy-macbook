// Exercise installers in isolated HOME directories, including rollback and idempotency.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const repository = path.resolve(__dirname, '..');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'omarchy-install-'));

function run(home, script, args = [], extra = {}) {
  return spawnSync('bash', [path.join(repository, 'scripts', script), ...args], {
    env: { ...process.env, HOME: home, XDG_STATE_HOME: path.join(home, 'state'), ...extra },
    encoding: 'utf8',
  });
}
function personalConfig(home) {
  fs.mkdirSync(path.join(home, '.config/hypr/customizations'), { recursive: true });
  fs.writeFileSync(path.join(home, '.config/hypr/customizations/personal.lua'), '-- personal\n');
  fs.mkdirSync(path.join(home, '.config/fontconfig/conf.d'), { recursive: true });
  fs.writeFileSync(path.join(home, '.config/fontconfig/conf.d/50-omarchy-input-method.conf'), 'personal font\n');
}
function successful(result) { assert.equal(result.status, 0, result.stdout + result.stderr); }

try {
  const home = path.join(temporary, 'success');
  personalConfig(home);
  successful(run(home, 'install-links.sh'));
  assert(!fs.existsSync(path.join(home, 'state')), 'dry run writes no state');
  successful(run(home, 'install-links.sh', ['--apply']));
  const backupRoot = path.join(home, 'state/omarchy-configs/backups');
  const backups = fs.readdirSync(backupRoot).filter(name => name.startsWith('install.') && fs.statSync(path.join(backupRoot, name)).isDirectory());
  assert.equal(backups.length, 1);
  const saved = path.join(backupRoot, backups[0]);
  assert.equal(fs.readFileSync(path.join(saved, '.config/hypr/customizations/personal.lua'), 'utf8'), '-- personal\n');
  assert.equal(fs.readFileSync(path.join(saved, '.config/fontconfig/conf.d/50-omarchy-input-method.conf'), 'utf8'), 'personal font\n');
  assert.equal(fs.realpathSync(path.join(home, '.config/hypr/customizations')), path.join(repository, 'hyprland'));
  successful(run(home, 'install-links.sh', ['--apply']));
  assert.equal(fs.readdirSync(backupRoot).filter(name => name.startsWith('install.') && fs.statSync(path.join(backupRoot, name)).isDirectory()).length, 1);

  // Fail after the first replacement and ensure both originals are restored.
  const failingHome = path.join(temporary, 'failure');
  personalConfig(failingHome);
  const bin = path.join(temporary, 'bin');
  fs.mkdirSync(bin);
  fs.writeFileSync(path.join(bin, 'ln'), '#!/bin/bash\ncase "$*" in *fontconfig*) exit 54 ;; esac\nexec /usr/bin/ln "$@"\n', { mode: 0o755 });
  const failure = run(failingHome, 'install-links.sh', ['--apply'], { PATH: bin + path.delimiter + process.env.PATH });
  assert.notEqual(failure.status, 0);
  assert.equal(fs.readFileSync(path.join(failingHome, '.config/hypr/customizations/personal.lua'), 'utf8'), '-- personal\n');
  assert.equal(fs.readFileSync(path.join(failingHome, '.config/fontconfig/conf.d/50-omarchy-input-method.conf'), 'utf8'), 'personal font\n');

  // Patch against the matching installed Omarchy templates, never live config.
  fs.mkdirSync(path.join(home, '.config/fcitx5'), { recursive: true });
  for (const name of ['input.lua', 'bindings.lua', 'looknfeel.lua', 'monitors.lua']) {
    fs.copyFileSync('/usr/share/omarchy/config/hypr/' + name, path.join(home, '.config/hypr', name));
  }
  fs.copyFileSync('/usr/share/omarchy/config/fcitx5/config', path.join(home, '.config/fcitx5/config'));
  const originalInput = fs.readFileSync(path.join(home, '.config/hypr/input.lua'), 'utf8');
  successful(run(home, 'apply-patches.sh'));
  assert.equal(fs.readFileSync(path.join(home, '.config/hypr/input.lua'), 'utf8'), originalInput);
  successful(run(home, 'apply-patches.sh', ['--apply']));
  successful(run(home, 'apply-patches.sh', ['--apply']));
  successful(run(home, 'apply-patches.sh', ['--apply', '--only', 'display']));
  successful(run(home, 'apply-patches.sh', ['--apply', '--only', 'display']));
  assert.match(fs.readFileSync(path.join(home, '.config/hypr/monitors.lua'), 'utf8'), /require\("hypr.customizations.fractional-scaling"\)/);

  // A conflict in one target must prevent changes to every selected target.
  fs.writeFileSync(path.join(home, '.config/hypr/input.lua'), originalInput);
  fs.writeFileSync(path.join(home, '.config/hypr/looknfeel.lua'), '-- incompatible template\n');
  const conflict = run(home, 'apply-patches.sh', ['--apply', '--only', 'hyprland']);
  assert.notEqual(conflict.status, 0);
  assert.equal(fs.readFileSync(path.join(home, '.config/hypr/input.lua'), 'utf8'), originalInput);
  console.log('PASS install dry run, backups, rollback, idempotency and patch preflight');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
