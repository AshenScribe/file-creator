local MiniTest = require("mini.test")

local new_set = MiniTest.new_set

local eq = MiniTest.expect.equality
local no_error = MiniTest.expect.no_error

local T = new_set()


local child

local function start_child()
    child = MiniTest.new_child_neovim()

    child.start({
        "-u",
        "NONE",
    })

    child.lua([[
        vim.opt.rtp:prepend(".")
        require("file-creator").setup({
            should_format = false,
        })
    ]])
end

local function stop_child()
    if child then
        child.stop()
        child = nil
    end
end

local function child_hooks()
    return {
        pre_case = function()
            start_child()
        end,

        post_case = function()
            stop_child()
        end,
    }
end


local function create_project()
    return child.lua_get([[
        (function()
            local root = vim.fn.tempname()

            vim.fn.mkdir(
                root .. "/src/main/java/org/example",
                "p"
            )

            return root
        end)()
    ]])
end

local function setup_source_directory(root)
    return child.lua_get(string.format([[
        (function()
            local source_dir =
                %q .. "/src/main/java/org/example"

            vim.cmd("cd " .. vim.fn.fnameescape(source_dir))
            vim.cmd("enew")

            return source_dir
        end)()
    ]], root))
end

local function read_file(path)
    return child.lua_get(string.format([[
        (function()
            local lines = vim.fn.readfile(%q)

            if #lines == 0 then
                return ""
            end

            return table.concat(lines, "\n") .. "\n"
        end)()
    ]], path))
end

local function delete_project(root)
    child.lua(string.format(
        "vim.fn.delete(%q, 'rf')",
        root
    ))
end


T["package detection"] = new_set({
    hooks = child_hooks(),
})

T["package detection"]["main source root"] = function()
    eq(
        child.lua_get([[
            require("file-creator")._get_package_from_path(
                "/project/src/main/java/org/example"
            )
        ]]),
        "org.example"
    )
end

T["package detection"]["nested main package"] = function()
    eq(
        child.lua_get([[
            require("file-creator")._get_package_from_path(
                "/project/src/main/java/org/example/server"
            )
        ]]),
        "org.example.server"
    )
end

T["package detection"]["deeply nested package"] = function()
    eq(
        child.lua_get([[
            require("file-creator")._get_package_from_path(
                "/project/src/main/java/org/example/server/messaging"
            )
        ]]),
        "org.example.server.messaging"
    )
end

T["package detection"]["test source root"] = function()
    eq(
        child.lua_get([[
            require("file-creator")._get_package_from_path(
                "/project/src/test/java/org/example/server"
            )
        ]]),
        "org.example.server"
    )
end

T["package detection"]["src fallback"] = function()
    eq(
        child.lua_get([[
            require("file-creator")._get_package_from_path(
                "/project/src/org/example"
            )
        ]]),
        "org.example"
    )
end

T["package detection"]["source root itself"] = function()
    eq(
        child.lua_get([[
            require("file-creator")._get_package_from_path(
                "/project/src/main/java"
            )
        ]]),
        ""
    )
end

T["package detection"]["outside source tree"] = function()
    eq(
        child.lua_get([[
            require("file-creator")._get_package_from_path(
                "/project/build/classes"
            )
        ]]),
        vim.NIL
    )
end


T["license"] = new_set({
    hooks = child_hooks(),
})

T["license"]["LICENSE is detected"] = function()
    local root = child.lua_get([[
        (function()
            local root = vim.fn.tempname()

            vim.fn.mkdir(root, "p")

            vim.fn.writefile({
                "MIT License",
                "",
                "Copyright 2026 Test",
            }, root .. "/LICENSE")

            return root
        end)()
    ]])

    eq(
        child.lua_get(string.format([[
            require("file-creator")._get_license_banner(%q)
        ]], root)),
        "/*\n"
            .. " * MIT License\n"
            .. " * Copyright 2026 Test\n"
            .. " */\n\n"
    )

    child.lua(string.format(
        "vim.fn.delete(%q, 'rf')",
        root
    ))
end

T["license"]["LICENSE.txt is detected"] = function()
    local root = child.lua_get([[
        (function()
            local root = vim.fn.tempname()

            vim.fn.mkdir(root, "p")

            vim.fn.writefile({
                "Apache License",
            }, root .. "/LICENSE.txt")

            return root
        end)()
    ]])

    eq(
        child.lua_get(string.format([[
            require("file-creator")._get_license_banner(%q)
        ]], root)),
        "/*\n"
            .. " * Apache License\n"
            .. " */\n\n"
    )

    child.lua(string.format(
        "vim.fn.delete(%q, 'rf')",
        root
    ))
end

T["license"]["LICENSE.md is detected"] = function()
    local root = child.lua_get([[
        (function()
            local root = vim.fn.tempname()

            vim.fn.mkdir(root, "p")

            vim.fn.writefile({
                "Project License",
            }, root .. "/LICENSE.md")

            return root
        end)()
    ]])

    eq(
        child.lua_get(string.format([[
            require("file-creator")._get_license_banner(%q)
        ]], root)),
        "/*\n"
            .. " * Project License\n"
            .. " */\n\n"
    )

    child.lua(string.format(
        "vim.fn.delete(%q, 'rf')",
        root
    ))
