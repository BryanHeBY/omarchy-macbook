#!/usr/bin/env node
// Enable VS Code editor inertia with a minimal JSONC edit and a private backup.
// Preview by default. No VS Code settings are linked to or stored in this repo.
'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const setting = 'editor.inertialScroll';
const usage = `Usage: features/vscode-scrolling/configure.cjs [--dry-run | --apply] [--disable] [--settings PATH]

Enable editor.inertialScroll (default), or set it to false with --disable.
Preview by default; --apply backs up the file before writing.
Default settings: $XDG_CONFIG_HOME/Code/User/settings.json (fallback: $HOME/.config)
Use --settings for another edition, named profile or custom user-data directory.
Requires Node.js 18 or newer. Close VS Code's settings editor before applying.
`;

// Keep source offsets while omitting comments and whitespace from JSON validation.
function tokenize(source) {
  const tokens = [];
  let index = 0;
  while (index < source.length) {
    const start = index;
    if (/\s/.test(source[index])) { index++; continue; }
    if (source.startsWith('//', index)) {
      while (index < source.length && !/[\r\n]/.test(source[index])) index++;
      continue;
    }
    if (source.startsWith('/*', index)) {
      const end = source.indexOf('*/', index + 2);
      if (end < 0) throw new Error('Unterminated JSONC comment.');
      index = end + 2;
      continue;
    }
    if (source[index] === '"') {
      index++;
      while (index < source.length) {
        if (source[index] === '\\') { index += 2; continue; }
        if (source[index++] === '"') break;
      }
    } else if ('{}[],:'.includes(source[index])) {
      index++;
    } else {
      while (index < source.length && !/[\s{}\[\],:"/]/.test(source[index])) index++;
    }
    if (index === start) throw new Error(`Unexpected JSONC token at offset ${index}.`);
    tokens.push({ text: source.slice(start, index), start, end: index });
  }
  return tokens;
}

function parse(source) {
  const tokens = tokenize(source);
  const json = tokens.filter((token, index) => !(token.text === ',' &&
    !['{', '['].includes(tokens[index - 1]?.text) &&
    ['}', ']'].includes(tokens[index + 1]?.text))).map(token => token.text).join(' ');
  const value = JSON.parse(json);
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('VS Code settings must be a JSONC object.');
  }
  const properties = [];
  let depth = 0;
  for (let index = 0; index < tokens.length; index++) {
    const token = tokens[index];
    if (depth === 1 && token.text.startsWith('"') && tokens[index + 1]?.text === ':') {
      let endIndex = index + 2;
      let nested = 0;
      while (endIndex < tokens.length) {
        const text = tokens[endIndex].text;
        if (nested === 0 && [',', '}'].includes(text)) break;
        if (['{', '['].includes(text)) nested++;
        if (['}', ']'].includes(text)) nested--;
        endIndex++;
      }
      properties.push({ key: JSON.parse(token.text), start: token.start,
        valueStart: tokens[index + 2].start, valueEnd: tokens[endIndex - 1].end });
    }
    if (['{', '['].includes(token.text)) depth++;
    if (['}', ']'].includes(token.text)) depth--;
  }
  return { value, tokens, properties };
}

function edit(source, enabled) {
  const { value, tokens, properties } = parse(source);
  const matches = properties.filter(property => property.key === setting);
  if (matches.length > 1) throw new Error(`Duplicate ${setting} keys; resolve them before applying.`);
  if (value[setting] === enabled) return source;
  if (matches.length) {
    const property = matches[0];
    return source.slice(0, property.valueStart) + enabled + source.slice(property.valueEnd);
  }
  const newline = source.includes('\r\n') ? '\r\n' : '\n';
  const entry = `${JSON.stringify(setting)}: ${enabled}`;
  // Insert after the opening brace, retaining comments beside their existing keys.
  if (properties.length) {
    const start = properties[0].start;
    const linePrefix = source.slice(source.lastIndexOf('\n', start - 1) + 1, start);
    const indent = /^[\t ]*$/.test(linePrefix) ? linePrefix : '  ';
    const open = tokens[0].end;
    const separation = /^[\t ]*\r?\n/.test(source.slice(open)) ? '' : newline + indent;
    return source.slice(0, open) + newline + indent + entry + ',' + separation + source.slice(open);
  }
  const close = tokens[tokens.length - 1].start;
  return source.slice(0, close) + newline + '  ' + entry + newline + source.slice(close);
}

function main() {
  const args = process.argv.slice(2);
  let apply = false;
  let enabled = true;
  let file = path.join(process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config'),
    'Code/User/settings.json');
  for (let index = 0; index < args.length; index++) {
    switch (args[index]) {
      case '--apply': apply = true; break;
      case '--dry-run': apply = false; break;
      case '--disable': enabled = false; break;
      case '--settings':
        if (!args[index + 1] || args[index + 1].startsWith('--')) throw new Error('--settings requires a path.');
        file = path.resolve(args[++index]);
        break;
      case '--help': case '-h': process.stdout.write(usage); return;
      default: throw new Error(`Unknown argument: ${args[index]}\n${usage}`);
    }
  }
  file = path.resolve(file);
  // Resolve existing links so an apply preserves the link itself.
  const exists = fs.existsSync(file);
  if (exists) file = fs.realpathSync(file);
  else if (fs.lstatSync(file, { throwIfNoEntry: false })) throw new Error('Settings path is a broken symlink.');
  if (exists && !fs.statSync(file).isFile()) throw new Error('Settings path must be a regular file.');
  const original = exists ? fs.readFileSync(file, 'utf8') : '{}\n';
  const updated = edit(original, enabled);
  if (parse(updated).value[setting] !== enabled) throw new Error('Updated settings failed validation.');
  console.log(`Settings: ${file}\nRequested: "${setting}": ${enabled}`);
  if (updated === original) { console.log('Already configured.'); return; }
  if (!apply) { console.log('Preview only. Use --apply to write this setting.'); return; }

  const unchanged = () => exists ? fs.existsSync(file) && fs.readFileSync(file, 'utf8') === original
    : !fs.existsSync(file) && !fs.lstatSync(file, { throwIfNoEntry: false });
  if (!unchanged()) throw new Error('Settings changed during preparation; retry.');
  if (exists) {
    const root = path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), '.local/state'),
      'omarchy-macbook/vscode-scroll-backups');
    fs.mkdirSync(root, { recursive: true, mode: 0o700 });
    const backup = fs.mkdtempSync(path.join(root, 'settings-'));
    fs.copyFileSync(file, path.join(backup, 'settings.json'));
    fs.chmodSync(path.join(backup, 'settings.json'), 0o600);
    console.log(`Backup: ${path.join(backup, 'settings.json')}`);
  }
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const temporary = fs.mkdtempSync(path.join(path.dirname(file), '.vscode-scroll-'));
  try {
    const staged = path.join(temporary, 'settings.json');
    const mode = exists ? fs.statSync(file).mode & 0o777 : 0o600;
    fs.writeFileSync(staged, updated, { mode });
    fs.chmodSync(staged, mode);
    if (!unchanged()) throw new Error('Settings changed before writing; retry.');
    fs.renameSync(staged, file);
  } finally {
    fs.rmSync(temporary, { recursive: true, force: true });
  }
  console.log('Applied. Test vertical touchpad scrolling in an editor.');
}

try { main(); } catch (error) {
  console.error(`Error: ${error.message}`);
  process.exitCode = 1;
}
