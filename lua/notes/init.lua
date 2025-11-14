--- Main module for notes.nvim
--- Core functionality for managing notes
local M = {}
local config = require("notes.config")
local Path = require("plenary.path")

--- Setup the plugin with user configuration
--- @param opts NotesConfig|nil User configuration
function M.setup(opts)
  config.setup(opts)
end

--- Sanitize filename to prevent directory traversal and invalid characters
--- @param name string Raw filename
--- @return string Sanitized filename
local function sanitize_filename(name)
  -- Remove path separators and dangerous characters
  name = name:gsub("[/\\]+", "-")
  -- Replace spaces and special chars with dash
  name = name:gsub("[^%w%s%-_]", "-")
  -- Collapse multiple dashes
  name = name:gsub("%-+", "-")
  -- Trim dashes from ends
  name = name:gsub("^%-+", ""):gsub("%-+$", "")
  return name
end

--- Check if current directory is inside a git repository
--- @return boolean
local function is_git_repo()
  local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
  return git_dir ~= ""
end

--- Get the notes directory based on scope
--- @param opts {scope?: "personal"|"project"|"auto"} Options
--- @return string Absolute path to notes directory
function M.get_notes_dir(opts)
  config.ensure_setup()
  opts = opts or {}
  local scope = opts.scope or config.options.scope

  if scope == "project" then
    return vim.fn.getcwd() .. "/" .. config.options.project_notes_dir
  elseif scope == "auto" then
    -- Auto mode: use project dir if in git repo, otherwise personal
    if is_git_repo() then
      return vim.fn.getcwd() .. "/" .. config.options.project_notes_dir
    else
      return config.options.personal_notes_dir
    end
  else
    -- Default to personal
    return config.options.personal_notes_dir
  end
end

--- List all notes in the specified directory
--- @param opts {scope?: "personal"|"project"|"auto"} Options
--- @return string[] Array of absolute file paths
function M.list_notes(opts)
  local notes_dir = M.get_notes_dir(opts)
  local path = Path:new(notes_dir)

  if not path:exists() then
    return {}
  end

  local notes = {}
  local scan = require("plenary.scandir")

  scan.scan_dir(notes_dir, {
    hidden = false,
    add_dirs = false,
    respect_gitignore = true,
    search_pattern = ".*%.md$",
    on_insert = function(entry)
      table.insert(notes, entry)
    end,
  })

  return notes
end

--- Get filename from path
--- @param path string Absolute file path
--- @return string Filename without directory
function M.get_filename(path)
  return vim.fn.fnamemodify(path, ":t")
end

--- Open a note in a buffer
--- @param path string Absolute path to note
function M.open_note(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

--- Create a new note
--- @param name string|nil Note name (without extension)
--- @param opts {scope?: "personal"|"project"|"auto"} Options
function M.new_note(name, opts)
  config.ensure_setup()
  opts = opts or {}

  -- Prompt for name if not provided
  if not name or name == "" then
    name = vim.fn.input("Note name: ")
    if name == "" then
      vim.notify("Note creation cancelled", vim.log.levels.INFO)
      return
    end
  end

  -- Sanitize and add extension
  name = sanitize_filename(name)
  if not name:match("%.md$") then
    name = name .. config.options.file_extension
  end

  local notes_dir = M.get_notes_dir(opts)
  local dir_path = Path:new(notes_dir)

  -- Create directory if it doesn't exist
  if not dir_path:exists() then
    dir_path:mkdir({ parents = true, exists_ok = true })
  end

  local file_path = Path:new(notes_dir, name)

  -- Check if file already exists
  if file_path:exists() then
    vim.notify("Note already exists: " .. name, vim.log.levels.WARN)
    M.open_note(file_path:absolute())
    return
  end

  -- Create empty file
  file_path:touch({ parents = true })

  -- Open in buffer
  M.open_note(file_path:absolute())

  vim.notify("Created note: " .. name, vim.log.levels.INFO)
end

--- Delete a note
--- @param path string|nil Absolute path to note or filename
function M.delete_note(path, opts)
  config.ensure_setup()

  if not path or path == "" then
    vim.notify("No note specified", vim.log.levels.ERROR)
    return
  end

  -- If it's just a filename (no path separators), search in notes directory
  if not path:match("[/\\]") then
    local notes_dir = M.get_notes_dir(opts)
    path = notes_dir .. "/" .. path
  end

  local file_path = Path:new(path)

  if not file_path:exists() then
    vim.notify("Note does not exist: " .. path, vim.log.levels.ERROR)
    return
  end

  local filename = M.get_filename(path)

  -- Confirm deletion
  if config.options.confirm_delete then
    vim.ui.input({
      prompt = "Delete note '" .. filename .. "'? [y/N]: ",
    }, function(input)
      if input and (input:lower() == "y" or input:lower() == "yes") then
        file_path:rm()
        vim.notify("Deleted note: " .. filename, vim.log.levels.INFO)

        -- Close buffer if it's open
        local bufnr = vim.fn.bufnr(path)
        if bufnr ~= -1 then
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      else
        vim.notify("Deletion cancelled", vim.log.levels.INFO)
      end
    end)
  else
    file_path:rm()
    vim.notify("Deleted note: " .. filename, vim.log.levels.INFO)
  end
end

--- Show a simple list of notes using vim.ui.select
--- @param opts {scope?: "personal"|"project"|"auto"} Options
function M.show_list(opts)
  local notes = M.list_notes(opts)

  if #notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end

  -- Extract filenames for display
  local items = {}
  for _, note_path in ipairs(notes) do
    table.insert(items, M.get_filename(note_path))
  end

  vim.ui.select(items, {
    prompt = "Select note:",
  }, function(choice, idx)
    if choice then
      M.open_note(notes[idx])
    end
  end)
end

return M