end

T["license"]["missing license returns empty string"] = function()
    local root = child.lua_get([[
        (function()
            local root = vim.fn.tempname()

            vim.fn.mkdir(root, "p")

            return root
        end)()
    ]])

    eq(
        child.lua_get(string.format([[
            require("file-creator")._get_license_banner(%q)
        ]], root)),
        ""
    )

    child.lua(string.format(
        "vim.fn.delete(%q, 'rf')",
        root
    ))
end

T["license"]["empty license returns empty string"] = function()
    local root = child.lua_get([[
        (function()
            local root = vim.fn.tempname()

            vim.fn.mkdir(root, "p")
            vim.fn.writefile({}, root .. "/LICENSE")

            return root
        end)()
    ]])

    eq(
        child.lua_get(string.format([[
            require("file-creator")._get_license_banner(%q)
        ]], root)),
        ""
    )

    child.lua(string.format(
        "vim.fn.delete(%q, 'rf')",
        root
    ))
end


T["file creation"] = new_set({
    hooks = child_hooks(),

    parametrize = {
        {
            "Class",
            "UserService",
            "public class UserService {\n    \n}\n",
        },
        {
            "Interface",
            "UserRepository",
            "public interface UserRepository {\n    \n}\n",
        },
        {
            "Enum",
            "Status",
            "public enum Status {\n    \n}\n",
        },
        {
            "Record",
            "User",
            "public record User() {\n    \n}\n",
        },
    },
})

T["file creation"]["creates correct type"] = function(
    template,
    name,
    expected_body
)
    local root = create_project()

    local source_dir =
        setup_source_directory(root)

    child.lua(string.format([[
        require("file-creator")._create_file(%q, %q)
    ]],
        template,
        name
    ))

    local file =
        source_dir .. "/" .. name .. ".java"

    eq(
        child.fn.filereadable(file),
        1
    )

    eq(
        read_file(file),
        "package org.example;\n\n"
            .. expected_body
    )

    delete_project(root)
end

T["file creation"]["does not overwrite existing file"] = function()
    local root = create_project()

    local source_dir =
        setup_source_directory(root)

    local file =
        source_dir .. "/UserService.java"

    child.lua(string.format(
        "vim.fn.writefile({'DO NOT OVERWRITE'}, %q)",
        file
    ))

    child.lua([[
        require("file-creator")._create_file(
            "Class",
            "UserService"
        )
    ]])

    eq(
        read_file(file),
        "DO NOT OVERWRITE\n"
    )

    delete_project(root)
end


T["nested paths"] = new_set({
    hooks = child_hooks(),
})

T["nested paths"]["creates nested directory"] = function()
    local root = create_project()

    local source_dir =
        setup_source_directory(root)

    child.lua([[
        require("file-creator")._create_file(
            "Class",
            "server/MessagingServer"
        )
    ]])

    local directory =
        source_dir .. "/server"

    local file =
        directory .. "/MessagingServer.java"

    eq(
        child.fn.isdirectory(directory),
        1
    )

    eq(
        child.fn.filereadable(file),
        1
    )

    delete_project(root)
end

T["nested paths"]["generates correct package"] = function()
    local root = create_project()

    local source_dir =
        setup_source_directory(root)

    child.lua([[
        require("file-creator")._create_file(
            "Class",
            "server/messaging/MessagingServer"
        )
    ]])

    local file =
        source_dir
        .. "/server/messaging/MessagingServer.java"

    local content =
        read_file(file)

    eq(
        content:match("package ([^;]+);"),
        "org.example.server.messaging"
    )

    delete_project(root)
end


T["configuration"] = new_set({
    hooks = child_hooks(),
})

T["configuration"]["formatting can be disabled"] = function()
    no_error(function()
        child.lua([[
            require("file-creator").setup({
                should_format = false,
            })
        ]])
    end)
end

T["configuration"]["custom template is used"] = function()
    child.lua([[
        require("file-creator").setup({
            should_format = false,

            templates = {
                Class = "CUSTOM ${name}\n",
            },
        })
    ]])

    local root = create_project()

    local source_dir =
        setup_source_directory(root)

    child.lua([[
        require("file-creator")._create_file(
            "Class",
            "CustomClass"
        )
    ]])

    local file =
        source_dir .. "/CustomClass.java"

    eq(
        read_file(file),
        "package org.example;\n\n"
            .. "CUSTOM CustomClass\n"
    )

    delete_project(root)
end


T["commands"] = new_set({
    hooks = child_hooks(),
})

T["commands"]["CreateJavaClass exists"] = function()
    eq(
        child.fn.exists(":CreateJavaClass"),
        2
    )
end

T["commands"]["CreateJavaInterface exists"] = function()
    eq(
        child.fn.exists(":CreateJavaInterface"),
        2
    )
end

T["commands"]["CreateJavaEnum exists"] = function()
    eq(
        child.fn.exists(":CreateJavaEnum"),
        2
    )
end

T["commands"]["CreateJavaRecord exists"] = function()
    eq(
        child.fn.exists(":CreateJavaRecord"),
        2
    )
end

return T
