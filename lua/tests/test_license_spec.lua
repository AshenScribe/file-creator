local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local T = new_set()
local child

local function start_child()
    child = MiniTest.new_child_neovim()
    child.start({ "-u", "NONE" })
    child.lua([[
        vim.opt.rtp:prepend(".")
        vim.opt.rtp:append(vim.fn.glob("~/.local/share/nvim/lazy/snacks*"))
        require("file-creator").setup({ should_format = false, organize_imports = false })
    ]])
end

T["license resolution"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["license resolution"]["LICENSE found one directory upward"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/subdir", "p")
        vim.fn.writefile({"MIT License", "Copyright 2026"}, root .. "/LICENSE")
        return root
    end)()]])

    local banner = child.lua_get(string.format([[require("file-creator")._get_license_banner(%q)]], root .. "/subdir"))
    eq(banner, "/*\n * MIT License\n * Copyright 2026\n */\n\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["license resolution"]["LICENSE found multiple directories upward"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/a/b/c/d", "p")
        vim.fn.writefile({"Apache 2.0"}, root .. "/LICENSE.txt")
        return root
    end)()]])

    local banner = child.lua_get(string.format([[require("file-creator")._get_license_banner(%q)]], root .. "/a/b/c/d"))
    eq(banner, "/*\n * Apache 2.0\n */\n\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["license resolution"]["Nearest license wins"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/module/service", "p")
        vim.fn.writefile({"Root License"}, root .. "/LICENSE")
        vim.fn.writefile({"Module License"}, root .. "/module/LICENSE")
        return root
    end)()]])

    local banner = child.lua_get(string.format([[require("file-creator")._get_license_banner(%q)]], root .. "/module/service"))
    eq(banner, "/*\n * Module License\n */\n\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["license resolution"]["License disabled via config"] = function()
    child.lua([[
        require("file-creator").setup({
            license = { enabled = false }
        })
    ]])
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/subdir", "p")
        vim.fn.writefile({"MIT License"}, root .. "/LICENSE")
        return root
    end)()]])

    local banner = child.lua_get(string.format([[require("file-creator")._get_license_banner(%q)]], root .. "/subdir"))
    eq(banner, "")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["license resolution"]["Whitespace-only license returns empty string"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root, "p")
        vim.fn.writefile({"   ", "  \t  "}, root .. "/LICENSE")
        return root
    end)()]])

    local banner = child.lua_get(string.format([[require("file-creator")._get_license_banner(%q)]], root))
    eq(banner, "")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["license resolution"]["Multi-line license formatting with empty lines"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root, "p")
        vim.fn.writefile({"Line 1", "", "Line 2", "", "Line 3"}, root .. "/LICENSE.md")
        return root
    end)()]])

    local banner = child.lua_get(string.format([[require("file-creator")._get_license_banner(%q)]], root))
    eq(banner, "/*\n * Line 1\n * Line 2\n * Line 3\n */\n\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

return T
