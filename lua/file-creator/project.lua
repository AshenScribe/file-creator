local M = {}

local function ends_with(str, ending)
    return ending == "" or str:sub(- #ending) == ending
end

function M.get_gradle_settings_root(start_path)
    local found = vim.fs.find({ "settings.gradle", "settings.gradle.kts" }, {
        path = start_path,
        upward = true,
        limit = 1,
    })
    if #found > 0 then
        return vim.fs.dirname(found[1])
    end
    return nil
end

function M.get_gradle_build_root(start_path)
    local found = vim.fs.find({ "build.gradle", "build.gradle.kts" }, {
        path = start_path,
        upward = true,
        limit = 1,
    })
    if #found > 0 then
        return vim.fs.dirname(found[1])
    end
    return nil
end

function M.get_package_from_path(path, config)
    local source_dirs = config.java_source_dirs
    local test_dirs = config.java_test_dirs

    local all_dirs = {}
    for _, dir in ipairs(source_dirs) do table.insert(all_dirs, dir) end
    for _, dir in ipairs(test_dirs) do table.insert(all_dirs, dir) end

    for _, pattern in ipairs(all_dirs) do
        local escaped_pattern = pattern:gsub("([^%w])", "%%%1")
        local _, end_index = path:find("/%s*" .. escaped_pattern .. "/")
        if not end_index then
            local _, match_end = path:find("/" .. escaped_pattern .. "$")
            if match_end then
                end_index = match_end
            end
        end

        if end_index then
            local relative_path = path:sub(end_index + 1)
            if relative_path == "" then
                return ""
            end
            return relative_path:gsub("/", ".")
        elseif ends_with(path, "/" .. pattern) then
            return ""
        end
    end

    return nil
end

function M.get_current_directory_and_package(config)
    local current_buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(current_buf)

    local target_dir = nil

    if buf_name ~= "" and vim.fn.filereadable(buf_name) == 1 then
        target_dir = vim.fn.fnamemodify(buf_name, ":p:h")
    else
        local root_file = M.get_gradle_settings_root(vim.fn.getcwd())
            or M.get_gradle_build_root(vim.fn.getcwd())
            or vim.fs.root(0, { ".git" })
            or vim.fn.getcwd()
        target_dir = vim.fn.fnamemodify(root_file, ":p")
    end

    target_dir = target_dir:gsub("/$", "")
    local package_name = M.get_package_from_path(target_dir, config)
    return target_dir, package_name
end

return M
