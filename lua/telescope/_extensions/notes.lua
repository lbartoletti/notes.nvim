--- Makes the plugin available via :Telescope notes
return require("telescope").register_extension({
  exports = {
    notes = require("notes.picker").notes,
  },
})
