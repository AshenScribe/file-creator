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
        require("file-creator").setup({ should_format = false })
    ]])
end

T["source root configurations"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["source root configurations"]["single-project source roots resolve correctly"] = function()
    local root = child.lua_get([[
        (function()
            local root = vim.fn.tempname()
            vim.fn.mkdir(root .. "/src/main/java/com/example", "p")
            vim.fn.mkdir(root .. "/src/test/java/com/example", "p")
            vim.fn.writefile({""}, root .. "/settings.gradle")
            vim.fn.writefile({""}, root .. "/build.gradle")
            return root
        end)()
    ]])

    eq(child.lua_get(string.format([[require("file-creator")._get_package_from_path(%q)]], root .. "/src/main/java/com/example")), "com.example")
    eq(child.lua_get(string.format([[require("file-creator")._get_package_from_path(%q)]], root .. "/src/test/java/com/example")), "com.example")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["source root configurations"]["multi-project source roots isolate app and core correctly"] = function()
    local root = child.lua_get([[
        (function()
            local root = vim.fn.tempname()
            vim.fn.mkdir(root .. "/app/src/main/java/com/app", "p")
            vim.fn.mkdir(root .. "/app/src/test/java/com/app", "p")
            vim.fn.mkdir(root .. "/core/src/main/java/com/core", "p")
            vim.fn.mkdir(root .. "/core/src/test/java/com/core", "p")
            vim.fn.writefile({"include 'app', 'core'"}, root .. "/settings.gradle")
            return root
        end)()
    ]])

    eq(child.lua_get(string.format([[require("file-creator")._get_package_from_path(%q)]], root .. "/app/src/main/java/com/app")), "com.app")
    eq(child.lua_get(string.format([[require("file-creator")._get_package_from_path(%q)]], root .. "/core/src/main/java/com/core")), "com.core")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

return T
