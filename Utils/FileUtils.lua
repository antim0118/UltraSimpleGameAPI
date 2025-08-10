File = {}

---@param path string
---@return boolean
---@nodiscard
function File.exists(path)
    local f = io.open(path, "rb")
    if f then f:close() end
    return f ~= nil
end

---@param path string
---@return string[]
---@nodiscard
function File.GetDirectories(path)
    local tb = {}
    for k, v in pairs(System.listDir(path)) do
        if (v.name ~= "." and v.name ~= ".."
                and v.size == 0 and System.isDir(path .. "/" .. v.name)) then --not File.exists(path .. "/" .. v.name)) then
            table.insert(tb, v.name)
        end
    end
    return tb;
end

---@param path string
---@return string[]
---@nodiscard
function File.GetFiles(path)
    local tb = {}
    for k, v in pairs(System.listDir(path)) do
        if (v.name ~= "." and v.name ~= ".."
                and v.size > 0) then --and File.exists(path .. "/" .. v.name)) then
            table.insert(tb, v.name)
        end
    end
    return tb;
end

function File.GetAllFiles(path)
    local tb = File.GetFiles(path);
    for _, dirName in pairs(File.GetDirectories(path)) do
        for _, filePath in pairs(File.GetAllFiles(path .. '/' .. dirName)) do
            table.insert(tb, dirName .. '/' .. filePath);
            print("adding " .. dirName .. '/' .. filePath)
        end
    end
    return tb;
end

---@param path string
---@return string | nil
function File.ReadAllText(path)
    local file = io.open(path, "rb")
    if (not file) then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

---@param path string
---@return string[] | nil
function File.ReadAllLines(path)
    if (not File.exists(path)) then return nil end
    local lines = {}
    for line in io.lines(path) do
        lines[#lines + 1] = line
    end
    return lines
end

---@param path string
---@param content string
function File.WriteAllText(path, content)
    local file, err = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
    else
        error(err);
    end
    print("called write for ", path)
end
