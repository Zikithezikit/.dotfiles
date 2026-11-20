-- minuet backend that asks Claude Haiku through the logged-in Claude Code CLI (`claude -p`), so a Claude
-- subscription works without an API key. minuet loads backends as require("minuet.backends.<provider>").
-- Each request is a fresh headless process (~2s); shortcut: a persistent stream-json process would cut the
-- startup, upgrade if the latency bothers you.
local utils = require("minuet.utils")
local common = require("minuet.backends.common")
local defaults = require("minuet.config")

-- Access: the model gets NO tools (no file reads, edits, shell), no MCP, no settings/hooks, no session files, and
-- runs from an empty cache dir; all it sees is the code window minuet sends. That is all inline completion needs.
local M = {}

-- Files that usually hold secrets are never sent, even on a manual request.
local sensitive = { "^%.env", "%.pem$", "%.key$", "%.p12$", "%.pfx$", "^id_[%w_]+$", "^secrets?[%.%-_]", "^credentials?[%.%-_]",
  "%.kdbx$", "^%.netrc$", "^%.npmrc$", "^%.pypirc$" }
local function is_sensitive(path)
  local name = vim.fs.basename(path):lower()
  for _, pat in ipairs(sensitive) do
    if name:find(pat) then
      return true
    end
  end
  return false
end

-- minuet inserts whatever text comes back, so an answer that is not code (a refusal, a question) would land in the
-- buffer. Require the code inside tags and drop everything else.
local format_rule = [[

A <lsp_context> block may precede the code: declarations from the project's language server for symbols used near the
cursor. Use it to match real names, signatures and types, and never copy it into your reply.

Output format (strict): put your entire reply inside <completion></completion> tags and nothing outside them.
If you cannot or will not complete this code, reply with exactly <completion></completion> and no explanation.]]

-- Repo context without giving the model any access: ask the language server where the symbols near the cursor are
-- defined, keep the ones defined in this project (the model already knows the stdlib and libraries), fetch their
-- signatures/docs with hover, and send just that text. Everything is async and capped by lsp_timeout_ms.
local skip = {}
for w in ([[def class return if else elif for while in not and or is import from as with try except finally raise
  pass None True False self cls lambda yield async await print len range str int float bool list dict set tuple
  void char const static struct enum union typedef include define auto let var function export new this true false
  null undefined fn pub use mod impl match mut ref string number boolean std const let type interface extends
  implements public private protected]]):gmatch("%S+") do
  skip[w] = true
end
local not_project = { "/%.venv/", "/venv/", "/node_modules/", "/site%-packages/", "/%.cargo/", "/%.rustup/", "/target/",
  "/%.git/", "/usr/", "/opt/", "/%.local/share/", "/%.cache/" }

