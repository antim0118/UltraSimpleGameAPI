---@param str string
---@param suffix string
---@return boolean
---@nodiscard
function string.endsWith(str, suffix)
    return string.lower(str:sub(- #suffix)) == string.lower(suffix)
end
