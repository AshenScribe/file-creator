local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local no_error = MiniTest.expect.no_error
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

T["template rendering"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["template rendering"]["Class with superclass"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            extends = "BaseService",
        })
    ]])
    eq(res, "public class UserService extends BaseService {\n    \n}\n")
end

T["template rendering"]["Class with one interface"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            implements = "Serializable",
        })
    ]])
    eq(res, "public class UserService implements Serializable {\n    \n}\n")
end

T["template rendering"]["Class with multiple interfaces"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            implements = "Serializable, Cloneable, Auditable",
        })
    ]])
    eq(res, "public class UserService implements Serializable, Cloneable, Auditable {\n    \n}\n")
end

T["template rendering"]["Class with superclass + interfaces"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            extends = "BaseEntity",
            implements = "Serializable, Cloneable",
        })
    ]])
    eq(res, "public class UserService extends BaseEntity implements Serializable, Cloneable {\n    \n}\n")
end

T["template rendering"]["Interface with superinterfaces"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Interface", "UserRepository", require("file-creator.config").get(), {
            extends = "JpaRepository<User, Long>, Closeable",
        })
    ]])
    eq(res, "public interface UserRepository extends JpaRepository<User, Long>, Closeable {\n    \n}\n")
end

T["template rendering"]["Enum with interfaces"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Enum", "Status", require("file-creator.config").get(), {
            implements = "Displayable, Serializable",
        })
    ]])
    eq(res, "public enum Status implements Displayable, Serializable {\n    \n}\n")
end

T["template rendering"]["Record with interfaces"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Record", "User", require("file-creator.config").get(), {
            implements = "Serializable, Comparable<User>",
        })
    ]])
    eq(res, "public record User() implements Serializable, Comparable<User> {\n    \n}\n")
end

T["template rendering"]["Empty superclass produces no extends"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            extends = "",
        })
    ]])
    eq(res, "public class UserService {\n    \n}\n")
end

T["template rendering"]["Empty interfaces produce no implements"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            implements = "",
        })
    ]])
    eq(res, "public class UserService {\n    \n}\n")
end

T["template rendering"]["Whitespace around superclass is trimmed"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            extends = "   BaseService   ",
        })
    ]])
    eq(res, "public class UserService extends BaseService {\n    \n}\n")
end

T["template rendering"]["Whitespace around interfaces is trimmed"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "UserService", require("file-creator.config").get(), {
            implements = "   Serializable   ",
        })
    ]])
    eq(res, "public class UserService implements Serializable {\n    \n}\n")
end

T["template rendering"]["Invalid template returns nil"] = function()
    local res = child.lua_get([[
        require("file-creator.template").render("NonExistentTemplate", "Test", require("file-creator.config").get(), {})
    ]])
    eq(res, vim.NIL)
end

T["template rendering"]["custom template configuration is used"] = function()
    child.lua([[
        require("file-creator").setup({
            templates = { Class = "CUSTOM ${name}${extends}\n" },
        })
    ]])
    local res = child.lua_get([[
        require("file-creator.template").render("Class", "CustomClass", require("file-creator.config").get(), {
            extends = "BaseCustom",
        })
    ]])
    eq(res, "CUSTOM CustomClass extends BaseCustom\n")
end

return T
