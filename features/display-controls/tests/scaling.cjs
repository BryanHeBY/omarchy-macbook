// Cover exact fractional presets and per-output persistence without a live compositor.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const model = require('../plugin/Model.js');

const plugin = path.resolve(__dirname, '../plugin');
const panel = fs.readFileSync(path.join(plugin, 'Panel.qml'), 'utf8');
const presets = JSON.parse(panel.match(/scalePresets: (\[[^\n]+\])/)[1]);
assert.deepEqual(presets, ['1', '1.25', '1.6', '1.8', '1.9', '2', '3']);
assert.deepEqual(model.availableScales(presets, 2560, 1600), presets);
assert.equal(model.cleanScale('1.8', 2560, 1600), '1.8');
assert.equal(model.cleanScale('1.9', 2560, 1600), '1.9');
assert.equal(model.matchingScaleIndex(presets, 1.79999995, 2560, 1600), 3);
assert.equal(model.matchingScaleIndex(presets, 1.89999995, 2560, 1600), 4);
assert.equal(model.matchingScaleIndex(presets, 2, 2560, 1600), 5);

const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'display-controls-'));
try {
  const bin = path.join(temporary, 'bin');
  const config = path.join(temporary, '.config/hypr');
  fs.mkdirSync(bin);
  fs.mkdirSync(config, { recursive: true });
  const monitors = path.join(config, 'monitors.lua');
  fs.writeFileSync(monitors, [
    '-- Keep this personal setting.',
    'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })',
    'hl.monitor({ output = "TEST-1", mode = "preferred", position = "auto", scale = 2 })',
    'hl.monitor({ output = "TEST-2", mode = "preferred", position = "auto", scale = 1 })',
    'local omarchy_gdk_scale = 2',
    '',
  ].join('\n'));
  fs.writeFileSync(path.join(bin, 'hyprctl'), `#!/usr/bin/env node
const fs = require('node:fs');
const args = process.argv.slice(2);
if (args.includes('getoption')) {
  console.log(JSON.stringify({bool: process.env.SCALE_CHECKS_DISABLED === '1'}));
} else if (args.includes('monitors')) {
  console.log(JSON.stringify([
    {name:'TEST-1',focused:true,scale:2,width:2560,height:1600,refreshRate:60},
    {name:'TEST-2',focused:false,scale:1,width:1920,height:1080,refreshRate:60}
  ]));
} else if (args[0] === 'eval') {
  if (process.env.FAIL_MONITOR_UPDATE === '1') process.exit(1);
  fs.writeFileSync(process.env.EVAL_LOG, args[1]);
} else process.exit(2);
`, { mode: 0o755 });
  const env = {
    ...process.env,
    HOME: temporary,
    XDG_STATE_HOME: path.join(temporary, 'state'),
    PATH: bin + path.delimiter + process.env.PATH,
    SCALE_CHECKS_DISABLED: '1',
    EVAL_LOG: path.join(temporary, 'eval.log'),
  };
  const run = (overrides, scale = '1.8') => spawnSync('bash', [path.join(plugin, 'set-scale.sh'), scale], {
    env: { ...env, ...overrides }, encoding: 'utf8',
  });
  let result = run({});
  assert.equal(result.status, 0, result.stderr);
  assert.match(fs.readFileSync(env.EVAL_LOG, 'utf8'), /scale = 1\.8/);
  let persisted = fs.readFileSync(monitors, 'utf8');
  assert.match(persisted, /output = "TEST-1".*scale = 1\.8/);
  assert.match(persisted, /output = "TEST-2".*scale = 1/);
  assert.match(persisted, /Keep this personal setting/);
  assert.match(persisted, /local omarchy_gdk_scale = 1/);
  result = run({}, '1.9');
  assert.equal(result.status, 0, result.stderr);
  assert.match(fs.readFileSync(env.EVAL_LOG, 'utf8'), /scale = 1\.9/);
  persisted = fs.readFileSync(monitors, 'utf8');
  assert.match(persisted, /output = "TEST-1".*scale = 1\.9/);
  result = run({}, 'down');
  assert.equal(result.status, 0, result.stderr);
  assert.match(fs.readFileSync(env.EVAL_LOG, 'utf8'), /scale = 1\.9/);
  result = run({ SCALE_CHECKS_DISABLED: '0' });
  assert.notEqual(result.status, 0);
  assert.equal(fs.readFileSync(monitors, 'utf8'), persisted);
  result = run({ FAIL_MONITOR_UPDATE: '1' });
  assert.notEqual(result.status, 0);
  assert.equal(fs.readFileSync(monitors, 'utf8'), persisted);
  console.log('PASS display presets, exact 1.8/1.9 scaling, stepping, persistence and failure guards');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
