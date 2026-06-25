# notes.nvim

A simple Neovim plugin for managing markdown notes and todos.

<a href="https://codeberg.org/lbartoletti/notes.nvim">
    <img alt="Get it on Codeberg" src="https://get-it-on.codeberg.org/get-it-on-blue-on-white.png" height="60" align="right">
</a>

> [!NOTE]
>
> **The canonical repository is hosted on [Codeberg](https://codeberg.org/lbartoletti/notes.nvim)**, which contains the official issue tracker. GitHub is a read-write mirror: PRs are accepted on both and synchronized back to Codeberg.

## Features

- Create, delete, and list markdown notes
- **No required dependencies** — pure Lua + Vim API, no plenary
- Multi-picker support, auto-detected: [snacks.nvim](https://github.com/folke/snacks.nvim) > [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) > [fzf-lua](https://github.com/ibhagwan/fzf-lua) > `vim.ui.select`
- Personal notes folder and project-local notes
- Works out-of-box with sensible defaults (no `setup()` required)

## Requirements

- Neovim >= 0.10.0
- One of the pickers above (optional — falls back to `vim.ui.select`)

## Installation

### lazy.nvim

Minimal (no picker dependency):

```lua
{ "lbartoletti/notes.nvim" }
```

With snacks.nvim (recommended):

```lua
{
  "lbartoletti/notes.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("notes").setup({
      personal_notes_dir = vim.fn.expand("~/.notes"),
      scope = "personal", -- "personal" | "project" | "auto"
    })
  end,
}
```

With telescope (legacy):

```lua
{
  "lbartoletti/notes.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  config = function()
    require("notes").setup()
    require("telescope").load_extension("notes")
  end,
}
```

## Usage

### Commands

```vim
:Note new [name]        " Create a new note (prompts if no name given)
:Note delete [name]     " Delete a note (with confirmation)
:Note list              " List notes using vim.ui.select
:Note find              " Open picker to browse notes by filename
:Note grep              " Open picker to full-text search note content
```

### Lua API

```lua
local notes = require("notes")

notes.new_note("my-note")
notes.new_note("project-note", { scope = "project" })
notes.delete_note("/path/to/note.md")
local paths = notes.list_notes()
local dir   = notes.get_notes_dir({ scope = "personal" })

require("notes.picker").notes()                       -- browse notes
require("notes.picker").grep()                        -- full-text search
require("notes.picker").notes({ scope = "project" })
```

### Recommended keymaps

```lua
vim.keymap.set("n", "<leader>fn", function() require("notes.picker").notes() end, { desc = "Find notes" })
vim.keymap.set("n", "<leader>sn", function() require("notes.picker").grep() end,  { desc = "Search notes" })
vim.keymap.set("n", "<leader>nn", function() require("notes").new_note() end,      { desc = "New note" })
vim.keymap.set("n", "<leader>np", function() require("notes").new_note(nil, { scope = "project" }) end, { desc = "New project note" })
```

## Configuration

```lua
require("notes").setup({
  personal_notes_dir = vim.fn.stdpath("data") .. "/notes", -- ~/.local/share/nvim/notes
  project_notes_dir  = ".notes",                           -- relative to cwd
  scope              = "personal",                         -- "personal" | "project" | "auto"
  file_extension     = ".md",
  confirm_delete     = true,
  picker             = nil,  -- nil = auto-detect, or "snacks"|"telescope"|"fzf-lua"|"builtin"
})
```

### Scope

- **`personal`** (default): notes go to `personal_notes_dir`
- **`project`**: notes go to `project_notes_dir` (relative to cwd)
- **`auto`**: project dir if inside a git repo, otherwise personal

Examples:

```lua
-- Personal knowledge base
require("notes").setup({ personal_notes_dir = vim.fn.expand("~/knowledge-base") })

-- Project notes with auto-switch
require("notes").setup({ scope = "auto" })
```

Force a specific picker:

```lua
require("notes").setup({ picker = "telescope" })
```

## Philosophy

- **No required dependencies** — works on any system
- **No timestamps** — add in filename or frontmatter if needed
- **No TODO states** — markdown checkboxes are sufficient
- **No syncing** — use Git, Syncthing, etc.
- **KISS** — simple code, simple features

## Contributing

Contributions welcome. Keep the KISS principle: simplicity over features, no unnecessary dependencies.

## License

MIT

## Alternatives

- [telekasten.nvim](https://github.com/renerocksai/telekasten.nvim) — full zettelkasten with links
- [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim) — Obsidian integration
- [neorg](https://github.com/nvim-neorg/neorg) — org-mode alternative

`notes.nvim` is simpler and lighter, focused purely on managing markdown files.
