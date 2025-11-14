--- Telescope picker integration for notes.nvim
--- Provides fuzzy finding, preview, deletion, and creation
local M = {}

--- Main notes picker
--- @param opts table|nil Telescope picker options
function M.notes(opts)
  -- Check if Telescope is available
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("Telescope not found. Use :Note list instead.", vim.log.levels.ERROR)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  local notes = require("notes")

  opts = opts or {}
  local note_paths = notes.list_notes(opts)

  pickers
    .new(opts, {
      prompt_title = "Notes",
      finder = finders.new_table({
        results = note_paths,
        entry_maker = function(entry)
          return {
            value = entry,
            display = notes.get_filename(entry),
            ordinal = notes.get_filename(entry),
            path = entry,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer({
        title = "Note Preview",
        define_preview = function(self, entry, status)
          conf.buffer_previewer_maker(entry.path, self.state.bufnr, {
            bufname = self.state.bufname,
            winid = self.state.winid,
          })
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        -- Default action: open note
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            notes.open_note(selection.value)
          end
        end)

        -- <C-d>: Delete note
        map("i", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end

          local current_picker = action_state.get_current_picker(prompt_bufnr)
          local filename = notes.get_filename(selection.value)

          vim.ui.input({
            prompt = "Delete note '" .. filename .. "'? [y/N]: ",
          }, function(input)
            if input and (input:lower() == "y" or input:lower() == "yes") then
              local Path = require("plenary.path")
              local file_path = Path:new(selection.value)
              file_path:rm()

              vim.notify("Deleted note: " .. filename, vim.log.levels.INFO)

              -- Close buffer if open
              local bufnr = vim.fn.bufnr(selection.value)
              if bufnr ~= -1 then
                vim.api.nvim_buf_delete(bufnr, { force = true })
              end

              -- Refresh picker
              current_picker:refresh(finders.new_table({
                results = notes.list_notes(opts),
                entry_maker = function(entry)
                  return {
                    value = entry,
                    display = notes.get_filename(entry),
                    ordinal = notes.get_filename(entry),
                    path = entry,
                  }
                end,
              }), { reset_prompt = false })
            end
          end)
        end)

        map("n", "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if not selection then
            return
          end

          local current_picker = action_state.get_current_picker(prompt_bufnr)
          local filename = notes.get_filename(selection.value)

          vim.ui.input({
            prompt = "Delete note '" .. filename .. "'? [y/N]: ",
          }, function(input)
            if input and (input:lower() == "y" or input:lower() == "yes") then
              local Path = require("plenary.path")
              local file_path = Path:new(selection.value)
              file_path:rm()

              vim.notify("Deleted note: " .. filename, vim.log.levels.INFO)

              -- Close buffer if open
              local bufnr = vim.fn.bufnr(selection.value)
              if bufnr ~= -1 then
                vim.api.nvim_buf_delete(bufnr, { force = true })
              end

              -- Refresh picker
              current_picker:refresh(finders.new_table({
                results = notes.list_notes(opts),
                entry_maker = function(entry)
                  return {
                    value = entry,
                    display = notes.get_filename(entry),
                    ordinal = notes.get_filename(entry),
                    path = entry,
                  }
                end,
              }), { reset_prompt = false })
            end
          end)
        end)

        -- <C-n>: Create new note with current query
        map("i", "<C-n>", function()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          local query = current_picker:_get_prompt()

          actions.close(prompt_bufnr)

          if query and query ~= "" then
            notes.new_note(query, opts)
          else
            notes.new_note(nil, opts)
          end
        end)

        map("n", "<C-n>", function()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          local query = current_picker:_get_prompt()

          actions.close(prompt_bufnr)

          if query and query ~= "" then
            notes.new_note(query, opts)
          else
            notes.new_note(nil, opts)
          end
        end)

        return true
      end,
    })
    :find()
end

return M
