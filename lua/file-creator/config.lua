local M = {}

M.defaults = {
    java_source_dirs = { "src/main/java" },
    java_test_dirs = { "src/test/java" },
    templates = {
        Class     = "public class ${name}${extends}${implements} {\n    \n}\n",
        Interface = "public interface ${name}${extends} {\n    \n}\n",
        Enum      = "public enum ${name}${implements} {\n    \n}\n",
        Record    = "public record ${name}()${implements} {\n    \n}\n",
        Test      = "public class ${name} {\n    \n}\n",
    },
    license = {
        enabled = true,
        filenames = { "LICENSE", "LICENSE.txt", "LICENSE.md" },
    },
    should_format = true,
    organize_imports = true,
}

local current_config = vim.tbl_deep_extend("force", {}, M.defaults)

function M.setup(opts)
    current_config = vim.tbl_deep_extend("force", M.defaults, opts or {})
    return current_config
end

function M.get()
    return current_config
end

return M
