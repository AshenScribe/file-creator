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

local function read_file(path)
    return child.lua_get(string.format([[
        (function()
            local lines = vim.fn.readfile(%q)
            if #lines == 0 then return "" end
            return table.concat(lines, "\n") .. "\n"
        end)()
    ]], path))
end

T["generator file creation"] = new_set({
    hooks = {
        pre_case = start_child,
        post_case = function() child.stop() end,
    },
})

T["generator file creation"]["Creates class with superclass"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Class", "UserService", { extends = "BaseEntity" })
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/UserService.java"
    eq(child.fn.filereadable(file), 1)
    eq(read_file(file), "package org.example;\n\npublic class UserService extends BaseEntity {\n    \n}\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["generator file creation"]["Creates class implementing multiple interfaces"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Class", "UserService", { implements = "Serializable, Cloneable" })
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/UserService.java"
    eq(child.fn.filereadable(file), 1)
    eq(read_file(file), "package org.example;\n\npublic class UserService implements Serializable, Cloneable {\n    \n}\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["generator file creation"]["Creates class extending + implementing"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Class", "UserService", { extends = "BaseEntity", implements = "Serializable" })
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/UserService.java"
    eq(read_file(file), "package org.example;\n\npublic class UserService extends BaseEntity implements Serializable {\n    \n}\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["generator file creation"]["Creates interface extending interfaces"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Interface", "UserRepository", { extends = "JpaRepository, Closeable" })
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/UserRepository.java"
    eq(read_file(file), "package org.example;\n\npublic interface UserRepository extends JpaRepository, Closeable {\n    \n}\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["generator file creation"]["Creates enum implementing interfaces"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Enum", "Status", { implements = "Displayable" })
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/Status.java"
    eq(read_file(file), "package org.example;\n\npublic enum Status implements Displayable {\n    \n}\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["generator file creation"]["Creates record implementing interfaces"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Record", "User", { implements = "Serializable" })
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/User.java"
    eq(read_file(file), "package org.example;\n\npublic record User() implements Serializable {\n    \n}\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["generator file creation"]["Extra options work with nested package paths"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Class", "service/auth/AuthService", { extends = "BaseAuth" })
        end)()
    ]], root))

    local file = root .. "/src/main/java/org/example/service/auth/AuthService.java"
    eq(child.fn.filereadable(file), 1)
    eq(read_file(file), "package org.example.service.auth;\n\npublic class AuthService extends BaseAuth {\n    \n}\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

T["generator file creation"]["Existing file is not overwritten with extra options"] = function()
    local root = child.lua_get([[(function()
        local root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/src/main/java/org/example", "p")
        return root
    end)()]])

    local file = root .. "/src/main/java/org/example/UserService.java"
    child.lua(string.format("vim.fn.writefile({'DO NOT OVERWRITE'}, %q)", file))

    child.lua(string.format([[
        (function()
            vim.cmd("cd " .. vim.fn.fnameescape(%q .. "/src/main/java/org/example"))
            require("file-creator")._create_file("Class", "UserService", { extends = "OtherClass" })
        end)()
    ]], root))

    eq(read_file(file), "DO NOT OVERWRITE\n")
    child.lua(string.format("vim.fn.delete(%q, 'rf')", root))
end

return T
