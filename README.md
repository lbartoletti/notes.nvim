# notes.nvim

A simple Neovim plugin for managing markdown notes and todos with Telescope integration.

<a href="https://codeberg.org/lbartoletti/notes.nvim">
    <img alt="Get it on Codeberg" src="https://get-it-on.codeberg.org/get-it-on-blue-on-white.png" height="60" align="right">
</a>

> [!NOTE]
> 
> **The canonical repository is hosted on [Codeberg](https://codeberg.org/lbartoletti/notes.nvim), which contains the official issue tracker and where development primarily occurs.**
>
> **Read-write mirror:** GitHub — pull requests are accepted here and synchronized back to Codeberg.
>
> Codeberg remains the authoritative source of truth for the project.


## Features

- Create, delete, and list markdown notes
- Full Telescope integration with fuzzy finding and preview
- Support for personal notes folder and project-local notes
- Simple command interface: `:Note new`, `:Note delete`, `:Note list`, `:Note find`
- Telescope picker with:
  - Content preview
  - Delete notes with `<C-d>`
  - Create new notes with `<C-n>`
- Works out-of-box with sensible defaults (no `setup()` required)
- Lazy-loaded for fast startup
- Git-friendly plain text storage

## Requirements

- Neovim >= 0.7.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for picker)

## Installation

### lazy.nvim

```lua
{
  "lbartoletti/notes.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    -- Optional: customize settings
    require("notes").setup({
      personal_notes_dir = vim.fn.expand("~/.notes"),
      project_notes_dir = ".notes",
      scope = "personal", -- "personal" | "project" | "auto"
    })

    -- Optional: load Telescope extension
    require("telescope").load_extension("notes")
  end,
}
```

### packer.nvim

```lua
use {
  "lbartoletti/notes.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("notes").setup({
      personal_notes_dir = vim.fn.expand("~/.notes"),
    })
    require("telescope").load_extension("notes")
  end,
}
```

### vim-plug

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'  " optional
Plug 'lbartoletti/notes.nvim'

" In your init.lua or vimscript:
lua << EOF
require("notes").setup()
require("telescope").load_extension("notes")
EOF
```

## Usage

### Commands

```vim
:Note new [name]        " Create a new note (prompts if no name given)
:Note delete [name]     " Delete a note (with confirmation)
:Note list              " List notes using vim.ui.select
:Note find              " Open Telescope picker (or list if Telescope not available)
```

### Telescope

```vim
:Telescope notes        " Open notes picker
```

**Telescope keybindings:**
- `<CR>` - Open selected note
- `<C-d>` - Delete selected note (with confirmation)
- `<C-n>` - Create new note (uses current search query as name)

### Lua API

```lua
local notes = require("notes")

-- Create a note
notes.new_note("my-new-note")

-- Create a project-local note
notes.new_note("project-note", { scope = "project" })

-- List all notes
local note_paths = notes.list_notes()

-- Delete a note
notes.delete_note("/path/to/note.md")

-- Open a note
notes.open_note("/path/to/note.md")

-- Get notes directory
local dir = notes.get_notes_dir({ scope = "personal" })
```

## Configuration

Default configuration:

```lua
{
  personal_notes_dir = vim.fn.stdpath("data") .. "/notes",  -- ~/.local/share/nvim/notes
  project_notes_dir = ".notes",                             -- Relative to project root
  scope = "personal",                                       -- "personal" | "project" | "auto"
  file_extension = ".md",                                   -- File extension for notes
  confirm_delete = true,                                    -- Confirm before deleting
}
```

### Scope Modes

- **`personal`** (default): All notes go to `personal_notes_dir`
- **`project`**: All notes go to `project_notes_dir` (relative to cwd)
- **`auto`**: Use project directory if inside a git repo, otherwise use personal

### Example Configurations

**Use a custom notes directory:**

```lua
require("notes").setup({
  personal_notes_dir = vim.fn.expand("~/Documents/Notes"),
})
```

**Auto-switch between personal and project notes:**

```lua
require("notes").setup({
  scope = "auto",  -- Uses .notes/ in git repos, ~/.local/share/nvim/notes elsewhere
})
```

**Store project notes at project root (not in subdirectory):**

```lua
require("notes").setup({
  project_notes_dir = "",  -- Notes go directly in cwd
  scope = "project",
})
```

## Keybindings

The plugin does not create default keybindings to avoid conflicts. Here are some recommended mappings:

```lua
-- Open Telescope notes picker
vim.keymap.set("n", "<leader>fn", "<cmd>Telescope notes<cr>", { desc = "Find notes" })

