local M = {}

local KEYWORDS = {
    ["abstract"] = true, ["assert"] = true, ["boolean"] = true, ["break"] = true,
    ["byte"] = true, ["case"] = true, ["catch"] = true, ["char"] = true,
    ["class"] = true, ["const"] = true, ["continue"] = true, ["default"] = true,
    ["do"] = true, ["double"] = true, ["else"] = true, ["enum"] = true,
    ["extends"] = true, ["final"] = true, ["finally"] = true, ["float"] = true,
    ["for"] = true, ["goto"] = true, ["if"] = true, ["implements"] = true,
    ["import"] = true, ["instanceof"] = true, ["int"] = true, ["interface"] = true,
    ["long"] = true, ["native"] = true, ["new"] = true, ["package"] = true,
    ["private"] = true, ["protected"] = true, ["public"] = true, ["return"] = true,
    ["short"] = true, ["static"] = true, ["strictfp"] = true, ["super"] = true,
    ["switch"] = true, ["synchronized"] = true, ["this"] = true, ["throw"] = true,
    ["throws"] = true, ["transient"] = true, ["try"] = true, ["void"] = true,
    ["volatile"] = true, ["while"] = true, ["_"] = true,
}

local LITERALS = {
    ["true"] = true, ["false"] = true, ["null"] = true,
}

local RESTRICTED_TYPE_IDENTIFIERS = {
    ["var"] = true, ["yield"] = true, ["record"] = true,
}

--- Validates a single Java identifier
--- @param name string
--- @param is_type_name? boolean
--- @return boolean is_valid
--- @return string? error_message
function M.validate_identifier(name, is_type_name)
    if not name or name == "" then
        return false, "Identifier cannot be empty"
    end

    if name:match("%s") then
        return false, string.format("Identifier '%s' cannot contain spaces", name)
    end

    if name:match("^%d") then
        return false, string.format("Identifier '%s' cannot start with a number", name)
    end

    if not name:match("^[%a_$][%w_$]*$") then
        return false, string.format("Identifier '%s' contains invalid characters (only letters, digits, '_' and '$' are allowed)", name)
    end

    if KEYWORDS[name] then
        return false, string.format("'%s' is a reserved Java keyword and cannot be used as an identifier", name)
    end

    if LITERALS[name] then
        return false, string.format("'%s' is a reserved Java literal and cannot be used as an identifier", name)
    end

    if is_type_name and RESTRICTED_TYPE_IDENTIFIERS[name] then
        return false, string.format("'%s' is a restricted Java type identifier and cannot be used as a type name", name)
    end

    return true, nil
end

--- Validates full input path (including optional subdirectories/packages)
--- @param input string
--- @return boolean is_valid
--- @return string? error_message
function M.validate_file_path_input(input)
    if not input or vim.trim(input) == "" then
        return false, "Input cannot be empty"
    end

    input = vim.trim(input):gsub("%.java$", "")
    input = input:gsub("\\", "/")

    local segments = vim.split(input, "/", { trimempty = false })
    if #segments == 0 then
        return false, "Input cannot be empty"
    end

    for i, segment in ipairs(segments) do
        if segment == "" then
            return false, "Path contains empty directory segment"
        end

        local is_type_name = (i == #segments)
        local valid, err = M.validate_identifier(segment, is_type_name)
        if not valid then
            return false, err
        end
    end

    return true, nil
end

return M