local function candidates(bufnr, row, col, max)
  local first = math.max(0, row - 25) -- 0-based first line of the lookback window
  local lines = vim.api.nvim_buf_get_lines(bufnr, first, row + 1, false)
  lines[#lines] = lines[#lines]:sub(1, col)
  local seen, out = {}, {}
  for i = #lines, 1, -1 do -- nearest to the cursor first
    local found = {}
    for pos, name in lines[i]:gmatch("()([%a_][%w_]*)") do
      found[#found + 1] = { pos = pos, name = name }
    end
    for j = #found, 1, -1 do
      local f = found[j]
      if #f.name > 1 and not skip[f.name] and not seen[f.name] then
        seen[f.name] = true
        out[#out + 1] = { name = f.name, line = first + i - 1, col = f.pos - 1 }
        if #out >= max then
          return out
        end
      end
    end
  end
  return out
end

---@return string? text of the first non-empty hover result
local function hover_text(results)
  for _, r in pairs(results or {}) do
    if r.result and r.result.contents then
      local md = vim.lsp.util.convert_input_to_markdown_lines(r.result.contents)
      local text = vim.trim(table.concat(md, "\n"):gsub("```%w*", ""):gsub("\n%s*\n+", "\n"):gsub("%-%-%-+", ""))
      if text ~= "" then
        return text
      end
    end
  end
end

-- cb(block) with a ready-to-paste text block ("" when there is nothing useful)
local function lsp_context(bufnr, options, window_is_partial, cb)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/definition" })
  if not options.lsp_context or #clients == 0 then
    return cb("")
  end
  local cur = vim.api.nvim_win_get_cursor(0)
  local cands = candidates(bufnr, cur[1] - 1, cur[2], options.lsp_max_candidates)
  local root = vim.fn.getcwd()
  local uri = vim.uri_from_bufnr(bufnr)
  local entries, pending, finished = {}, #cands, false

  local function finish()
    if finished then
      return
    end
    finished = true
    local parts, used = {}, 0
    for _, e in ipairs(entries) do
      local text = e.text:sub(1, options.lsp_max_chars_each)
      if used + #text > options.lsp_max_chars then
        break
      end
      used = used + #text
      parts[#parts + 1] = ("%s (%s):\n%s"):format(e.name, e.where, text)
    end
    cb(#parts > 0 and ("<lsp_context>\n" .. table.concat(parts, "\n---\n") .. "\n</lsp_context>\n\n") or "")
  end

  if pending == 0 then
    return finish()
  end
  vim.defer_fn(finish, options.lsp_timeout_ms)

  local function position(c)
    local line = vim.api.nvim_buf_get_lines(bufnr, c.line, c.line + 1, false)[1] or ""
    local ok, ch = pcall(vim.str_utfindex, line, "utf-16", c.col)
    return { line = c.line, character = ok and ch or c.col }
  end

  for _, c in ipairs(cands) do
    local params = { textDocument = { uri = uri }, position = position(c) }
    vim.lsp.buf_request_all(bufnr, "textDocument/definition", params, function(defs)
      local target
      for _, r in pairs(defs or {}) do
        local res = r.result
        local loc = res and (res.uri and res or res.targetUri and res or res[1])
        local target_uri = loc and (loc.uri or loc.targetUri)
        if target_uri then
          local path = vim.uri_to_fname(target_uri)
          local ok_path = vim.startswith(path, root)
          for _, pat in ipairs(not_project) do
            if path:find(pat) and not root:find(pat, 1, true) then
              ok_path = false
            end
          end
          -- a symbol defined in this very file is already in the code window, unless the window starts mid-file
          if path == vim.api.nvim_buf_get_name(bufnr) and not window_is_partial then
            ok_path = false
          end
          if ok_path then
            target = { path = path }
            break
          end
        end
      end
      if not target or finished then
        pending = pending - 1
        if pending == 0 then finish() end
        return
      end
      vim.lsp.buf_request_all(bufnr, "textDocument/hover", params, function(hov)
        local text = hover_text(hov)
        if text and not text:match("^%(module%)") and not text:match("^module ") and not finished then
          entries[#entries + 1] = { name = c.name, text = text, where = vim.fn.fnamemodify(target.path, ":.") }
        end
        pending = pending - 1
        if pending == 0 then finish() end
      end)
    end)
  end
end

local job ---@type vim.SystemObj?
local superseded = {} ---@type table<vim.SystemObj, true> jobs we killed ourselves
local stamps = {} ---@type integer[] start times (ms) of requests in the last minute
local failures, paused_until = 0, 0

-- Hard limits on top of minuet's debounce/throttle: at most `max_per_minute` requests, and after `max_failures`
-- failures in a row (logged out, offline, ...) stop for `pause_ms` instead of retrying on every keystroke.
local function allowed(options)
  local now = vim.uv.now()
  if now < paused_until then
    return false
  end
  while stamps[1] and now - stamps[1] > 60000 do
    table.remove(stamps, 1)
  end
  if #stamps >= options.max_per_minute then
    return false
  end
  stamps[#stamps + 1] = now
  return true
end

local function record_failure(options)
  failures = failures + 1
  if failures >= options.max_failures then
    failures = 0
    paused_until = vim.uv.now() + options.pause_ms
    utils.notify(("Claude ghost text paused for %ds after repeated failures"):format(options.pause_ms / 1000), "warn", vim.log.levels.WARN)
  end
end

function M.is_available()
  return vim.fn.executable("claude") == 1
end

local generation = 0

function M.complete(context, callback)
  local config = require("minuet").config
  local options = vim.deepcopy(config.provider_options.claude_code)

  if is_sensitive(vim.api.nvim_buf_get_name(0)) or not allowed(options) then
    return callback()
  end

  generation = generation + 1
  local mine = generation
  if job then -- one request in flight: the previous suggestion is stale as soon as the cursor moved
    superseded[job] = true
    job:kill(15)
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local relpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":.")
  local header = ""
  if context.opts and context.opts.is_incomplete_before then -- the window starts mid-file: keep the imports
    header = "<file_header>\n" .. table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, 15, false), "\n") .. "\n</file_header>\n\n"
  end
  lsp_context(bufnr, options, context.opts and context.opts.is_incomplete_before, function(extra)
    if mine ~= generation then -- a newer request started while we waited on the language server
      return callback()
    end
    M._send(context, callback, options, config, "File: " .. relpath .. "\n\n" .. header .. extra)
  end)
end

function M._send(context, callback, options, config, preamble)

  -- deepcopy the fallbacks: make_chat_llm_shot consumes its template argument, which would break the shared default
  local system = utils.make_system_prompt(options.system or vim.deepcopy(defaults.default_system), config.n_completions)
    .. format_rule
  local chat_input = options.chat_input or vim.deepcopy(defaults.default_chat_input)
  local prompt = preamble .. table.concat(utils.make_chat_llm_shot(context, chat_input), "\n")

  -- flags: no tools/MCP/skills/settings/session files, so only the system prompt and the code are sent;
  -- run from a neutral cwd so no project CLAUDE.md is picked up; stdin = "" closes it (the CLI waits 3s for it)
  local cwd = vim.fn.stdpath("cache") .. "/minuet-claude-code"
  vim.fn.mkdir(cwd, "p")
  local cmd = {
    "claude", "-p", "--model", options.model, "--tools", "", "--strict-mcp-config", "--disable-slash-commands",
    "--no-session-persistence", "--setting-sources", "", "--permission-mode", "dontAsk", "--system-prompt", system, prompt,
  }

  local this
  this = vim.system(cmd, { text = true, stdin = "", cwd = cwd, timeout = options.timeout_ms }, vim.schedule_wrap(function(result)
    if job == this then
      job = nil
    end
    -- the CLI traps SIGTERM and exits 143 with no output (signal stays 0), so a killed job must be tracked
    -- explicitly; 124 is vim.system's timeout code
    if superseded[this] or result.signal ~= 0 or result.code == 124 then
      superseded[this] = nil
      return callback()
    end
    if result.code ~= 0 or (result.stdout or "") == "" then
      -- the CLI reports some errors (e.g. not logged in) on stdout, so show both
      local detail = vim.trim((result.stderr or "") .. " " .. (result.stdout or "")):sub(1, 300)
      utils.notify(("claude -p failed (exit %d): %s"):format(result.code, detail), "error", vim.log.levels.ERROR)
      record_failure(options)
      return callback()
    end
    failures = 0
    local body = result.stdout:match("<completion>(.-)</completion>")
    if not body or body:match("^%s*$") then -- refusal, chatter or empty: nothing to insert
      utils.notify("Claude ghost text: no completion returned (" .. vim.trim(result.stdout):sub(1, 120) .. ")", "verbose", vim.log.levels.INFO)
      return callback()
    end
    body = body:gsub("^\n", ""):gsub("\n$", "")
    local items = common.parse_completion_items(body, "Claude Code")
    items = common.filter_context_sequences_in_items(items, context)
    -- the model sometimes returns more options than asked for, the extras are usually noise
    callback(vim.list_slice(utils.trim_completion_items(items), 1, config.n_completions))
  end))
  job = this
end

return M
