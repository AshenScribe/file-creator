local project = require("file-creator.project")
local license = require("file-creator.license")
local template = require("file-creator.template")
local validator = require("file-creator.validator")

local M = {}

local function notify(msg, level)
    if #vim.api.nvim_list_uis() > 0 then
        vim.notify(msg, level)
    end
end

local function trigger_lsp_actions(bufnr, config)
    local function run()
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        if config.organize_imports then
            local ok, jdtls = pcall(require, "jdtls")
            if ok and jdtls.organize_imports then
                pcall(jdtls.organize_imports)
            else
                pcall(vim.lsp.buf.code_action, {
                    context = { only = { "source.organizeImports" } },
                    apply = true,
                })
            end
        end

        if config.should_format and vim.lsp.buf.format then
            vim.lsp.buf.format({ bufnr = bufnr, async = true })
        end
    end

    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients > 0 then
        vim.defer_fn(run, 200)
    else
        local group = vim.api.nvim_create_augroup("FileCreatorLspAction_" .. bufnr, { clear = true })
        vim.api.nvim_create_autocmd("LspAttach", {
            group = group,
            buffer = bufnr,
            once = true,
            callback = function()
                vim.defer_fn(run, 200)
            end,
        })
        vim.defer_fn(run, 400)
    end
end

function M.create_file(template_name, file_name_input, config, extra_opts)
    local valid, err = validator.validate_file_path_input(file_name_input)
    if not valid then
        notify(err, vim.log.levels.ERROR)
        return
    end

    local template_source = template.render(
        template_name,
        vim.fn.fnamemodify(file_name_input, ":t"),
        config,
        extra_opts
    )
    if not template_source then
        notify("Invalid template selected: " .. tostring(template_name), vim.log.levels.ERROR)
        return
    end

    local base_target_dir, base_package_name = project.get_current_directory_and_package(config)

    file_name_input = file_name_input:gsub("\\", "/")

    local sub_dir = vim.fn.fnamemodify(file_name_input, ":h")
    local file_name = vim.fn.fnamemodify(file_name_input, ":t")

    local target_dir = base_target_dir
    local final_package_name = base_package_name

    if sub_dir ~= "" and sub_dir ~= "." then
        target_dir = vim.fs.joinpath(base_target_dir, sub_dir)

        if base_package_name and base_package_name ~= "" then
            final_package_name = base_package_name .. "." .. sub_dir:gsub("/", ".")
        else
            final_package_name = sub_dir:gsub("/", ".")
        end
    end

    if vim.fn.isdirectory(target_dir) == 0 then
        local success = vim.fn.mkdir(target_dir, "p")
        if success == 0 then
            notify("Could not create directory: " .. target_dir, vim.log.levels.ERROR)
            return
        end
    end

    local file_path = vim.fs.joinpath(target_dir, file_name .. ".java")

    if vim.fn.filereadable(file_path) == 1 then
        notify("File already exists: " .. file_path, vim.log.levels.ERROR)
        return
    end

    local license_banner = license.get_license_banner(target_dir, config)
    local content = license_banner

    if final_package_name and final_package_name ~= "" then
        content = content .. "package " .. final_package_name .. ";\n\n"
    end

    content = content .. template_source

    local file = io.open(file_path, "w")
    if not file then
        notify("Could not create file: " .. file_path, vim.log.levels.ERROR)
        return
    end
    file:write(content)
    file:close()

    if #vim.api.nvim_list_uis() > 0 then
        vim.cmd("edit " .. vim.fn.fnameescape(file_path))
        local bufnr = vim.api.nvim_get_current_buf()
        trigger_lsp_actions(bufnr, config)
    end

    notify("Created and opened: " .. file_path, vim.log.levels.INFO)
end

return M
