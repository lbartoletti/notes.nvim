--- Core note operations (pure Lua + Vim API, no dependencies)
local M = {}
local config = require("notes.config")

--- Setup the plugin with user configuration
--- @param opts NotesConfig|nil User configuration
function M.setup(opts)
  config.setup(opts)
end

--- Sanitize filename to prevent directory traversal and invalid characters
--- @param name string Raw filename
--- @return string Sanitized filename
local function sanitize_filename(name)
  name = name:gsub("[/\\]+", "-")
  name = name:gsub("[^%w%s%-_]", "-")
  name = name:gsub("%-+", "-")
  name = name:gsub("^%-+", ""):gsub("%-+$", "")
  return name
end

--- Check if a path exists on the filesystem
--- @param path string
--- @return boolean
local function path_exists(path)
  return vim.uv.fs_stat(path) ~= nil
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
    if is_git_repo() then
      return vim.fn.getcwd() .. "/" .. config.options.project_notes_dir
    else
      return config.options.personal_notes_dir
    end
  else
    return config.options.personal_notes_dir
  end
end

--- List all markdown notes in the specified directory (recursive)
--- @param opts {scope?: "personal"|"project"|"auto"} Options
--- @return string[] Array of absolute file paths
function M.list_notes(opts)
  local notes_dir = M.get_notes_dir(opts)
  if not path_exists(notes_dir) then
    return {}
  end
  return vim.fn.glob(notes_dir .. "/**/*.md", false, true)
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

  if not name or name == "" then
    name = vim.fn.input("Note name: ")
    if name == "" then
      vim.notify("Note creation cancelled", vim.log.levels.INFO)
      return
    end
  end

  name = sanitize_filename(name)
  if not name:match("%.md$") then
    name = name .. config.options.file_extension
  end

  local notes_dir = M.get_notes_dir(opts)

  if not path_exists(notes_dir) then
    vim.fn.mkdir(notes_dir, "p")
  end

  local file_path = notes_dir .. "/" .. name

  if path_exists(file_path) then
    vim.notify("Note already exists: " .. name, vim.log.levels.WARN)
    M.open_note(file_path)
    return
  end

  local f = io.open(file_path, "w")
  if f then f:close() end

  M.open_note(file_path)
  vim.notify("Created note: " .. name, vim.log.levels.INFO)
end

--- Delete a note
--- @param path string|nil Absolute path to note or filename
--- @param opts {scope?: "personal"|"project"|"auto"}|nil Options
function M.delete_note(path, opts)
  config.ensure_setup()

  if not path or path == "" then
    vim.notify("No note specified", vim.log.levels.ERROR)
    return
  end

  if not path:match("[/\\]") then
    local notes_dir = M.get_notes_dir(opts)
    path = notes_dir .. "/" .. path
  end

  if not path_exists(path) then
    vim.notify("Note does not exist: " .. path, vim.log.levels.ERROR)
    return
  end

  local filename = M.get_filename(path)

  if config.options.confirm_delete then
    vim.ui.input({
      prompt = "Delete note '" .. filename .. "'? [y/N]: ",
    }, function(input)
      if input and (input:lower() == "y" or input:lower() == "yes") then
        vim.fn.delete(path)
        vim.notify("Deleted note: " .. filename, vim.log.levels.INFO)
        local bufnr = vim.fn.bufnr(path)
        if bufnr ~= -1 then
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      else
        vim.notify("Deletion cancelled", vim.log.levels.INFO)
      end
    end)
  else
    vim.fn.delete(path)
    vim.notify("Deleted note: " .. filename, vim.log.levels.INFO)
  end
end

--- Show a simple list of notes using vim.ui.select (fallback when no picker available)
--- @param opts {scope?: "personal"|"project"|"auto"} Options
function M.show_list(opts)
  local notes = M.list_notes(opts)

  if #notes == 0 then
    vim.notify("No notes found", vim.log.levels.INFO)
    return
  end

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
