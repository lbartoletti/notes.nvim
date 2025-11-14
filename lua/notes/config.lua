--- Configuration module for notes.nvim
--- Handles user configuration and provides sensible defaults
local M = {}

--- Default configuration options
--- @class NotesConfig
--- @field personal_notes_dir string Directory for personal notes
--- @field project_notes_dir string Directory for project-local notes (relative to cwd)
--- @field scope "personal"|"project"|"auto" Default scope for new notes
--- @field file_extension string File extension for notes (default: .md)
--- @field confirm_delete boolean Confirm before deleting notes
M.defaults = {
  personal_notes_dir = vim.fn.stdpath("data") .. "/notes",
  project_notes_dir = ".notes",
  scope = "personal",
  file_extension = ".md",
  confirm_delete = true,
}

--- Current options (merged with user config)
--- @type NotesConfig
M.options = {}

--- Setup configuration with user options
--- @param opts NotesConfig|nil User configuration options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

--- Initialize with defaults if not already setup
function M.ensure_setup()
  if vim.tbl_isempty(M.options) then
    M.options = vim.deepcopy(M.defaults)
  end
end

return M
