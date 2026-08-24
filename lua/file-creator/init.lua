local M = {}

local default_config = {
    java_source_dirs = { "src/main/java", "src/test/java", "src" },
    templates = {
        Class     = "public class ${name} {\n    \n}\n",
        Interface = "public interface ${name} {\n    \n}\n",
        Enum      = "public enum ${name} {\n    \n}\n",
        Record    = "public record ${name}() {\n    \n}\n",
    },
    license = {
        enabled = true,
        filenames = { "LICENSE", "LICENSE.txt", "LICENSE.md" },
    },
    should_format = true,
}

local config = {}

local function notify(msg, level)
    if #vim.api.nvim_list_uis() > 0 then
        vim.notify(msg, level)
    end
end

local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

local function get_package_from_path(path)
    for _, pattern in ipairs(config.java_source_dirs or default_config.java_source_dirs) do
        local _, end_index = path:find("/" .. pattern .. "/")
        if end_index then
            local relative_path = path:sub(end_index + 1)
            return relative_path:gsub("/", ".")
        elseif ends_with(path, "/" .. pattern) then
            return ""
        end
    end

    return nil
end

-- Exposed for mini.test
M._get_package_from_path = get_package_from_path

local function get_license_banner(start_dir)
    local cfg = next(config) ~= nil and config or default_config
    if not cfg.license.enabled then
        return ""
    end

    local search_path = start_dir

    local found_files = vim.fs.find(cfg.license.filenames, {
        path = search_path,
        upward = true,
        limit = 1,
    })

    if #found_files == 0 then
        return ""
    end

    local license_path = found_files[1]
    local file = io.open(license_path, "r")
    if not file then
        return ""
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        return ""
    end

    content = content:gsub("^%s+", ""):gsub("%s+$", "")

    local formatted = "/*\n"
    for line in content:gmatch("([^\r\n]*)") do
        line = line:gsub("%s+$", "")
        if line ~= "" then
            formatted = formatted .. " * " .. line .. "\n"
        end
    end
    formatted = formatted .. " */\n\n"

    return formatted
end

-- Exposed for mini.test
M._get_license_banner = get_license_banner

local function get_current_directory_and_package()
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)

    local target_dir = nil

    if buf_name ~= "" and vim.fn.filereadable(buf_name) == 1 then
        target_dir = vim.fn.fnamemodify(buf_name, ":p:h")
    else
        target_dir = vim.fs.root(0, { "build.gradle", ".git" }) or vim.fn.getcwd()
        target_dir = vim.fn.fnamemodify(target_dir, ":p")
    end

    target_dir = target_dir:gsub("/$", "")

    local package_name = get_package_from_path(target_dir)
    return target_dir, package_name
end

local function create_file(template_name, file_name_input)
    local cfg = next(config) ~= nil and config or default_config
    local template_source = cfg.templates[template_name]
    if not template_source then
        notify("Invalid template selected: " .. tostring(template_name), vim.log.levels.ERROR)
        return
    end

    local base_target_dir, base_package_name = get_current_directory_and_package()

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

    local license_banner = get_license_banner(target_dir)
    local content = license_banner

    if final_package_name and final_package_name ~= "" then
        content = content .. "package " .. final_package_name .. ";\n\n"
    end

    content = content .. template_source:gsub("${name}", file_name)

    local file = io.open(file_path, "w")
    if not file then
        notify("Could not create file: " .. file_path, vim.log.levels.ERROR)
        return
    end
    file:write(content)
    file:close()

    -- Only jump to/edit file if UI is active (skip in headless tests)
    if #vim.api.nvim_list_uis() > 0 then
        vim.cmd("edit " .. vim.fn.fnameescape(file_path))
        if cfg.should_format then
            vim.lsp.buf.format({ async = true })
        end
    end

    notify("Created and opened: " .. file_path, vim.log.levels.INFO)
end

-- Exposed for mini.test
M._create_file = create_file

local function ask_for_name(template_name)
    vim.ui.input({ prompt = template_name .. " Name: " }, function(input_name)
        if not input_name or input_name == "" then
            return
        end

        if input_name:match("%s") then
            notify("Name cannot contain spaces", vim.log.levels.ERROR)
            return
        end

        create_file(template_name, input_name)
    end)
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.api.nvim_create_user_command("CreateJavaClass", function()
        ask_for_name("Class")
    end, {
        desc = "Quickly create a new Java Class",
    })
    vim.api.nvim_create_user_command("CreateJavaInterface", function()
        ask_for_name("Interface")
    end, {
        desc = "Quickly create a new Java Interface",
    })
    vim.api.nvim_create_user_command("CreateJavaEnum", function()
        ask_for_name("Enum")
    end, {
        desc = "Quickly create a new Java Enum",
    })
    vim.api.nvim_create_user_command("CreateJavaRecord", function()
        ask_for_name("Record")
    end, {
        desc = "Quickly create a new Java Record",
    })
end

return M
