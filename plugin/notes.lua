--- Plugin entry point for notes.nvim
--- Registers user commands (auto-loaded on startup)

-- Guard against double-loading
if vim.g.loaded_notes then
  return
end
vim.g.loaded_notes = true

--- Main :Note command with subcommands
vim.api.nvim_create_user_command("Note", function(opts)
  local subcommand = opts.fargs[1]
  local args = vim.list_slice(opts.fargs, 2)

  -- Lazy load the plugin only when command is used
  local notes = require("notes")

  if subcommand == "new" then
    notes.new_note(args[1])
  elseif subcommand == "delete" then
    notes.delete_note(args[1])
  elseif subcommand == "list" then
    notes.show_list()
  elseif subcommand == "find" then
    -- Try to use Telescope, fall back to list if not available
    local has_telescope, telescope = pcall(require, "telescope")
    if has_telescope then
      telescope.extensions.notes.notes()
    else
      notes.show_list()
    end
  else
    vim.notify(
      "Unknown subcommand: " .. subcommand .. "\nAvailable: new, delete, list, find",
      vim.log.levels.ERROR
    )
  end
end, {
  nargs = "+",
  desc = "Manage notes and todos",
  complete = function(arg_lead, cmdline, cursor_pos)
    local subcommands = { "new", "delete", "list", "find" }

    -- Parse current arguments
    local args = vim.split(cmdline, "%s+")
    local num_args = #args - 1 -- Exclude command name

    -- First argument: complete subcommands
    if num_args == 1 then
      return vim.tbl_filter(function(cmd)
        return vim.startswith(cmd, arg_lead)
      end, subcommands)
    end

    -- Second argument for delete: complete note names
    if num_args == 2 and args[2] == "delete" then
      local notes = require("notes")
      local note_paths = notes.list_notes()
      local note_names = {}
      for _, path in ipairs(note_paths) do
        table.insert(note_names, notes.get_filename(path))
      end
      return vim.tbl_filter(function(name)
        return vim.startswith(name, arg_lead)
      end, note_names)
    end

    return {}
  end,
})
