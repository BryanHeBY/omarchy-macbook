// Exercise the standalone helper against isolated settings, never the live profile.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const script = path.resolve(__dirname, '../scripts/configure-vscode-scroll.cjs');
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'omarchy-vscode-scroll-'));
const home = path.join(temporary, 'home');
const state = path.join(home, 'state');
const config = path.join(home, 'config');
const target = path.join(config, 'Code/User/settings.json');

function run(args = []) {
  return spawnSync(process.execPath, [script, ...args], {
    env: { ...process.env, HOME: home, XDG_CONFIG_HOME: config, XDG_STATE_HOME: state },
    encoding: 'utf8',
  });
}
function ok(result) { assert.equal(result.status, 0, result.stdout + result.stderr); }
function backups() {
  const root = path.join(state, 'omarchy-configs/vscode-scroll-backups');
  return fs.existsSync(root) ? fs.readdirSync(root).map(name => path.join(root, name, 'settings.json')) : [];
}
function fixture(name, source) {
  const file = path.join(temporary, name + '.json');
  fs.writeFileSync(file, source, { mode: 0o640 });
  return file;
}

try {
  ok(run());
  assert(!fs.existsSync(home), 'preview must not create directories');
  ok(run(['--help']));
  assert(!fs.existsSync(home));
  ok(run(['--apply']));
  assert.equal(JSON.parse(fs.readFileSync(target, 'utf8'))['editor.inertialScroll'], true);
  assert.equal(fs.statSync(target).mode & 0o777, 0o600);
  assert.equal(backups().length, 0, 'new files need no backup');

  const source = '\uFEFF{\r\n\t// A personal preference\r\n\t"editor.smoothScrolling": false,\r\n' +
    '\t"url": "https://example.test/a,}//",\r\n' +
    '\t"escaped": "\\\"/*text*/",\r\n' +
    '\t"nested": { "editor.inertialScroll": false, "list": [1, 2,], },\r\n' +
    '\t/* Keep this block */ "editor.inertialScroll" /* key */ : /* value */ false,\r\n}\r\n';
  fs.writeFileSync(target, source);
  fs.chmodSync(target, 0o640);
  ok(run());
  assert.equal(fs.readFileSync(target, 'utf8'), source);
  assert.equal(backups().length, 0);
  ok(run(['--apply']));
  const expected = source.replace('/* value */ false', '/* value */ true');
  assert.equal(fs.readFileSync(target, 'utf8'), expected);
  assert.equal(fs.statSync(target).mode & 0o777, 0o640);
  assert.equal(backups().length, 1);
  assert.equal(fs.readFileSync(backups()[0], 'utf8'), source);
  assert.equal(fs.statSync(backups()[0]).mode & 0o777, 0o600);
  assert.equal(fs.statSync(path.dirname(backups()[0])).mode & 0o777, 0o700);
  ok(run(['--apply']));
  assert.equal(backups().length, 1, 'matching values must not create extra backups');
  ok(run(['--apply', '--disable']));
  assert.equal(fs.readFileSync(target, 'utf8'), source);

  // Add a top-level setting without disturbing nested settings or end comments.
  for (const [name, input] of [
    ['empty', '{ /* keep */ }\n'],
    ['line-comment', '{\n // keep\n}\n'],
    ['inline', '{"nested":{"editor.inertialScroll":false}} // end\n'],
    ['trailing', '{\n\t"other": [1, 2,], // keep\n}\n'],
    ['attached-comment', '{\r\n\t// This describes other.\r\n\t"other": true\r\n}\r\n'],
  ]) {
    const file = fixture(name, input);
    ok(run(['--settings', file, '--apply']));
    const first = fs.readFileSync(file, 'utf8');
    assert.match(first, /"editor.inertialScroll": true/);
    if (input.includes('// keep')) assert(first.includes('// keep'));
    if (input.includes('/* keep */')) assert(first.includes('/* keep */'));
    if (name === 'inline') assert(first.includes('"nested":{"editor.inertialScroll":false}'));
    if (name === 'attached-comment') {
      assert(first.includes('// This describes other.\r\n\t"other": true'));
      assert(!/(?<!\r)\n/.test(first), 'preserve CRLF line endings');
    }
    ok(run(['--settings', file, '--apply']));
    assert.equal(fs.readFileSync(file, 'utf8'), first, 'second apply should not rewrite');
    ok(run(['--settings', file, '--disable', '--apply']));
    assert.match(fs.readFileSync(file, 'utf8'), /"editor.inertialScroll": false/);
  }

  // Refuse malformed or ambiguous input before backing up or modifying anything.
  for (const [index, invalid] of [
    '{"editor.inertialScroll":false,"editor.inertialScroll":true}',
    '{"editor.inertialScroll":true,"editor\\u002einertialScroll":false}',
    '{"a": [1 2]}', '{,}', '{"a": [,]}', '{/* unfinished',
    '{"a":false,,}', '{"a":"unfinished}', '[]', 'null', '',
  ].entries()) {
    const file = fixture('invalid-' + index, invalid);
    const count = backups().length;
    assert.notEqual(run(['--settings', file, '--apply']).status, 0, invalid);
    assert.equal(fs.readFileSync(file, 'utf8'), invalid);
    assert.equal(backups().length, count);
  }
  const linkTarget = fixture('linked-target', '{"other": true}\n');
  const link = path.join(temporary, 'settings-link.json');
  fs.symlinkSync(linkTarget, link);
  ok(run(['--settings', link, '--apply']));
  assert(fs.lstatSync(link).isSymbolicLink());
  assert.equal(JSON.parse(fs.readFileSync(linkTarget, 'utf8'))['editor.inertialScroll'], true);
  const broken = path.join(temporary, 'broken.json');
  fs.symlinkSync(path.join(temporary, 'absent.json'), broken);
  assert.notEqual(run(['--settings', broken, '--apply']).status, 0);
  assert(fs.lstatSync(broken).isSymbolicLink());
  assert.notEqual(run(['--settings']).status, 0);
  assert.notEqual(run(['--unknown']).status, 0);
  console.log('PASS VS Code preview, JSONC preservation, backups, idempotency, disable and symlinks');
} finally {
  fs.rmSync(temporary, { recursive: true, force: true });
}
