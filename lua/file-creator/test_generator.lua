local project = require("file-creator.project")
local license = require("file-creator.license")
local template = require("file-creator.template")

local M = {}

local function notify(msg, level)
    if #vim.api.nvim_list_uis() > 0 then
        vim.notify(msg, level)
    end
end

local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

function M.create_test(config)
    local full_path = vim.fn.expand("%:p")
    if full_path == "" then
        notify("No active file buffer found", vim.log.levels.WARN)
        return
    end

    if full_path:find("/src/test/java/", 1, true) or ends_with(full_path, "/src/test/java") then
        notify("Current file is already under test directory", vim.log.levels.WARN)
        return
    end

    local source_dirs = config.java_source_dirs
    local test_dirs = config.java_test_dirs

    local test_file_path = nil

    for i, src in ipairs(source_dirs) do
        local target_test_dir = test_dirs[i] or test_dirs[1] or "src/test/java"

        if full_path:find(src, 1, true) then
            test_file_path = full_path:gsub(vim.pesc(src), target_test_dir)

            if test_file_path:match("%.java$") and not test_file_path:match("Test%.java$") then
                test_file_path = test_file_path:gsub("%.java$", "Test.java")
            end
            break
        end
    end

    if not test_file_path then
        notify("Current file path does not match any java_source_dirs", vim.log.levels.WARN)
        return
    end

    local test_dir_path = vim.fs.dirname(test_file_path)

    if vim.fn.isdirectory(test_dir_path) == 0 then
        local success = vim.fn.mkdir(test_dir_path, "p")
        if success == 0 then
            notify("Could not create test directory: " .. test_dir_path, vim.log.levels.ERROR)
            return
        end
    end

    if vim.fn.filereadable(test_file_path) == 0 then
        local file = io.open(test_file_path, "w")
        if file then
            local test_package = project.get_package_from_path(test_dir_path, config)
            local license_banner = license.get_license_banner(test_dir_path, config)
            local class_name = vim.fn.fnamemodify(test_file_path, ":t:r")

            local template_source = template.render("Test", class_name, config)
                or "public class ${name} {\n    \n}\n"

            local content = license_banner
            if test_package and test_package ~= "" then
                content = content .. "package " .. test_package .. ";\n\n"
            end
            content = content .. template_source

            file:write(content)
            file:close()
        end
    end

    vim.cmd("edit " .. vim.fn.fnameescape(test_file_path))

    if config.should_format and vim.lsp and vim.lsp.buf and vim.lsp.buf.format then
        vim.lsp.buf.format({ async = true })
    end
end

return M
