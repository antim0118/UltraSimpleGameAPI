---@param str string
---@param suffix string
---@return boolean
---@nodiscard
string.endsWith = function(str, suffix)
    return string.lower(str:sub(- #suffix)) == string.lower(suffix);
end;

---@param tabs integer
---@return string
string.tabs = function(tabs)
    local str = "";
    for i = 1, tabs do
        str = str .. '\t';
    end;
    return str;
end;