-- Create new note
vim.keymap.set("n", "<leader>nn", function()
  require("notes").new_note()
end, { desc = "New note" })

-- Quick note in project
vim.keymap.set("n", "<leader>np", function()
  require("notes").new_note(nil, { scope = "project" })
end, { desc = "New project note" })
```

## Use Cases

### Personal Knowledge Base

Store all notes in a single directory:

```lua
require("notes").setup({
  personal_notes_dir = vim.fn.expand("~/knowledge-base"),
  scope = "personal",
})
```

Sync with git:
```bash
cd ~/knowledge-base
git init
git add .
git commit -m "My notes"
git remote add origin git@github.com:yourusername/knowledge-base.git
git push -u origin main
```

### Project-Specific Notes

Keep notes alongside your project:

```lua
require("notes").setup({
  scope = "project",
  project_notes_dir = ".notes",
})
```

Add to `.gitignore` if notes are private:
```
.notes/
```

Or commit them if they're project documentation:
```bash
git add .notes/
git commit -m "Add project notes"
```

### Hybrid Mode (Recommended)

Let the plugin decide based on context:

```lua
require("notes").setup({
  scope = "auto",  -- Project notes in git repos, personal notes elsewhere
})
```

## Searching Note Content

While the Telescope picker searches by filename, you can search note content using Telescope's built-in live grep:

```vim
" Search in personal notes directory
:lua require('telescope.builtin').live_grep({ cwd = vim.fn.stdpath("data") .. "/notes" })

" Search in project notes
:lua require('telescope.builtin').live_grep({ cwd = ".notes" })
```

Or create a keymap:

```lua
vim.keymap.set("n", "<leader>sn", function()
  require('telescope.builtin').live_grep({
    cwd = require("notes").get_notes_dir(),
    prompt_title = "Search Notes",
  })
end, { desc = "Search notes content" })
```

## Tips

- Use descriptive filenames: `meeting-2024-01-15.md` instead of `notes.md`
- Add frontmatter manually if you need metadata:
  ```markdown
  ---
  created: 2024-01-15
  tags: meeting, project-x
  ---

  # Meeting Notes
  ```
- Use `<C-n>` in Telescope picker to quickly create notes based on your search query
- Organize with prefixes: `todo-`, `idea-`, `log-` for easy filtering

## Philosophy & Design Decisions

**Why no automatic timestamps?** They clutter diffs and aren't always useful. Add them manually in filenames or frontmatter if needed.

**Why no TODO states?** Markdown checkboxes work great: `- [ ] Task`. Use search to find incomplete tasks.

**Why no syncing?** Git, Dropbox, Syncthing, etc. already exist and work better. Use the right tool for the job.

**Why markdown?** Universal format, syntax highlighting, great tooling, readable in any editor.

**Why Telescope?** Most popular picker in the Neovim ecosystem, proven, extensible.

## Contributing

Contributions welcome! Please keep the KISS principle in mind:
- Prefer simplicity over features
- No unnecessary dependencies
- Code should be readable by intermediate Lua developers
- Follow existing patterns

## License

MIT

## Alternatives

- [telekasten.nvim](https://github.com/renerocksai/telekasten.nvim) - Full zettelkasten system with links
- [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim) - Obsidian integration
- [neorg](https://github.com/nvim-neorg/neorg) - Org-mode alternative

`notes.nvim` is simpler and lighter than these alternatives, focused purely on managing markdown notes.
