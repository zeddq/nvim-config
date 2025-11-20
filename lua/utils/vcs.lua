-- VCS Detection Module
-- Detects Git vs Jujutsu repositories with caching for performance
--
-- CRITICAL: This module prioritizes .jj over .git to handle colocated repos
-- (where Jujutsu uses Git as a backend, creating both .jj and .git directories)

local M = {}

-- Cache configuration
local cache = {}
local CACHE_TTL = 5000 -- 5 seconds in milliseconds
local MAX_DEPTH = 100 -- Maximum directory traversal depth

-- Debug mode (enable with: lua require("utils.vcs").debug = true)
M.debug = false

---Log debug message
---@param msg string Message to log
local function log(msg)
  if M.debug then
    print("[VCS] " .. msg)
  end
end

---Get current time in milliseconds
---@return number
local function get_time_ms()
  return vim.uv.hrtime() / 1000000
end

---Normalize path to absolute path
---@param path string|nil Path to normalize
---@return string Normalized absolute path
local function normalize_path(path)
  if not path or path == "" then
    path = vim.fn.getcwd()
  end

  -- If path is a file, get its directory
  if vim.fn.isdirectory(path) == 0 and vim.fn.filereadable(path) == 1 then
    path = vim.fn.fnamemodify(path, ":h")
  end

  -- Convert to absolute path
  return vim.fn.fnamemodify(path, ":p")
end

---Get cached VCS type if valid
---@param path string Normalized path
---@return string|nil VCS type or nil if cache miss/expired
local function get_from_cache(path)
  local entry = cache[path]
  if not entry then
    return nil
  end

  local age = get_time_ms() - entry.timestamp
  if age > CACHE_TTL then
    log("Cache expired for: " .. path)
    cache[path] = nil
    return nil
  end

  log("Cache hit for: " .. path .. " (" .. entry.vcs_type .. ")")
  return entry.vcs_type
end

---Store result in cache
---@param path string Normalized path
---@param vcs_type string VCS type ("jj", "git", "none")
---@param root string|nil Repository root path
local function set_cache(path, vcs_type, root)
  cache[path] = {
    vcs_type = vcs_type,
    root = root,
    timestamp = get_time_ms(),
  }
  log("Cached: " .. path .. " -> " .. vcs_type)
end

---Walk up directory tree to find VCS root
---@param start_path string Starting directory
---@param vcs_dir string VCS directory name (".jj" or ".git")
---@return string|nil Root directory path or nil if not found
local function find_vcs_root(start_path, vcs_dir)
  local current = start_path

  for _ = 1, MAX_DEPTH do
    if current == "/" or current == "" or current == "." then
      break
    end

    local vcs_path = current .. "/" .. vcs_dir

    -- Check for directory or file (git can be a file in worktrees)
    if vim.fn.isdirectory(vcs_path) == 1 or vim.fn.filereadable(vcs_path) == 1 then
      return current
    end

    -- Move up one directory
    local parent = vim.fn.fnamemodify(current, ":h")
    if parent == current then
      break -- Reached filesystem root
    end
    current = parent
  end

  return nil
end

---Check if path is within a jj repository
---@param path string|nil Path to check (defaults to current buffer/cwd)
---@return boolean
function M.is_jj_repo(path)
  path = normalize_path(path)
  local root = find_vcs_root(path, ".jj")
  return root ~= nil
end

---Check if path is within a git repository
---@param path string|nil Path to check (defaults to current buffer/cwd)
---@return boolean
function M.is_git_repo(path)
  path = normalize_path(path)
  local root = find_vcs_root(path, ".git")
  return root ~= nil
end

---Detect VCS type for a given path
---@param path string|nil Path to check (defaults to current buffer/cwd)
---@return "jj"|"git"|"none"
function M.detect_vcs_type(path)
  -- Normalize and validate path
  local ok, normalized_path = pcall(normalize_path, path)
  if not ok then
    log("Error normalizing path: " .. tostring(path))
    return "none"
  end

  path = normalized_path

  -- Check cache first
  local cached = get_from_cache(path)
  if cached then
    return cached
  end

  log("Detecting VCS for: " .. path)

  -- Detection with error handling
  local detection_ok, result = pcall(function()
    -- CRITICAL: Check .jj BEFORE .git
    -- Jujutsu repos can have both .jj and .git (colocated mode)
    -- .jj takes priority to prevent git operations in jj repos
    local jj_root = find_vcs_root(path, ".jj")
    if jj_root then
      set_cache(path, "jj", jj_root)
      return "jj"
    end

    local git_root = find_vcs_root(path, ".git")
    if git_root then
      set_cache(path, "git", git_root)
      return "git"
    end

    set_cache(path, "none", nil)
    return "none"
  end)

  if not detection_ok then
    vim.notify("VCS detection error: " .. tostring(result), vim.log.levels.ERROR)
    return "none"
  end

  return result
end

---Get repository root path
---@param path string|nil Path to start from (defaults to current buffer/cwd)
---@param vcs_type string|nil Specific VCS type to find ("jj"|"git"), nil for auto-detect
---@return string|nil Root path or nil if not in a repo
function M.get_repo_root(path, vcs_type)
  path = normalize_path(path)

  -- Check cache first
  local entry = cache[path]
  if entry and entry.root then
    local age = get_time_ms() - entry.timestamp
    if age <= CACHE_TTL then
      return entry.root
    end
  end

  -- Auto-detect if type not specified
  if not vcs_type then
    vcs_type = M.detect_vcs_type(path)
  end

  if vcs_type == "none" then
    return nil
  end

  local vcs_dir = (vcs_type == "jj") and ".jj" or ".git"
  return find_vcs_root(path, vcs_dir)
end

---Get cached VCS type without re-detection (fast path)
---@param path string|nil Path to check
---@return string|nil Cached VCS type or nil if not cached/expired
function M.get_cached_vcs_type(path)
  path = normalize_path(path)
  return get_from_cache(path)
end

---Clear cache for a specific path (or all if nil)
---@param path string|nil Path to clear cache for, nil clears all
function M.clear_cache(path)
  if path then
    path = normalize_path(path)
    cache[path] = nil
    log("Cache cleared for: " .. path)
  else
    cache = {}
    log("Cache cleared (all)")
  end

  -- Emit event for other plugins (e.g., gitsigns)
  vim.api.nvim_exec_autocmds("User", { pattern = "VCSCacheCleared" })
end

---Get cache statistics (for debugging)
---@return table Cache stats
function M.get_cache_stats()
  local total = 0
  local valid = 0
  local now = get_time_ms()

  for path, entry in pairs(cache) do
    total = total + 1
    local age = now - entry.timestamp
    if age <= CACHE_TTL then
      valid = valid + 1
    end
  end

  return {
    total_entries = total,
    valid_entries = valid,
    expired_entries = total - valid,
    cache_ttl_ms = CACHE_TTL,
  }
end

return M
