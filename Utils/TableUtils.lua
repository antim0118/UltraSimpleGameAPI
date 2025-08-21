local sf = string.format;
local tostring = tostring;
local pairs, ipairs = pairs, ipairs;

---@param tb table
---@param element any
---@return boolean
table.contains = function(tb, element)
    for _, v in pairs(tb) do
        if v == element then
            return true;
        end;
    end;
    return false;
end;

---@param tb table
---@param keyName string
---@return boolean
table.containsKey = function(tb, keyName)
    for k, v in pairs(tb) do
        if (k == keyName) then
            return true;
        end;
    end;
    return false;
end;


---@param tb table
---@return integer
table.count = function(tb)
    local c = 0;
    for k, v in pairs(tb) do
        c = c + 1;
    end;
    return c;
end;

---@param tb table
---@param tabs? integer
---@return string
table.debug = function(tb, tabs)
    tabs = tabs or 0;
    local str = '';
    for k, v in pairs(tb) do
        local t = type(v);
        if (type(k) == "string") then
            k = '"' .. k .. '"';
        end;
        if (t == "table") then
            local count = table.count(v);
            if (count > 0) then
                str = str .. sf('%s%s: (table)[%d]:\n%s',
                    string.tabs(tabs), tostring(k), count, table.debug(v, tabs + 1)
                );
            else
                str = str .. sf('%s%s: (table)[%d]: empty\n',
                    string.tabs(tabs), tostring(k), count);
            end;
        else
            str = str .. sf('%s%s: %s (%s)\n', string.tabs(tabs), tostring(k), tostring(v), type(v));
        end;
    end;
    return str;
end;

---@param tb table
---@param value any
---@return any | nil
table.getKeyByValue = function(tb, value)
    for k, v in pairs(tb) do
        if (v == value) then
            return k;
        end;
    end;
end;

---@param tb table
---@return [string | number]
table.keys = function(tb)
    local keys = {};
    for key, value in pairs(tb) do
        table.insert(keys, key);
    end;
    return keys;
end;

---@generic T
---@param tb T[]
---@param value T
---@return boolean
table.icontains = function(tb, value)
    for i = 1, #tb do
        local v = tb[i];
        if (v == value) then return true; end;
    end;
    return false;
end;

---@generic T
---@param tb T[]
---@param callback fun(value: T):any
---@return table
---@nodiscard
table.imap = function(tb, callback)
    local newtb = {};
    for i = 1, #tb do
        local v = tb[i];
        newtb[i] = callback(v);
    end;
    return newtb;
end;

---@generic T
---@param tb T[]
---@param callback fun(value: T):boolean
---@return T|nil
---@nodiscard
table.ifind = function(tb, callback)
    for i = 1, #tb do
        local v = tb[i];
        if (callback(v)) then
            return v;
        end;
    end;
end;
