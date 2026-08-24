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

T["package detection"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["package detection"]["main source root"] = function()
    eq(child.lua_get([[require("file-creator")._get_package_from_path("/project/src/main/java/org/example")]]), "org.example")
end

T["package detection"]["nested main package"] = function()
    eq(child.lua_get([[require("file-creator")._get_package_from_path("/project/src/main/java/org/example/server")]]), "org.example.server")
end

T["package detection"]["deeply nested package"] = function()
    eq(child.lua_get([[require("file-creator")._get_package_from_path("/project/src/main/java/org/example/server/messaging")]]), "org.example.server.messaging")
end

T["package detection"]["source root itself"] = function()
    eq(child.lua_get([[require("file-creator")._get_package_from_path("/project/src/main/java")]]), "")
end

T["package detection"]["outside source tree"] = function()
    eq(child.lua_get([[require("file-creator")._get_package_from_path("/project/build/classes")]]), vim.NIL)
end

return T
