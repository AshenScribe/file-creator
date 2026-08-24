local M = {}

function M.get_license_banner(start_dir, config)
    if not config.license.enabled then
        return ""
    end

    local found_files = vim.fs.find(config.license.filenames, {
        path = start_dir,
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
    if content == "" then
        return ""
    end

    local formatted = "/*\n"
    local has_lines = false
    for line in content:gmatch("([^\r\n]*)") do
        line = line:gsub("%s+$", "")
        if line ~= "" then
            formatted = formatted .. " * " .. line .. "\n"
            has_lines = true
        end
    end
    formatted = formatted .. " */\n\n"

    if not has_lines then
        return ""
    end

    return formatted
end

return M
