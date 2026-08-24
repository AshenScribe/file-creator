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

T["validation"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["validation"]["Valid identifiers are accepted"] = function()
    eq(child.lua_get([[require("file-creator")._validate_name("UserService")]]), true)
    eq(child.lua_get([[require("file-creator")._validate_name("_PrivateService")]]), true)
    eq(child.lua_get([[require("file-creator")._validate_name("$ProxyClass")]]), true)
    eq(child.lua_get([[require("file-creator")._validate_name("User2Dto")]]), true)
    eq(child.lua_get([[require("file-creator")._validate_name("com/example/service/UserService")]]), true)
end

T["validation"]["Identifier starting with digit is rejected"] = function()
    local valid, err = unpack(child.lua_get([[
        { require("file-creator")._validate_name("2abc") }
    ]]))
    eq(valid, false)
    eq(err:match("cannot start with a number") ~= nil, true)
end

T["validation"]["Identifier with special characters is rejected"] = function()
    local valid, _ = unpack(child.lua_get([[
        { require("file-creator")._validate_name("User-Service") }
    ]]))
    eq(valid, false)

    local valid2, _ = unpack(child.lua_get([[
        { require("file-creator")._validate_name("User@Service") }
    ]]))
    eq(valid2, false)
end

T["validation"]["Identifier with spaces is rejected"] = function()
    local valid, err = unpack(child.lua_get([[
        { require("file-creator")._validate_name("User Service") }
    ]]))
    eq(valid, false)
    eq(err:match("cannot contain spaces") ~= nil, true)
end

T["validation"]["Java keywords are rejected"] = function()
    local keywords = { "class", "public", "int", "interface", "enum", "while", "goto", "_" }
    for _, kw in ipairs(keywords) do
        local valid, err = unpack(child.lua_get(string.format([[
            { require("file-creator")._validate_name(%q) }
        ]], kw)))
        eq(valid, false)
        eq(err:match("reserved Java keyword") ~= nil, true)
    end
end

T["validation"]["Java literals are rejected"] = function()
    local literals = { "true", "false", "null" }
    for _, lit in ipairs(literals) do
        local valid, err = unpack(child.lua_get(string.format([[
            { require("file-creator")._validate_name(%q) }
        ]], lit)))
        eq(valid, false)
        eq(err:match("reserved Java literal") ~= nil, true)
    end
end

T["validation"]["Restricted type identifiers are rejected"] = function()
    local restricted = { "var", "yield", "record" }
    for _, word in ipairs(restricted) do
        local valid, err = unpack(child.lua_get(string.format([[
            { require("file-creator")._validate_name(%q) }
        ]], word)))
        eq(valid, false)
        eq(err:match("restricted Java type identifier") ~= nil, true)
    end
end

T["validation"]["Invalid package segment in path is rejected"] = function()
    local valid, err = unpack(child.lua_get([[
        { require("file-creator")._validate_name("2package/UserService") }
    ]]))
    eq(valid, false)
    eq(err:match("cannot start with a number") ~= nil, true)

    local valid_kw, _ = unpack(child.lua_get([[
        { require("file-creator")._validate_name("class/UserService") }
    ]]))
    eq(valid_kw, false)
end

return T
