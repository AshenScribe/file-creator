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

T["gradle detection"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["gradle detection"]["settings.gradle found in current and parent directories"] = function()
    local root, child_dir = unpack(child.lua_get([[
        (function()
            local root = vim.fn.tempname()
            local child_dir = root .. "/sub/nested"
            vim.fn.mkdir(child_dir, "p")
            vim.fn.writefile({"rootProject.name='test'"}, root .. "/settings.gradle")
            return {root, child_dir}
        end)()
    ]]))
    eq(child.lua_get(string.format([[require("file-creator")._get_gradle_settings_root(%q)]], root)), root)
    eq(child.lua_get(string.format([[require("file-creator")._get_gradle_settings_root(%q)]], child_dir)), root)
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["gradle detection"]["settings.gradle.kts discovery and nearest fallback"] = function()
    local root, sub_dir, nested_sub = unpack(child.lua_get([[
        (function()
            local root = vim.fn.tempname()
            local sub_dir = root .. "/sub"
            local nested_sub = sub_dir .. "/nested"
            vim.fn.mkdir(nested_sub, "p")
            vim.fn.writefile({"root='root'"}, root .. "/settings.gradle.kts")
            vim.fn.writefile({"root='sub'"}, sub_dir .. "/settings.gradle.kts")
            return {root, sub_dir, nested_sub}
        end)()
    ]]))
    eq(child.lua_get(string.format([[require("file-creator")._get_gradle_settings_root(%q)]], nested_sub)), sub_dir)
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["gradle detection"]["missing settings file returns nil"] = function()
    local root = child.lua_get([[(function() local root = vim.fn.tempname() vim.fn.mkdir(root, "p") return root end)()]])
    eq(child.lua_get(string.format([[require("file-creator")._get_gradle_settings_root(%q)]], root)), vim.NIL)
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["gradle detection"]["build root resolution and subproject hierarchy lookup"] = function()
    local root, sub_dir, nested_dir = unpack(child.lua_get([[
        (function()
            local root = vim.fn.tempname()
            local sub_dir = root .. "/app"
            local nested_dir = root .. "/modules/core/service"
            vim.fn.mkdir(sub_dir, "p")
            vim.fn.mkdir(nested_dir, "p")
            vim.fn.writefile({"plugins { java }"}, root .. "/build.gradle")
            vim.fn.writefile({"plugins { java }"}, sub_dir .. "/build.gradle.kts")
            vim.fn.writefile({"plugins { java }"}, nested_dir .. "/build.gradle")
            return {root, sub_dir, nested_dir}
        end)()
    ]]))
    eq(child.lua_get(string.format([[require("file-creator")._get_gradle_build_root(%q)]], root)), root)
    eq(child.lua_get(string.format([[require("file-creator")._get_gradle_build_root(%q)]], sub_dir)), sub_dir)
    eq(child.lua_get(string.format([[require("file-creator")._get_gradle_build_root(%q)]], nested_dir)), nested_dir)
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

return T
