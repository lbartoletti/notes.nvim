--- Telescope extension registration for notes.nvim
--- Makes the plugin available via :Telescope notes
return require("telescope").register_extension({
  setup = function(ext_config, config)
    -- Extension configuration
    -- ext_config: user-provided config for this extension
    -- config: telescope's global config
    -- Currently no extension-specific config needed
  end,
  exports = {
    notes = require("notes.picker").notes,
  },
})
