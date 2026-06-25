--- Registers the :Note user command

-- Guard against double-loading
if vim.g.loaded_notes then
  return
end
vim.g.loaded_notes = true

--- Main :Note command with subcommands
vim.api.nvim_create_user_command("Note", function(opts)
  local subcommand = opts.fargs[1]
  local args = vim.list_slice(opts.fargs, 2)

  local notes = require("notes")

  if subcommand == "new" then
    notes.new_note(args[1])
  elseif subcommand == "delete" then
    notes.delete_note(args[1])
  elseif subcommand == "list" then
    notes.show_list()
  elseif subcommand == "find" then
    require("notes.picker").notes()
  elseif subcommand == "grep" then
    require("notes.picker").grep()
  else
    vim.notify(
      "Unknown subcommand: " .. subcommand .. "\nAvailable: new, delete, list, find, grep",
      vim.log.levels.ERROR
    )
  end
end, {
  nargs = "+",
  desc  = "Manage notes and todos",
  complete = function(arg_lead, cmdline, _)
    local subcommands = { "new", "delete", "list", "find", "grep" }
    local args = vim.split(cmdline, "%s+")
    local num_args = #args - 1

    if num_args == 1 then
      return vim.tbl_filter(function(c) return vim.startswith(c, arg_lead) end, subcommands)
    end

    if num_args == 2 and args[2] == "delete" then
      local note_paths = require("notes").list_notes()
      local names = {}
      for _, p in ipairs(note_paths) do
        table.insert(names, require("notes").get_filename(p))
      end
      return vim.tbl_filter(function(n) return vim.startswith(n, arg_lead) end, names)
    end

    return {}
  end,
})
