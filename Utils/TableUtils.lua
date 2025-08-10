---@param tb table
---@param element any
---@return boolean
function table.contains(tb, element)
    for _, v in pairs(tb) do
        if v == element then
            return true
        end
    end
    return false
end

---@param tb table
---@return string
function table.debug(tb)
    local str = ""
    for k, v in pairs(tb) do
        str = str .. string.format("%s = %s\n", tostring(k), tostring(v))
    end
    return str
end

---@param tb table
---@param value any
---@return any | nil
function table.getKeyByValue(tb, value)
    for k, v in pairs(tb) do
        if (v == value) then
            return k;
        end
    end
end

---@param tb table
---@return [string | number]
table.keys = function(tb)
    local keys = {};
    for key, value in pairs(tb) do
        table.insert(keys, key);
    end
    return keys;
end
