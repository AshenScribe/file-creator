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

T["commands and edge cases"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["commands and edge cases"]["all user commands exist including CreateJavaFile"] = function()
    eq(child.fn.exists(":CreateJavaFile"), 2)
    eq(child.fn.exists(":CreateJavaClass"), 2)
    eq(child.fn.exists(":CreateJavaInterface"), 2)
    eq(child.fn.exists(":CreateJavaEnum"), 2)
    eq(child.fn.exists(":CreateJavaRecord"), 2)
    eq(child.fn.exists(":CreateTest"), 2)
end

T["commands and edge cases"]["command argument creates file without spaces"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Class", "UserService")
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/UserService.java"
    eq(child.fn.filereadable(file), 1)
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["commands and edge cases"][".java suffix is removed in file creation input"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            local clean_name = vim.trim("UserService.java"):gsub("%%.java$", "")
            require("file-creator")._create_file("Class", clean_name)
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/UserService.java"
    eq(child.fn.filereadable(file), 1)
    eq(child.fn.filereadable(root .. "/src/main/java/org/example/UserService.java.java"), 0)
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["commands and edge cases"]["handles files outside recognized roots gracefully"] = function()
    local root = child.lua_get([[(function() local root = vim.fn.tempname() vim.fn.mkdir(root .. "/random", "p") return root end)()]])
    local outside_file = root .. "/random/Script.java"
    child.fn.writefile({ "public class Script {}" }, outside_file)

    child.cmd("edit " .. child.fn.fnameescape(outside_file))
    child.cmd("CreateTest")
    eq(child.fn.isdirectory(root .. "/src/test"), 0)
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

return T
