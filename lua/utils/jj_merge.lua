-- JJ Merge Helper
-- Buffer-local keymaps for jj resolve 3-way merges opened via Neovim.

local M = {}

local ROLE_INDEX_3_WAY = { left = 1, base = 2, right = 3 }
local ROLE_INDEX_2_WAY = { left = 1, right = 2 }

local function is_floating(win)
  local cfg = vim.api.nvim_win_get_config(win)
  return cfg.relative ~= nil and cfg.relative ~= ""
end

local function win_has_diff(win)
  return vim.api.nvim_get_option_value("diff", { win = win })
end

local function sort_wins_left_to_right(wins)
  table.sort(wins, function(a, b)
    local ra, ca = unpack(vim.api.nvim_win_get_position(a))
    local rb, cb = unpack(vim.api.nvim_win_get_position(b))
    if ra == rb then
      return ca < cb
    end
    return ra < rb
  end)
  return wins
end

local function find_output_win()
  local wins = vim.api.nvim_tabpage_list_wins(0)

  local out_buf = vim.g.jj_merge_outbuf
  if type(out_buf) == "number" and vim.api.nvim_buf_is_valid(out_buf) then
    for _, win in ipairs(wins) do
      if not is_floating(win) and vim.api.nvim_win_get_buf(win) == out_buf then
        return win, out_buf
      end
    end
  end

  local candidate_win, candidate_buf
  for _, win in ipairs(wins) do
    if not is_floating(win) and not win_has_diff(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local modifiable = vim.api.nvim_get_option_value("modifiable", { buf = buf })
      local readonly = vim.api.nvim_get_option_value("readonly", { buf = buf })
      if modifiable and not readonly then
        if candidate_win then
          return nil, nil
        end
        candidate_win, candidate_buf = win, buf
      end
    end
  end

  return candidate_win, candidate_buf
end

local function get_diff_wins(exclude_win)
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_floating(win) and win ~= exclude_win and win_has_diff(win) then
      table.insert(wins, win)
    end
  end
  return wins
end

local merge_types = { twoway = 2, threeway = 3 }
-- 2 or 3
local merge_type = 0

local function get_role_win(role, out_win)
  local diff_wins = sort_wins_left_to_right(get_diff_wins(out_win))
  local idx = -1

  if #diff_wins == 3 then
    merge_type = merge_types.threeway
    idx = ROLE_INDEX_3_WAY[role]
    if not idx then
      return nil, nil, "unknown role: " .. tostring(role)
    end
  elseif #diff_wins == 2 then
    merge_type = merge_types.twoway
    idx = ROLE_INDEX_2_WAY[role]
    if not idx then
      return nil, nil, "unknown role: " .. tostring(role)
    end
  else
    return nil, nil, ("expected 2 or 3 diff windows, found %d"):format(#diff_wins)
  end

  if idx < 0 then
    error("Invalid windows configuration found", vim.ERROR)
  end

  local win = diff_wins[idx]
  return win, vim.api.nvim_win_get_buf(win), nil
end

local function set_win_diff(win, enabled)
  vim.api.nvim_set_option_value("diff", enabled, { win = win })
end

function M.take(role)
  -- Try to detect 3-way merge (has separate non-diff output window)
  local out_win_3way = select(1, find_output_win())

  if out_win_3way then
    -- 3-WAY MERGE MODE
    local src_win, src_buf, err = get_role_win(role, out_win_3way)
    if not src_buf then
      vim.notify("JJ merge: " .. err, vim.log.levels.WARN)
      return
    end

    local previous_win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(out_win_3way)

    local diff_wins = sort_wins_left_to_right(get_diff_wins(out_win_3way))
    local original_diff = { [out_win_3way] = win_has_diff(out_win_3way) }
    for _, win in ipairs(diff_wins) do
      original_diff[win] = win_has_diff(win)
    end

    local ok, diff_err = pcall(function()
      -- Avoid 4-way diff recalculation (which causes the "missing line" filler artifacts).
      -- Temporarily leave diff enabled only for OUTPUT + the selected source window.
      for _, win in ipairs(diff_wins) do
        set_win_diff(win, win == src_win)
      end
      set_win_diff(out_win_3way, true)

      vim.api.nvim_set_current_win(out_win_3way)
      vim.cmd("diffupdate")
      vim.cmd("diffget " .. tostring(src_buf))
    end)

    -- Restore original diff state (including keeping OUTPUT out of diff mode by default).
    for win, was in pairs(original_diff) do
      if vim.api.nvim_win_is_valid(win) then
        set_win_diff(win, was)
      end
    end

    if not ok then
      vim.notify("JJ merge: " .. tostring(diff_err), vim.log.levels.ERROR)
    end

    pcall(vim.api.nvim_win_set_cursor, out_win_3way, cursor)
    if vim.api.nvim_win_is_valid(previous_win) then
      vim.api.nvim_set_current_win(previous_win)
    end
  else
    -- Try to detect 2-way merge (both windows in diff, left is output)
    local all_diff_wins = get_diff_wins(nil)

    if #all_diff_wins == 2 then
      -- 2-WAY MERGE MODE
      if role == "base" then
        vim.notify("JJ merge: 'base' not available in 2-way merge", vim.log.levels.WARN)
        return
      end

      local sorted = sort_wins_left_to_right(all_diff_wins)
      local out_win = sorted[1]  -- Left window is output in 2-way merge
      local src_idx = (role == "left") and 1 or 2
      local src_win = sorted[src_idx]
      local src_buf = vim.api.nvim_win_get_buf(src_win)

      local previous_win = vim.api.nvim_get_current_win()
      local cursor = vim.api.nvim_win_get_cursor(out_win)

      -- In 2-way merge, both windows are always in diff mode - no toggling needed
      local ok, diff_err = pcall(function()
        vim.api.nvim_set_current_win(out_win)
        vim.cmd("diffupdate")
        vim.cmd("diffget " .. tostring(src_buf))
      end)

      if not ok then
        vim.notify("JJ merge: " .. tostring(diff_err), vim.log.levels.ERROR)
      end

      pcall(vim.api.nvim_win_set_cursor, out_win, cursor)
      if vim.api.nvim_win_is_valid(previous_win) then
        vim.api.nvim_set_current_win(previous_win)
      end
    else
      vim.notify("JJ merge: invalid window configuration", vim.log.levels.WARN)
    end
  end
end

function M.setup_keymaps()
  local out_win, out_buf = find_output_win()
  if not out_win or not out_buf then
    return
  end

  local diff_wins = get_diff_wins(out_win)
  if #diff_wins == 3 then
    merge_type = merge_types.threeway
  elseif #diff_wins == 2 then
    merge_type = merge_types.twoway
  else
    return
  end

  local ok, already = pcall(vim.api.nvim_buf_get_var, out_buf, "jj_merge_keymaps_set")
  if ok and already then
    return
  end
  pcall(vim.api.nvim_buf_set_var, out_buf, "jj_merge_keymaps_set", true)

  local opts = { buffer = out_buf, silent = true }

  vim.keymap.set("n", "<leader>ml", function()
    M.take("left")
  end, vim.tbl_extend("force", opts, { desc = "Merge: take LEFT (top-left)" }))
  if merge_type == merge_types.threeway then
    vim.keymap.set("n", "<leader>mb", function()
      M.take("base")
    end, vim.tbl_extend("force", opts, { desc = "Merge: take BASE (top-middle)" }))
  end
  vim.keymap.set("n", "<leader>mr", function()
    M.take("right")
  end, vim.tbl_extend("force", opts, { desc = "Merge: take RIGHT (top-right)" }))
end

return M
