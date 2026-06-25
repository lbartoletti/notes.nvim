--- Multi-picker integration (snacks > telescope > fzf-lua > builtin)
local M = {}

--- Detect the best available picker
--- @return string One of: "snacks", "telescope", "fzf-lua", "builtin"
local function detect_picker()
  local config = require("notes.config")
  -- Honour explicit user preference
  if config.options.picker then
    return config.options.picker
  end
  -- Auto-detect
  if pcall(require, "snacks") and Snacks and Snacks.picker then
    return "snacks"
  end
  if pcall(require, "telescope") then
    return "telescope"
  end
  if pcall(require, "fzf-lua") then
    return "fzf-lua"
  end
  return "builtin"
end

--- Open a picker to browse and open notes
--- @param opts {scope?: "personal"|"project"|"auto", title?: string}|nil
function M.notes(opts)
  opts = opts or {}
  local notes   = require("notes")
  local dir     = notes.get_notes_dir(opts)
  local title   = opts.title or "Notes"
  local picker  = detect_picker()

  if picker == "snacks" then
    Snacks.picker.files({
      title = title,
      cwd   = dir,
    })

  elseif picker == "telescope" then
    require("telescope.builtin").find_files({
      cwd           = dir,
      prompt_title  = title,
    })

  elseif picker == "fzf-lua" then
    require("fzf-lua").files({
      cwd    = dir,
      prompt = title .. "> ",
      actions = {
        ["default"] = function(selected)
          if selected and selected[1] then
            -- fzf-lua returns filenames relative to cwd
            notes.open_note(dir .. "/" .. selected[1])
          end
        end,
      },
    })

  else
    notes.show_list(opts)
  end
end

--- Open a picker to full-text search notes
--- @param opts {scope?: "personal"|"project"|"auto", title?: string}|nil
function M.grep(opts)
  opts = opts or {}
  local notes  = require("notes")
  local dir    = notes.get_notes_dir(opts)
  local title  = opts.title or "Search Notes"
  local picker = detect_picker()

  if picker == "snacks" then
    Snacks.picker.grep({
      title = title,
      cwd   = dir,
    })

  elseif picker == "telescope" then
    require("telescope.builtin").live_grep({
      cwd           = dir,
      prompt_title  = title,
    })

  elseif picker == "fzf-lua" then
    require("fzf-lua").live_grep({ cwd = dir })

  else
    vim.notify("No fuzzy finder available for grep. Use :vimgrep instead.", vim.log.levels.WARN)
  end
end

return M
