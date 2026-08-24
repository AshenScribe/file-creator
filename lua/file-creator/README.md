# file-creator.nvim

A lightweight, intelligent Java file scaffolding plugin for Neovim. It automatically infers packages, creates nested directory structures on the fly, injects license headers, and scaffolds boilerplate code.

## Features

- **Smart Directory Detection:** Prefers the active buffer's directory; falls back to standard source roots (`src/main/java`, `src/test/java`, `src`) or project roots (`build.gradle`, `.git`).
- **Automatic Package Inference:** Converts directory paths into proper Java package declarations (e.g., `src/main/java/org/example/server` becomes `package org.example.server;`).
- **Recursive License Injection:** Scans the current directory, parent directories, and upstream paths for license files (`LICENSE`, `LICENSE.txt`, `LICENSE.md`) and formats them into clean Java block comments (`/* ... */`).
- **Nested Path Creation:** Automatically creates missing parent directories recursively when typing nested paths (e.g., typing `server/messaging/UserService` creates the `server/messaging/` folder structure automatically).
- **Built-in Templates:** Out-of-the-box support for `Class`, `Interface`, `Enum`, and `Record` templates (fully customizable).
- **Fully Tested:** Includes a comprehensive integration test suite built with `mini.test`.

---

## Installation

If you use [lazy.nvim](https://github.com/folke/lazy.nvim) for managing your local plugins:

```lua
return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/file-creator",
    name = "file-creator",
    config = function()
      require("file-creator").setup({
        should_format = true, -- Auto-format via LSP after creation
      })
    end,
  },
}
```

---

## Configuration

You can customize the plugin by passing an options table to the `setup()` function:

```lua
require("file-creator").setup({
  -- Custom search patterns for source code roots
  java_source_dirs = { "src/main/java", "src/test/java", "src" },

  -- Override or add custom templates
  templates = {
    Class     = "public class ${name} {\n    \n}\n",
    Interface = "public interface ${name} {\n    \n}\n",
    Enum      = "public enum ${name} {\n    \n}\n",
    Record    = "public record ${name}() {\n    \n}\n",
  },

  -- License banner settings
  license = {
    enabled = true,
    filenames = { "LICENSE", "LICENSE.txt", "LICENSE.md" },
  },

  -- Trigger LSP formatting immediately after file creation
  should_format = true,
})
```

---

## Usage

The plugin provides direct user commands to scaffold different Java types instantly. When executed, you will be prompted to type a name (subdirectories are supported using `/`).

- `:CreateJavaClass` — Scaffolds a new Java Class.
- `:CreateJavaInterface` — Scaffolds a new Java Interface.
- `:CreateJavaEnum` — Scaffolds a new Java Enum.
- `:CreateJavaRecord` — Scaffolds a new Java Record.

### Examples:
- Running `:CreateJavaClass` and typing `UserService` creates `UserService.java` with package and license headers.
- Running `:CreateJavaClass` and typing `server/messaging/MessagingClient` will automatically create the `server/messaging/` directories, calculate package `org.example.server.messaging`, and generate the file.

---

## Testing

This plugin uses [`mini.test`](https://github.com/nvim-mini/mini.test) for automated unit and integration testing.

To run the test suite:
```bash
nvim --headless -u NONE -c "lua vim.opt.rtp:prepend('.'); vim.opt.rtp:prepend('deps/mini.nvim'); require('mini.test').setup(); MiniTest.run_file('lua/file-creator/tests/file_creator_spec.lua')"
```

---

## License

Distributed under the MIT License. See `LICENSE` for more information.
```
