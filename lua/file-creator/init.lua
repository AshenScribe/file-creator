local config = require("file-creator.config")
local project = require("file-creator.project")
local license = require("file-creator.license")
local generator = require("file-creator.generator")
local test_generator = require("file-creator.test_generator")
local validator = require("file-creator.validator")
local snacks = require("snacks")

local M = {}

M._get_package_from_path = function(path)
    return project.get_package_from_path(path, config.get())
end

M._get_gradle_settings_root = project.get_gradle_settings_root
M._get_gradle_build_root = project.get_gradle_build_root

M._get_license_banner = function(start_dir)
    return license.get_license_banner(start_dir, config.get())
end

M._create_file = function(template_name, file_name_input, extra_opts)
    return generator.create_file(template_name, file_name_input, config.get(), extra_opts)
end

M._create_test = function()
    return test_generator.create_test(config.get())
end

M._validate_name = validator.validate_file_path_input

local function prompt_super_types(template_name, callback)
local snacks = require("snacks")
    if template_name == "Class" then
        snacks.input({ prompt = "Super class (extends - optional): " }, function(super_class)
            snacks.input({ prompt = "Interfaces (implements - optional, comma separated): " }, function(interfaces)
                callback({
                    extends = super_class or "",
                    implements = interfaces or "",
                })
            end)
        end)
    elseif template_name == "Interface" then
        snacks.input({ prompt = "Super interfaces (extends - optional, comma separated): " }, function(super_interfaces)
            callback({
                extends = super_interfaces or "",
            })
        end)
    elseif template_name == "Record" or template_name == "Enum" then
        snacks.input({ prompt = "Interfaces (implements - optional, comma separated): " }, function(interfaces)
            callback({
                implements = interfaces or "",
            })
        end)
    else
        callback({})
    end
end

local function handle_file_creation(template_name, input_name)
    if not input_name or input_name == "" then
        return
    end

    input_name = vim.trim(input_name):gsub("%.java$", "")

    -- Comprehensive Java Identifier & Path Validation
    local valid, err = validator.validate_file_path_input(input_name)
    if not valid then
        if #vim.api.nvim_list_uis() > 0 then
            vim.notify(err, vim.log.levels.ERROR)
        end
        return
    end

    prompt_super_types(template_name, function(extra_opts)
        generator.create_file(template_name, input_name, config.get(), extra_opts)
    end)
end

local function ask_for_name(template_name)
local snacks = require("snacks")
    snacks.input({ prompt = template_name .. " Name: " }, function(input_name)
        handle_file_creation(template_name, input_name)
    end)
end

local function create_java_file_picker()
local snacks = require("snacks")
    local items = {
        { idx = 1, text = "Class",     template = "Class" },
        { idx = 2, text = "Interface", template = "Interface" },
        { idx = 3, text = "Enum",      template = "Enum" },
        { idx = 4, text = "Record",    template = "Record" },
    }

    if snacks.picker and snacks.picker.pick then
        snacks.picker.pick({
            title = " Create Java File (Type name & select template) ",
            layout = {
                preset = "select",
            },
            live = true,
            finder = function()
                return items
            end,
            format = "text",
            confirm = function(picker, item)
                local input_name = picker.input.filter.search
                if not input_name or input_name == "" then
                    input_name = picker.input.filter.pattern
                end

                if (not input_name or input_name == "") and picker.input and picker.input.win and picker.input.win.buf and vim.api.nvim_buf_is_valid(picker.input.win.buf) then
                    local lines = vim.api.nvim_buf_get_lines(picker.input.win.buf, 0, -1, false)
                    input_name = vim.trim(lines[1] or "")
                end

                picker:close()

                if not item then
                    return
                end

                local template_name = item.template or item.text

                if input_name and input_name ~= "" then
                    handle_file_creation(template_name, input_name)
                else
                    ask_for_name(template_name)
                end
            end,
        })
    else
        vim.ui.select({ "Class", "Interface", "Enum", "Record" }, {
            prompt = "Select Java Type: ",
        }, function(choice)
            if choice then
                ask_for_name(choice)
            end
        end)
    end
end

local function create_cmd_handler(template_name)
    return function(cmd_opts)
        local arg = cmd_opts.args and vim.trim(cmd_opts.args) or ""
        if arg ~= "" then
            handle_file_creation(template_name, arg)
        else
            ask_for_name(template_name)
        end
    end
end

function M.setup(opts)
    config.setup(opts)

    vim.api.nvim_create_user_command("CreateJavaFile", function()
        create_java_file_picker()
    end, { desc = "Create a new Java file by typing name and selecting template" })

    vim.api.nvim_create_user_command(
        "CreateJavaClass",
        create_cmd_handler("Class"),
        { nargs = "?", desc = "Quickly create a new Java Class" }
    )

    vim.api.nvim_create_user_command(
        "CreateJavaInterface",
        create_cmd_handler("Interface"),
        { nargs = "?", desc = "Quickly create a new Java Interface" }
    )

    vim.api.nvim_create_user_command(
        "CreateJavaEnum",
        create_cmd_handler("Enum"),
        { nargs = "?", desc = "Quickly create a new Java Enum" }
    )

    vim.api.nvim_create_user_command(
        "CreateJavaRecord",
        create_cmd_handler("Record"),
        { nargs = "?", desc = "Quickly create a new Java Record" }
    )

    vim.api.nvim_create_user_command("CreateTest", function()
        test_generator.create_test(config.get())
    end, { desc = "Quickly create a Test File for current Java File" })
end

return M
