#!/usr/bin/env node
// /korean-mode on|off|status
// on     registers scripts/prompt-hook.sh as a UserPromptSubmit hook in ~/.claude/settings.json
//        and sets alwaysThinkingEnabled=false (ignored by models that always think, such as Fable).
// off    removes the hook and restores alwaysThinkingEnabled to the value saved by "on".
// Settings edits are hot-reloaded by Claude Code, so both take effect from the next prompt.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const skillDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..").replace(/\\/g, "/");
const settingsPath = path.join(os.homedir(), ".claude", "settings.json");
const prevPath = path.join(os.homedir(), ".claude", "korean-mode.prev.json");
const HOOK_MARK = "korean-mode/scripts/prompt-hook.sh";
const hookCommand = `bash "${skillDir}/scripts/prompt-hook.sh"`;

function readSettings() {
  const text = fs.existsSync(settingsPath) ? fs.readFileSync(settingsPath, "utf8") : "{}";
  const indent = (text.match(/^[ \t]+/m) || ["  "])[0];
  const eol = text.includes("\r\n") ? "\r\n" : "\n";
  return { data: JSON.parse(text), indent, eol };
}

function writeSettings({ data, indent, eol }) {
  fs.writeFileSync(settingsPath, JSON.stringify(data, null, indent).replace(/\n/g, eol) + eol);
}

function isOurs(entry) {
  return (entry.hooks || []).some((h) => typeof h.command === "string" && h.command.includes(HOOK_MARK));
}

function isOn(data) {
  return (data.hooks?.UserPromptSubmit || []).some(isOurs);
}

function turnOn() {
  const s = readSettings();
  if (isOn(s.data)) return "korean-mode는 이미 켜져 있습니다.";
  s.data.hooks ??= {};
  s.data.hooks.UserPromptSubmit ??= [];
  s.data.hooks.UserPromptSubmit.push({ hooks: [{ type: "command", command: hookCommand }] });
  if (!fs.existsSync(prevPath)) {
    fs.writeFileSync(prevPath, JSON.stringify({ alwaysThinkingEnabled: s.data.alwaysThinkingEnabled ?? null }));
  }
  s.data.alwaysThinkingEnabled = false;
  writeSettings(s);
  return "korean-mode를 켰습니다. 다음 프롬프트부터 한국어 5문장 규칙이 적용됩니다.";
}

function turnOff() {
  const s = readSettings();
  if (!isOn(s.data)) return "korean-mode는 이미 꺼져 있습니다.";
  s.data.hooks.UserPromptSubmit = s.data.hooks.UserPromptSubmit.filter((e) => !isOurs(e));
  if (s.data.hooks.UserPromptSubmit.length === 0) delete s.data.hooks.UserPromptSubmit;
  if (fs.existsSync(prevPath)) {
    const prev = JSON.parse(fs.readFileSync(prevPath, "utf8")).alwaysThinkingEnabled;
    if (prev === null) delete s.data.alwaysThinkingEnabled;
    else s.data.alwaysThinkingEnabled = prev;
    fs.unlinkSync(prevPath);
  }
  writeSettings(s);
  return "korean-mode를 꺼서 규칙 주입을 멈추고 thinking 설정을 원래대로 되돌렸습니다.";
}

function status() {
  const { data } = readSettings();
  return `korean-mode는 ${isOn(data) ? "켜져" : "꺼져"} 있습니다 (alwaysThinkingEnabled=${data.alwaysThinkingEnabled ?? "unset"}).`;
}

const actions = { on: turnOn, off: turnOff, status };
const rawArg = (process.argv[2] || "").trim();
const arg = rawArg.toLowerCase();

if (!rawArg) {
  console.log((isOn(readSettings().data) ? turnOff : turnOn)());
} else if (!actions[arg]) {
  console.log(`사용법: /korean-mode on|off|status\n${status()}`);
} else {
  console.log(actions[arg]());
}
