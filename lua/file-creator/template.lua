local M = {}

function M.render(template_name, file_name, config, extra)
    local template_source = config.templates[template_name]
    if not template_source then
        return nil
    end

    extra = extra or {}

    local extends_clause = ""
    if extra.extends and vim.trim(extra.extends) ~= "" then
        extends_clause = " extends " .. vim.trim(extra.extends)
    end

    local implements_clause = ""
    if extra.implements and vim.trim(extra.implements) ~= "" then
        implements_clause = " implements " .. vim.trim(extra.implements)
    end

    local result = template_source

    if result:find("${extends}", 1, true) then
        result = result:gsub("${extends}", extends_clause)
    elseif extends_clause ~= "" then
        result = result:gsub("${name}", "${name}" .. extends_clause)
    end

    if result:find("${implements}", 1, true) then
        result = result:gsub("${implements}", implements_clause)
    elseif implements_clause ~= "" then
        result = result:gsub("${name}", "${name}" .. implements_clause)
    end

    result = result:gsub("${name}", file_name)
    return result
end

return M
